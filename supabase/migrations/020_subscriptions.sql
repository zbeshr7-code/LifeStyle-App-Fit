-- Trainer subscription plans and trainee subscriptions (Moyasar-ready)

CREATE TYPE public.subscription_status AS ENUM ('active', 'expired', 'cancelled');

CREATE TYPE public.subscription_payment_status AS ENUM (
  'waived',
  'pending_moyasar',
  'paid'
);

CREATE TABLE public.subscription_plans (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title          VARCHAR NOT NULL,
  description    TEXT,
  price_amount   NUMERIC(12, 2) NOT NULL CHECK (price_amount >= 0),
  currency       VARCHAR NOT NULL DEFAULT 'SAR',
  duration_days  INTEGER NOT NULL CHECK (duration_days > 0),
  features       JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active      BOOLEAN NOT NULL DEFAULT true,
  is_featured    BOOLEAN NOT NULL DEFAULT false,
  sort_order     INTEGER NOT NULL DEFAULT 0,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_subscription_plans_trainer
  ON public.subscription_plans (trainer_id, is_active, sort_order);

CREATE TABLE public.trainee_subscriptions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainee_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id          UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  plan_id             UUID REFERENCES public.subscription_plans(id) ON DELETE SET NULL,
  plan_title          VARCHAR NOT NULL,
  plan_price          NUMERIC(12, 2) NOT NULL,
  duration_days       INTEGER NOT NULL,
  status              public.subscription_status NOT NULL DEFAULT 'active',
  payment_status      public.subscription_payment_status NOT NULL DEFAULT 'waived',
  starts_at           TIMESTAMPTZ NOT NULL,
  ends_at             TIMESTAMPTZ NOT NULL,
  amount_paid         NUMERIC(12, 2),
  moyasar_payment_id  TEXT,
  moyasar_checkout_id TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  CHECK (ends_at > starts_at)
);

CREATE UNIQUE INDEX idx_trainee_subscriptions_one_active
  ON public.trainee_subscriptions (trainee_id, trainer_id)
  WHERE status = 'active';

CREATE INDEX idx_trainee_subscriptions_trainer
  ON public.trainee_subscriptions (trainer_id, status);

CREATE OR REPLACE FUNCTION public.set_subscription_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER on_subscription_plan_updated
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.set_subscription_updated_at();

CREATE TRIGGER on_trainee_subscription_updated
  BEFORE UPDATE ON public.trainee_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.set_subscription_updated_at();

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.has_active_subscription(
  p_trainee_id UUID,
  p_trainer_id UUID
)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trainee_subscriptions s
    WHERE s.trainee_id = p_trainee_id
      AND s.trainer_id = p_trainer_id
      AND s.status = 'active'
      AND s.ends_at > timezone('utc', now())
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainee_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone authenticated reads active plans for a trainer"
  ON public.subscription_plans FOR SELECT
  USING (
    is_active = true
    OR trainer_id = auth.uid()
  );

CREATE POLICY "Trainers manage own subscription plans"
  ON public.subscription_plans FOR ALL
  USING (trainer_id = auth.uid())
  WITH CHECK (trainer_id = auth.uid());

CREATE POLICY "Trainees read own subscriptions"
  ON public.trainee_subscriptions FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers read subscriptions for their trainees"
  ON public.trainee_subscriptions FOR SELECT
  USING (trainer_id = auth.uid());

CREATE POLICY "Trainers update subscriptions for their trainees"
  ON public.trainee_subscriptions FOR UPDATE
  USING (trainer_id = auth.uid())
  WITH CHECK (trainer_id = auth.uid());

-- Inserts only via SECURITY DEFINER RPCs

-- ---------------------------------------------------------------------------
-- RPC: list plans
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_trainer_subscription_plans(p_trainer_id UUID)
RETURNS SETOF public.subscription_plans AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT p.*
  FROM public.subscription_plans p
  WHERE p.trainer_id = p_trainer_id
    AND (
      p.is_active = true
      OR p.trainer_id = auth.uid()
    )
  ORDER BY p.sort_order ASC, p.created_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: upsert plan (trainer)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.upsert_subscription_plan(
  p_plan_id UUID,
  p_title VARCHAR,
  p_description TEXT,
  p_price_amount NUMERIC,
  p_duration_days INTEGER,
  p_features JSONB,
  p_is_featured BOOLEAN DEFAULT false,
  p_sort_order INTEGER DEFAULT 0
)
RETURNS public.subscription_plans AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_plan public.subscription_plans;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_trainer_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Only trainers can manage plans';
  END IF;

  IF p_duration_days IS NULL OR p_duration_days <= 0 THEN
    RAISE EXCEPTION 'duration_days must be positive';
  END IF;

  IF p_plan_id IS NULL THEN
    INSERT INTO public.subscription_plans (
      trainer_id, title, description, price_amount, duration_days,
      features, is_featured, sort_order
    ) VALUES (
      v_trainer_id,
      p_title,
      p_description,
      COALESCE(p_price_amount, 0),
      p_duration_days,
      COALESCE(p_features, '[]'::jsonb),
      COALESCE(p_is_featured, false),
      COALESCE(p_sort_order, 0)
    )
    RETURNING * INTO v_plan;
  ELSE
    UPDATE public.subscription_plans
    SET title = p_title,
        description = p_description,
        price_amount = COALESCE(p_price_amount, 0),
        duration_days = p_duration_days,
        features = COALESCE(p_features, '[]'::jsonb),
        is_featured = COALESCE(p_is_featured, is_featured),
        sort_order = COALESCE(p_sort_order, sort_order),
        updated_at = timezone('utc', now())
    WHERE id = p_plan_id AND trainer_id = v_trainer_id
    RETURNING * INTO v_plan;

    IF v_plan IS NULL THEN
      RAISE EXCEPTION 'Plan not found or not owned by trainer';
    END IF;
  END IF;

  RETURN v_plan;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.deactivate_subscription_plan(p_plan_id UUID)
RETURNS public.subscription_plans AS $$
DECLARE
  v_plan public.subscription_plans;
BEGIN
  UPDATE public.subscription_plans
  SET is_active = false,
      updated_at = timezone('utc', now())
  WHERE id = p_plan_id AND trainer_id = auth.uid()
  RETURNING * INTO v_plan;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  RETURN v_plan;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: subscribe (trainee, auto-activate waived)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.subscribe_to_plan(p_plan_id UUID)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_trainee_id UUID := auth.uid();
  v_me public.profiles;
  v_plan public.subscription_plans;
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
  IF v_trainee_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_me FROM public.profiles WHERE id = v_trainee_id;
  IF v_me.role != 'trainee' THEN
    RAISE EXCEPTION 'Only trainees can subscribe';
  END IF;
  IF v_me.trainer_id IS NULL THEN
    RAISE EXCEPTION 'Assign a trainer before subscribing';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = p_plan_id
    AND trainer_id = v_me.trainer_id
    AND is_active = true;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'Plan not found for your trainer';
  END IF;

  -- Expire previous active subscription with same trainer
  UPDATE public.trainee_subscriptions
  SET status = 'expired',
      updated_at = v_now
  WHERE trainee_id = v_trainee_id
    AND trainer_id = v_me.trainer_id
    AND status = 'active';

  INSERT INTO public.trainee_subscriptions (
    trainee_id,
    trainer_id,
    plan_id,
    plan_title,
    plan_price,
    duration_days,
    status,
    payment_status,
    starts_at,
    ends_at,
    amount_paid
  ) VALUES (
    v_trainee_id,
    v_me.trainer_id,
    v_plan.id,
    v_plan.title,
    v_plan.price_amount,
    v_plan.duration_days,
    'active',
    'waived',
    v_now,
    v_now + (v_plan.duration_days || ' days')::interval,
    0
  )
  RETURNING * INTO v_sub;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: trainee active subscription
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_active_subscription()
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_trainee_id UUID := auth.uid();
  v_me public.profiles;
  v_sub public.trainee_subscriptions;
BEGIN
  IF v_trainee_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_me FROM public.profiles WHERE id = v_trainee_id;

  SELECT * INTO v_sub
  FROM public.trainee_subscriptions s
  WHERE s.trainee_id = v_trainee_id
    AND s.trainer_id = v_me.trainer_id
    AND s.status = 'active'
    AND s.ends_at > timezone('utc', now())
  ORDER BY s.created_at DESC
  LIMIT 1;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: trainer subscribers list
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trainer_list_subscribers()
RETURNS TABLE (
  subscription_id UUID,
  trainee_id UUID,
  first_name VARCHAR,
  last_name VARCHAR,
  avatar_url TEXT,
  plan_title VARCHAR,
  plan_price NUMERIC,
  status public.subscription_status,
  payment_status public.subscription_payment_status,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ
) AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    s.trainee_id,
    p.first_name,
    p.last_name,
    p.avatar_url,
    s.plan_title,
    s.plan_price,
    s.status,
    s.payment_status,
    s.starts_at,
    s.ends_at
  FROM public.trainee_subscriptions s
  JOIN public.profiles p ON p.id = s.trainee_id
  WHERE s.trainer_id = v_trainer_id
  ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: trainer update subscription period
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trainer_update_subscription_period(
  p_subscription_id UUID,
  p_starts_at TIMESTAMPTZ,
  p_ends_at TIMESTAMPTZ
)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_sub public.trainee_subscriptions;
BEGIN
  IF p_ends_at <= p_starts_at THEN
    RAISE EXCEPTION 'ends_at must be after starts_at';
  END IF;

  UPDATE public.trainee_subscriptions
  SET starts_at = p_starts_at,
      ends_at = p_ends_at,
      status = CASE
        WHEN p_ends_at > timezone('utc', now()) THEN 'active'::public.subscription_status
        ELSE 'expired'::public.subscription_status
      END,
      updated_at = timezone('utc', now())
  WHERE id = p_subscription_id
    AND trainer_id = auth.uid()
  RETURNING * INTO v_sub;

  IF v_sub IS NULL THEN
    RAISE EXCEPTION 'Subscription not found';
  END IF;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

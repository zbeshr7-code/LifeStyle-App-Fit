-- Trainer subscription management + Moyasar payment flow

ALTER TYPE public.subscription_status ADD VALUE IF NOT EXISTS 'pending';

-- ---------------------------------------------------------------------------
-- Helper: clear prior active/pending subscriptions for trainee+trainer pair
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._clear_trainee_subscriptions_for_trainer(
  p_trainee_id UUID,
  p_trainer_id UUID,
  p_now TIMESTAMPTZ DEFAULT timezone('utc', now())
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.trainee_subscriptions
  SET status = 'expired',
      updated_at = p_now
  WHERE trainee_id = p_trainee_id
    AND trainer_id = p_trainer_id
    AND status = 'active';

  UPDATE public.trainee_subscriptions
  SET status = 'cancelled',
      updated_at = p_now
  WHERE trainee_id = p_trainee_id
    AND trainer_id = p_trainer_id
    AND status = 'pending';
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: trainer assign subscription (waived, custom dates)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trainer_assign_subscription(
  p_trainee_id UUID,
  p_plan_id UUID,
  p_starts_at TIMESTAMPTZ,
  p_ends_at TIMESTAMPTZ
)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_plan public.subscription_plans;
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_trainer_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Only trainers can assign subscriptions';
  END IF;

  IF NOT public.is_trainer_of_trainee(p_trainee_id) THEN
    RAISE EXCEPTION 'Trainee is not assigned to you';
  END IF;

  IF p_ends_at <= p_starts_at THEN
    RAISE EXCEPTION 'ends_at must be after starts_at';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = p_plan_id
    AND trainer_id = v_trainer_id;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  PERFORM public._clear_trainee_subscriptions_for_trainer(
    p_trainee_id,
    v_trainer_id,
    v_now
  );

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
    p_trainee_id,
    v_trainer_id,
    v_plan.id,
    v_plan.title,
    v_plan.price_amount,
    v_plan.duration_days,
    CASE
      WHEN p_ends_at > v_now THEN 'active'::public.subscription_status
      ELSE 'expired'::public.subscription_status
    END,
    'waived',
    p_starts_at,
    p_ends_at,
    0
  )
  RETURNING * INTO v_sub;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: trainer cancel subscription
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trainer_cancel_subscription(
  p_subscription_id UUID
)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_sub public.trainee_subscriptions;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  UPDATE public.trainee_subscriptions
  SET status = 'cancelled',
      updated_at = timezone('utc', now())
  WHERE id = p_subscription_id
    AND trainer_id = auth.uid()
    AND status IN ('active', 'pending')
  RETURNING * INTO v_sub;

  IF v_sub IS NULL THEN
    RAISE EXCEPTION 'Subscription not found or already cancelled';
  END IF;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: activate paid subscription (service role / Edge Functions only)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.activate_paid_subscription(
  p_subscription_id UUID,
  p_moyasar_payment_id TEXT,
  p_amount_paid NUMERIC
)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
  UPDATE public.trainee_subscriptions
  SET status = 'active',
      payment_status = 'paid',
      starts_at = v_now,
      ends_at = v_now + (duration_days || ' days')::interval,
      amount_paid = p_amount_paid,
      moyasar_payment_id = p_moyasar_payment_id,
      updated_at = v_now
  WHERE id = p_subscription_id
    AND status = 'pending'
    AND payment_status = 'pending_moyasar'
  RETURNING * INTO v_sub;

  IF v_sub IS NULL THEN
    -- Idempotent: already activated
    SELECT * INTO v_sub
    FROM public.trainee_subscriptions
    WHERE id = p_subscription_id
      AND payment_status = 'paid'
      AND status = 'active';

    IF v_sub IS NULL THEN
      RAISE EXCEPTION 'Subscription not found or not pending payment';
    END IF;
  END IF;

  RETURN v_sub;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.activate_paid_subscription(UUID, TEXT, NUMERIC) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.activate_paid_subscription(UUID, TEXT, NUMERIC) TO service_role;

-- ---------------------------------------------------------------------------
-- RPC: initiate plan payment (trainee)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.initiate_plan_payment(p_plan_id UUID)
RETURNS TABLE (
  subscription_id UUID,
  amount_halalas INTEGER,
  plan_title VARCHAR,
  currency VARCHAR
) AS $$
DECLARE
  v_trainee_id UUID := auth.uid();
  v_me public.profiles;
  v_plan public.subscription_plans;
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
  v_halalas INTEGER;
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

  v_halalas := (ROUND(v_plan.price_amount * 100))::INTEGER;

  IF v_plan.price_amount <= 0 OR v_halalas <= 0 THEN
    -- Free plan: immediate waived activation
    PERFORM public._clear_trainee_subscriptions_for_trainer(
      v_trainee_id,
      v_me.trainer_id,
      v_now
    );

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

    RETURN QUERY
    SELECT v_sub.id, 0, v_plan.title, v_plan.currency;
    RETURN;
  END IF;

  PERFORM public._clear_trainee_subscriptions_for_trainer(
    v_trainee_id,
    v_me.trainer_id,
    v_now
  );

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
    ends_at
  ) VALUES (
    v_trainee_id,
    v_me.trainer_id,
    v_plan.id,
    v_plan.title,
    v_plan.price_amount,
    v_plan.duration_days,
    'pending',
    'pending_moyasar',
    v_now,
    v_now + (v_plan.duration_days || ' days')::interval
  )
  RETURNING * INTO v_sub;

  RETURN QUERY
  SELECT v_sub.id, v_halalas, v_plan.title, v_plan.currency;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- RPC: subscribe (trainee, free plans only)
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

  IF v_plan.price_amount > 0 THEN
    RAISE EXCEPTION 'Use initiate_plan_payment for paid plans';
  END IF;

  PERFORM public._clear_trainee_subscriptions_for_trainer(
    v_trainee_id,
    v_me.trainer_id,
    v_now
  );

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

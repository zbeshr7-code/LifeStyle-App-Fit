-- In-app purchase (Google Play / App Store) replaces Moyasar card checkout.

ALTER TYPE public.subscription_payment_status ADD VALUE IF NOT EXISTS 'pending_iap';

ALTER TABLE public.subscription_plans
  ADD COLUMN IF NOT EXISTS store_product_id TEXT;

ALTER TABLE public.trainee_subscriptions
  ADD COLUMN IF NOT EXISTS store_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS store_platform TEXT,
  ADD COLUMN IF NOT EXISTS store_product_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_trainee_subscriptions_store_tx_unique
  ON public.trainee_subscriptions (store_transaction_id)
  WHERE store_transaction_id IS NOT NULL AND store_transaction_id <> '';

CREATE OR REPLACE FUNCTION public.plan_store_product_id(p_duration_days INTEGER)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_duration_days = 30 THEN 'lifestyle_fit_sub_30d'
    WHEN p_duration_days = 90 THEN 'lifestyle_fit_sub_90d'
    ELSE 'lifestyle_fit_sub_180d'
  END;
$$;

UPDATE public.subscription_plans
SET store_product_id = public.plan_store_product_id(duration_days)
WHERE store_product_id IS NULL OR store_product_id = '';

-- ---------------------------------------------------------------------------
-- RPC: upsert plan (trainer) — sets store_product_id from duration
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
  v_store_product_id TEXT;
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

  v_store_product_id := public.plan_store_product_id(p_duration_days);

  IF p_plan_id IS NULL THEN
    INSERT INTO public.subscription_plans (
      trainer_id, title, description, price_amount, duration_days,
      features, is_featured, sort_order, store_product_id
    ) VALUES (
      v_trainer_id,
      p_title,
      p_description,
      COALESCE(p_price_amount, 0),
      p_duration_days,
      COALESCE(p_features, '[]'::jsonb),
      COALESCE(p_is_featured, false),
      COALESCE(p_sort_order, 0),
      v_store_product_id
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
        store_product_id = v_store_product_id,
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

-- ---------------------------------------------------------------------------
-- RPC: activate store purchase (service role / Edge Functions only)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.activate_store_purchase(
  p_subscription_id UUID,
  p_store_product_id TEXT,
  p_store_transaction_id TEXT,
  p_store_platform TEXT,
  p_amount_paid NUMERIC DEFAULT NULL
)
RETURNS public.trainee_subscriptions AS $$
DECLARE
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
BEGIN
  IF p_store_transaction_id IS NULL OR length(trim(p_store_transaction_id)) = 0 THEN
    RAISE EXCEPTION 'store_transaction_id is required';
  END IF;

  SELECT * INTO v_sub
  FROM public.trainee_subscriptions
  WHERE store_transaction_id = p_store_transaction_id
    AND payment_status = 'paid'
    AND status = 'active'
  LIMIT 1;

  IF FOUND THEN
    RETURN v_sub;
  END IF;

  UPDATE public.trainee_subscriptions
  SET status = 'active',
      payment_status = 'paid',
      starts_at = v_now,
      ends_at = v_now + (duration_days || ' days')::interval,
      amount_paid = COALESCE(p_amount_paid, plan_price),
      store_product_id = p_store_product_id,
      store_transaction_id = p_store_transaction_id,
      store_platform = p_store_platform,
      updated_at = v_now
  WHERE id = p_subscription_id
    AND status = 'pending'
    AND payment_status IN ('pending_iap', 'pending_moyasar')
  RETURNING * INTO v_sub;

  IF v_sub IS NULL THEN
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

REVOKE ALL ON FUNCTION public.activate_store_purchase(UUID, TEXT, TEXT, TEXT, NUMERIC) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.activate_store_purchase(UUID, TEXT, TEXT, TEXT, NUMERIC) TO service_role;

-- ---------------------------------------------------------------------------
-- RPC: initiate plan payment (trainee) — returns store_product_id for IAP
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.initiate_plan_payment(UUID);

CREATE FUNCTION public.initiate_plan_payment(p_plan_id UUID)
RETURNS TABLE (
  subscription_id UUID,
  amount_halalas INTEGER,
  plan_title VARCHAR,
  currency VARCHAR,
  store_product_id TEXT
) AS $$
DECLARE
  v_trainee_id UUID := auth.uid();
  v_me public.profiles;
  v_plan public.subscription_plans;
  v_sub public.trainee_subscriptions;
  v_now TIMESTAMPTZ := timezone('utc', now());
  v_halalas INTEGER;
  v_product_id TEXT;
BEGIN
  IF v_trainee_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_me FROM public.profiles WHERE id = v_trainee_id;
  IF v_me IS NULL OR v_me.role != 'trainee' THEN
    RAISE EXCEPTION 'Only trainees can subscribe';
  END IF;

  IF v_me.trainer_id IS NULL THEN
    RAISE EXCEPTION 'Choose a trainer first';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = p_plan_id
    AND trainer_id = v_me.trainer_id
    AND is_active = true;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  v_halalas := (v_plan.price_amount * 100)::INTEGER;
  v_product_id := COALESCE(
    NULLIF(v_plan.store_product_id, ''),
    public.plan_store_product_id(v_plan.duration_days)
  );

  IF v_plan.price_amount <= 0 THEN
    PERFORM public._clear_trainee_subscriptions_for_trainer(
      v_trainee_id,
      v_me.trainer_id,
      v_now
    );

    INSERT INTO public.trainee_subscriptions (
      trainee_id, trainer_id, plan_id, plan_title, plan_price,
      duration_days, status, payment_status, starts_at, ends_at, amount_paid
    ) VALUES (
      v_trainee_id, v_me.trainer_id, v_plan.id, v_plan.title, v_plan.price_amount,
      v_plan.duration_days, 'active', 'waived', v_now,
      v_now + (v_plan.duration_days || ' days')::interval, 0
    )
    RETURNING * INTO v_sub;

    RETURN QUERY SELECT v_sub.id, 0, v_plan.title, v_plan.currency, NULL::TEXT;
    RETURN;
  END IF;

  PERFORM public._clear_trainee_subscriptions_for_trainer(
    v_trainee_id,
    v_me.trainer_id,
    v_now
  );

  INSERT INTO public.trainee_subscriptions (
    trainee_id, trainer_id, plan_id, plan_title, plan_price,
    duration_days, status, payment_status, starts_at, ends_at, store_product_id
  ) VALUES (
    v_trainee_id, v_me.trainer_id, v_plan.id, v_plan.title, v_plan.price_amount,
    v_plan.duration_days, 'pending', 'pending_iap', v_now,
    v_now + (v_plan.duration_days || ' days')::interval, v_product_id
  )
  RETURNING * INTO v_sub;

  RETURN QUERY
  SELECT v_sub.id, v_halalas, v_plan.title, v_plan.currency, v_product_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

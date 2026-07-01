-- Trainer subscription revenue summary with optional date range (on created_at)

CREATE OR REPLACE FUNCTION public.trainer_subscription_revenue(
  p_from TIMESTAMPTZ DEFAULT NULL,
  p_to TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
  total_amount NUMERIC,
  paid_amount NUMERIC,
  subscription_count BIGINT,
  currency VARCHAR
) AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_trainer_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Only trainers can view revenue';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(
      SUM(
        CASE
          WHEN s.status = 'cancelled' THEN 0
          ELSE COALESCE(NULLIF(s.amount_paid, 0), s.plan_price)
        END
      ),
      0
    )::NUMERIC AS total_amount,
    COALESCE(
      SUM(
        CASE
          WHEN s.payment_status = 'paid' THEN COALESCE(s.amount_paid, s.plan_price)
          ELSE 0
        END
      ),
      0
    )::NUMERIC AS paid_amount,
    COUNT(*) FILTER (WHERE s.status != 'cancelled')::BIGINT AS subscription_count,
    'SAR'::VARCHAR AS currency
  FROM public.trainee_subscriptions s
  WHERE s.trainer_id = v_trainer_id
    AND (p_from IS NULL OR s.created_at >= p_from)
    AND (p_to IS NULL OR s.created_at < p_to);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

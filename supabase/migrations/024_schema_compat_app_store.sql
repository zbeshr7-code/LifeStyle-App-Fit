-- Backward compatibility for older App Store builds that queried
-- profiles.full_name and public.user_access.

-- ---------------------------------------------------------------------------
-- profiles.full_name (read + write compat)
-- ---------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS full_name TEXT
  GENERATED ALWAYS AS (trim(both from first_name || ' ' || last_name)) STORED;

COMMENT ON COLUMN public.profiles.full_name IS
  'Generated display name for legacy clients; source of truth remains first_name/last_name.';

-- ---------------------------------------------------------------------------
-- user_access view (subscription / trainer gate for legacy clients)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE VIEW public.user_access
WITH (security_invoker = true) AS
SELECT
  p.id AS user_id,
  p.role::text AS role,
  p.trainer_id,
  (p.role = 'trainer'::public.user_role) AS is_trainer,
  (p.trainer_id IS NOT NULL) AS has_trainer,
  CASE
    WHEN p.role = 'trainer'::public.user_role THEN true
    WHEN p.trainer_id IS NULL THEN false
    ELSE public.has_active_subscription(p.id, p.trainer_id)
  END AS has_access,
  CASE
    WHEN p.role = 'trainer'::public.user_role THEN true
    WHEN p.trainer_id IS NULL THEN false
    ELSE public.has_active_subscription(p.id, p.trainer_id)
  END AS has_subscription,
  s.id AS subscription_id,
  s.status::text AS subscription_status,
  s.ends_at AS subscription_ends_at,
  s.plan_title,
  timezone('utc', now()) AS checked_at
FROM public.profiles p
LEFT JOIN LATERAL (
  SELECT ts.*
  FROM public.trainee_subscriptions ts
  WHERE ts.trainee_id = p.id
    AND ts.trainer_id = p.trainer_id
    AND ts.status = 'active'
    AND ts.ends_at > timezone('utc', now())
  ORDER BY ts.ends_at DESC
  LIMIT 1
) s ON true;

COMMENT ON VIEW public.user_access IS
  'Legacy compatibility view for trainee subscription/trainer access checks.';

GRANT SELECT ON public.user_access TO authenticated;

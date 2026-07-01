-- FCM push notification tokens on profiles

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS fcm_token TEXT,
  ADD COLUMN IF NOT EXISTS fcm_platform VARCHAR CHECK (
    fcm_platform IN ('android', 'ios', 'web', 'unknown')
  ),
  ADD COLUMN IF NOT EXISTS fcm_token_updated_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token
  ON public.profiles (fcm_token)
  WHERE fcm_token IS NOT NULL;

COMMENT ON COLUMN public.profiles.fcm_token IS 'Firebase Cloud Messaging device token';
COMMENT ON COLUMN public.profiles.fcm_platform IS 'Mobile platform for the stored FCM token';

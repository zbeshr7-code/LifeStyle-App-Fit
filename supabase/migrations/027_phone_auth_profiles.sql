-- Phone OTP signup/login: optional email, unique phone, profile trigger updates.

ALTER TABLE public.profiles
  ALTER COLUMN email DROP NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_phone_number_unique
  ON public.profiles (phone_number)
  WHERE phone_number IS NOT NULL AND phone_number <> '';

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.phone IS NOT NULL AND NEW.phone <> '' THEN
    UPDATE auth.users
    SET phone_confirmed_at = COALESCE(phone_confirmed_at, timezone('utc', now()))
    WHERE id = NEW.id;
  END IF;

  IF NEW.email IS NOT NULL AND NEW.email <> '' THEN
    UPDATE auth.users
    SET email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc', now()))
    WHERE id = NEW.id;
  END IF;

  INSERT INTO public.profiles (
    id,
    email,
    phone_number,
    first_name,
    last_name,
    role,
    is_verified
  )
  VALUES (
    NEW.id,
    NULLIF(NEW.email, ''),
    NULLIF(NEW.phone, ''),
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(
      (NEW.raw_user_meta_data->>'role')::public.user_role,
      'trainee'::public.user_role
    ),
    true
  )
  ON CONFLICT (id) DO UPDATE
  SET
    phone_number = COALESCE(EXCLUDED.phone_number, public.profiles.phone_number),
    is_verified = true;

  RETURN NEW;
END;
$$;

-- Fix signup: confirmed_at is GENERATED ALWAYS on auth.users (cannot be updated).
-- Only set email_confirmed_at; confirmed_at is derived automatically.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, timezone('utc', now()))
  WHERE id = NEW.id;

  INSERT INTO public.profiles (
    id,
    email,
    first_name,
    last_name,
    role,
    is_verified
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.email, ''),
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE(
      (NEW.raw_user_meta_data->>'role')::public.user_role,
      'trainee'::public.user_role
    ),
    true
  )
  ON CONFLICT (id) DO UPDATE
  SET is_verified = true;

  RETURN NEW;
END;
$$;

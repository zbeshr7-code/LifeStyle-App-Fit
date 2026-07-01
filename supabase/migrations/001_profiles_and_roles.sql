-- Reference migration aligned with Supabase project LifestyleFit (legcosmcypmrkyzhvbwo)
-- Already applied remotely as: create_auth_profiles_and_roles (20260603042900)

CREATE TYPE user_role AS ENUM ('trainee', 'trainer');

CREATE TABLE public.profiles (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name          VARCHAR NOT NULL,
  last_name           VARCHAR NOT NULL,
  email               VARCHAR NOT NULL UNIQUE,
  phone_number        VARCHAR,
  avatar_url          TEXT,
  bio                 TEXT,
  date_of_birth       DATE,
  gender              VARCHAR CHECK (gender IN ('male', 'female')),
  role                user_role NOT NULL DEFAULT 'trainee',
  specialization      VARCHAR,
  years_of_experience INTEGER CHECK (years_of_experience >= 0),
  certification       TEXT,
  hourly_rate         NUMERIC CHECK (hourly_rate >= 0),
  fitness_goal        TEXT,
  current_weight      NUMERIC CHECK (current_weight > 0),
  target_weight       NUMERIC CHECK (target_weight > 0),
  height_cm           NUMERIC CHECK (height_cm > 0),
  activity_level      VARCHAR CHECK (
    activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')
  ),
  is_active           BOOLEAN NOT NULL DEFAULT true,
  is_verified         BOOLEAN NOT NULL DEFAULT false,
  is_deleted          BOOLEAN NOT NULL DEFAULT false,
  deleted_at          TIMESTAMPTZ,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, first_name, last_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'trainee'::public.user_role)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

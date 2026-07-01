-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
DO $$ BEGIN
    CREATE TYPE day_type AS ENUM ('workout', 'rest', 'cardio');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. PROFILES
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('trainer', 'trainee')),
    avatar_url TEXT,
    trainer_id UUID REFERENCES auth.users(id), -- For trainee to link to their trainer
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- 3. WORKOUT PLANS
CREATE TABLE public.workout_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    trainer_id UUID REFERENCES auth.users(id),
    day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Mon, 6=Sun
    type day_type DEFAULT 'rest',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. EXERCISES
CREATE TABLE public.exercises (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES public.workout_plans(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    video_url TEXT,
    image_url TEXT,
    sets INTEGER DEFAULT 3,
    reps TEXT DEFAULT '12',
    weight DECIMAL DEFAULT 0,
    is_pr_attempt BOOLEAN DEFAULT false,
    order_index INTEGER DEFAULT 0
);

-- 5. MEAL PLANS
CREATE TABLE public.meal_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    meals JSONB, -- Example: [{"title": "Breakfast", "description": "Oats", "time": "08:00"}]
    calories_goal INTEGER DEFAULT 2000,
    protein_goal INTEGER DEFAULT 150,
    carbs_goal INTEGER DEFAULT 200,
    fat_goal INTEGER DEFAULT 60,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 6. PROGRESS TRACKING
CREATE TABLE public.progress_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainee_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    weight DECIMAL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. CHAT
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES auth.users(id),
    receiver_id UUID REFERENCES auth.users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. USER ACCESS
CREATE TABLE public.user_access (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_subscribed BOOLEAN DEFAULT false,
    access_granted_by_trainer BOOLEAN DEFAULT false,
    expiry_date TIMESTAMPTZ
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_access ENABLE ROW LEVEL SECURITY;

-- Polices (Simplified)
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id OR auth.uid() = trainer_id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own workout plans" ON public.workout_plans FOR SELECT USING (auth.uid() = trainee_id OR auth.uid() = trainer_id);
CREATE POLICY "Users can view own meal plans" ON public.meal_plans FOR SELECT USING (auth.uid() = trainee_id);
CREATE POLICY "Users can view own messages" ON public.messages FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);
CREATE POLICY "Users can view own access" ON public.user_access FOR SELECT USING (auth.uid() = user_id);

-- TRIGGER for profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Unknown'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'role', 'trainee')
  );

  -- Create default access entry
  INSERT INTO public.user_access (user_id) VALUES (new.id);

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

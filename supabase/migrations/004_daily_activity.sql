-- Daily step tracking for trainees

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS daily_step_goal INTEGER NOT NULL DEFAULT 10000
  CHECK (daily_step_goal > 0);

CREATE TABLE public.daily_activity (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  steps         INTEGER NOT NULL DEFAULT 0 CHECK (steps >= 0),
  calories      NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (calories >= 0),
  distance_km   NUMERIC(10, 3) NOT NULL DEFAULT 0 CHECK (distance_km >= 0),
  goal_steps    INTEGER NOT NULL DEFAULT 10000 CHECK (goal_steps > 0),
  source        TEXT NOT NULL DEFAULT 'pedometer',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (user_id, activity_date)
);

CREATE INDEX idx_daily_activity_user_date
  ON public.daily_activity (user_id, activity_date DESC);

CREATE OR REPLACE FUNCTION public.set_daily_activity_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_daily_activity_updated
  BEFORE UPDATE ON public.daily_activity
  FOR EACH ROW EXECUTE FUNCTION public.set_daily_activity_updated_at();

-- Upsert today's (or any) activity row for the authenticated user
CREATE OR REPLACE FUNCTION public.upsert_daily_activity(
  p_date DATE,
  p_steps INTEGER,
  p_calories NUMERIC,
  p_distance_km NUMERIC,
  p_goal_steps INTEGER
)
RETURNS public.daily_activity AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_row public.daily_activity;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.daily_activity (
    user_id, activity_date, steps, calories, distance_km, goal_steps, source
  )
  VALUES (
    v_user_id, p_date, p_steps, p_calories, p_distance_km, p_goal_steps, 'pedometer'
  )
  ON CONFLICT (user_id, activity_date) DO UPDATE SET
    steps = EXCLUDED.steps,
    calories = EXCLUDED.calories,
    distance_km = EXCLUDED.distance_km,
    goal_steps = EXCLUDED.goal_steps,
    source = EXCLUDED.source,
    updated_at = timezone('utc', now())
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Fetch activity rows in a date range for charts/history
CREATE OR REPLACE FUNCTION public.get_activity_summary(
  p_from_date DATE,
  p_to_date DATE
)
RETURNS SETOF public.daily_activity AS $$
  SELECT *
  FROM public.daily_activity
  WHERE user_id = auth.uid()
    AND activity_date >= p_from_date
    AND activity_date <= p_to_date
  ORDER BY activity_date ASC;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

ALTER TABLE public.daily_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own daily activity"
  ON public.daily_activity FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users insert own daily activity"
  ON public.daily_activity FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users update own daily activity"
  ON public.daily_activity FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

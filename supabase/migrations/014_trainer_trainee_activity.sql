-- Trainers can read assigned trainees' step history

CREATE OR REPLACE FUNCTION public.is_trainer_of_trainee(p_trainee_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = p_trainee_id
      AND p.trainer_id = auth.uid()
      AND p.role = 'trainee'
      AND p.is_active = true
      AND p.is_deleted = false
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_trainee_activity_summary(
  p_trainee_id UUID,
  p_from_date DATE,
  p_to_date DATE
)
RETURNS SETOF public.daily_activity AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT public.is_trainer_of_trainee(p_trainee_id) THEN
    RAISE EXCEPTION 'Not authorized to view this trainee activity';
  END IF;

  RETURN QUERY
  SELECT da.*
  FROM public.daily_activity da
  WHERE da.user_id = p_trainee_id
    AND da.activity_date >= p_from_date
    AND da.activity_date <= p_to_date
  ORDER BY da.activity_date ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_trainee_activity_history(
  p_trainee_id UUID,
  p_limit INTEGER DEFAULT 30,
  p_offset INTEGER DEFAULT 0
)
RETURNS SETOF public.daily_activity AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT public.is_trainer_of_trainee(p_trainee_id) THEN
    RAISE EXCEPTION 'Not authorized to view this trainee activity';
  END IF;

  RETURN QUERY
  SELECT da.*
  FROM public.daily_activity da
  WHERE da.user_id = p_trainee_id
  ORDER BY da.activity_date DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

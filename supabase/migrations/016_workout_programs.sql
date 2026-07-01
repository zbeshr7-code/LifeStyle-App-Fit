-- Workout programs: weekly schedule + exercises per day (trainer manages)

CREATE TYPE public.workout_day_type AS ENUM ('workout', 'cardio', 'rest');

CREATE TABLE public.workout_programs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainee_id  UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name        VARCHAR NOT NULL DEFAULT 'My Program',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE public.workout_schedule_days (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id   UUID NOT NULL REFERENCES public.workout_programs(id) ON DELETE CASCADE,
  trainee_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  day_of_week  SMALLINT NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  day_type     public.workout_day_type NOT NULL DEFAULT 'rest',
  label        VARCHAR NOT NULL DEFAULT '',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (program_id, day_of_week)
);

CREATE INDEX idx_workout_schedule_program
  ON public.workout_schedule_days (program_id, day_of_week);

CREATE TABLE public.workout_exercises (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_day_id  UUID NOT NULL REFERENCES public.workout_schedule_days(id) ON DELETE CASCADE,
  trainee_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name             VARCHAR NOT NULL,
  sets             INTEGER CHECK (sets IS NULL OR sets > 0),
  reps             INTEGER CHECK (reps IS NULL OR reps > 0),
  target_weight_kg NUMERIC CHECK (target_weight_kg IS NULL OR target_weight_kg >= 0),
  video_url        TEXT,
  photo_path       TEXT,
  notes            TEXT,
  sort_order       INTEGER NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_workout_exercises_day
  ON public.workout_exercises (schedule_day_id, sort_order);

CREATE OR REPLACE FUNCTION public.set_workout_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER on_workout_program_updated
  BEFORE UPDATE ON public.workout_programs
  FOR EACH ROW EXECUTE FUNCTION public.set_workout_updated_at();

CREATE TRIGGER on_workout_schedule_day_updated
  BEFORE UPDATE ON public.workout_schedule_days
  FOR EACH ROW EXECUTE FUNCTION public.set_workout_updated_at();

CREATE TRIGGER on_workout_exercise_updated
  BEFORE UPDATE ON public.workout_exercises
  FOR EACH ROW EXECUTE FUNCTION public.set_workout_updated_at();

ALTER TABLE public.workout_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_schedule_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_exercises ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainees read own workout programs"
  ON public.workout_programs FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers manage assigned workout programs"
  ON public.workout_programs FOR ALL
  USING (public.is_trainer_of_trainee(trainee_id))
  WITH CHECK (
    trainer_id = auth.uid()
    AND public.is_trainer_of_trainee(trainee_id)
  );

CREATE POLICY "Trainees read own workout schedule"
  ON public.workout_schedule_days FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers manage assigned workout schedule"
  ON public.workout_schedule_days FOR ALL
  USING (public.is_trainer_of_trainee(trainee_id))
  WITH CHECK (public.is_trainer_of_trainee(trainee_id));

CREATE POLICY "Trainees read own workout exercises"
  ON public.workout_exercises FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers manage assigned workout exercises"
  ON public.workout_exercises FOR ALL
  USING (public.is_trainer_of_trainee(trainee_id))
  WITH CHECK (
    trainer_id = auth.uid()
    AND public.is_trainer_of_trainee(trainee_id)
  );

-- Create program + 7 default rest days if missing (trainer only)
CREATE OR REPLACE FUNCTION public.ensure_workout_program(p_trainee_id UUID)
RETURNS public.workout_programs AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_program public.workout_programs;
  v_day SMALLINT;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT public.is_trainer_of_trainee(p_trainee_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  SELECT * INTO v_program
  FROM public.workout_programs
  WHERE trainee_id = p_trainee_id;

  IF v_program IS NULL THEN
    INSERT INTO public.workout_programs (trainee_id, trainer_id, name)
    VALUES (p_trainee_id, v_trainer_id, 'My Program')
    RETURNING * INTO v_program;

    FOR v_day IN 0..6 LOOP
      INSERT INTO public.workout_schedule_days (
        program_id, trainee_id, day_of_week, day_type, label
      ) VALUES (
        v_program.id, p_trainee_id, v_day, 'rest', ''
      );
    END LOOP;
  END IF;

  RETURN v_program;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reorder_workout_exercises(
  p_schedule_day_id UUID,
  p_exercise_ids UUID[]
)
RETURNS VOID AS $$
DECLARE
  v_trainee_id UUID;
  v_exercise_id UUID;
  v_index INTEGER := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT trainee_id INTO v_trainee_id
  FROM public.workout_schedule_days
  WHERE id = p_schedule_day_id;

  IF v_trainee_id IS NULL OR NOT public.is_trainer_of_trainee(v_trainee_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  FOREACH v_exercise_id IN ARRAY p_exercise_ids LOOP
    UPDATE public.workout_exercises
    SET sort_order = v_index,
        updated_at = timezone('utc', now())
    WHERE id = v_exercise_id
      AND schedule_day_id = p_schedule_day_id;
    v_index := v_index + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('workout-media', 'workout-media', false, 10485760)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainee read own workout media'
  ) THEN
    CREATE POLICY "Trainee read own workout media"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'workout-media'
        AND auth.uid() IS NOT NULL
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainer read trainee workout media'
  ) THEN
    CREATE POLICY "Trainer read trainee workout media"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'workout-media'
        AND auth.uid() IS NOT NULL
        AND public.is_trainer_of_trainee(((storage.foldername(name))[1])::uuid)
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainer upload trainee workout media'
  ) THEN
    CREATE POLICY "Trainer upload trainee workout media"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'workout-media'
        AND auth.uid() IS NOT NULL
        AND public.is_trainer_of_trainee(((storage.foldername(name))[1])::uuid)
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainer update trainee workout media'
  ) THEN
    CREATE POLICY "Trainer update trainee workout media"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'workout-media'
        AND auth.uid() IS NOT NULL
        AND public.is_trainer_of_trainee(((storage.foldername(name))[1])::uuid)
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainer delete trainee workout media'
  ) THEN
    CREATE POLICY "Trainer delete trainee workout media"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'workout-media'
        AND auth.uid() IS NOT NULL
        AND public.is_trainer_of_trainee(((storage.foldername(name))[1])::uuid)
      );
  END IF;
END $$;

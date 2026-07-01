-- Nutrition meal plans: trainer manages, trainee reads

CREATE TYPE public.nutrition_day_type AS ENUM ('workout', 'rest');

CREATE TABLE public.nutrition_meals (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trainee_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainer_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  day_type    public.nutrition_day_type NOT NULL,
  title       VARCHAR NOT NULL,
  food_items  TEXT NOT NULL DEFAULT '',
  calories    INTEGER NOT NULL DEFAULT 0 CHECK (calories >= 0),
  notes       TEXT,
  photo_path  TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_nutrition_meals_trainee_day
  ON public.nutrition_meals (trainee_id, day_type, sort_order);

CREATE OR REPLACE FUNCTION public.set_nutrition_meal_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER on_nutrition_meal_updated
  BEFORE UPDATE ON public.nutrition_meals
  FOR EACH ROW EXECUTE FUNCTION public.set_nutrition_meal_updated_at();

ALTER TABLE public.nutrition_meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Trainees read own nutrition meals"
  ON public.nutrition_meals FOR SELECT
  USING (trainee_id = auth.uid());

CREATE POLICY "Trainers manage assigned trainee meals"
  ON public.nutrition_meals FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = trainee_id
        AND p.trainer_id = auth.uid()
        AND p.role = 'trainee'
    )
  )
  WITH CHECK (
    trainer_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = trainee_id
        AND p.trainer_id = auth.uid()
        AND p.role = 'trainee'
    )
  );

-- Reorder meals for a trainee/day type (trainer only)
CREATE OR REPLACE FUNCTION public.reorder_nutrition_meals(
  p_trainee_id UUID,
  p_day_type public.nutrition_day_type,
  p_meal_ids UUID[]
)
RETURNS VOID AS $$
DECLARE
  v_trainer_id UUID := auth.uid();
  v_meal_id UUID;
  v_index INTEGER := 0;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF NOT public.is_trainer_of_trainee(p_trainee_id) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  FOREACH v_meal_id IN ARRAY p_meal_ids LOOP
    UPDATE public.nutrition_meals
    SET sort_order = v_index,
        updated_at = timezone('utc', now())
    WHERE id = v_meal_id
      AND trainee_id = p_trainee_id
      AND day_type = p_day_type
      AND trainer_id = v_trainer_id;
    v_index := v_index + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Private meal photos bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('meal-photos', 'meal-photos', false, 10485760)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Trainee read own meal photos'
  ) THEN
    CREATE POLICY "Trainee read own meal photos"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'meal-photos'
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
      AND policyname = 'Trainer read trainee meal photos'
  ) THEN
    CREATE POLICY "Trainer read trainee meal photos"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'meal-photos'
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
      AND policyname = 'Trainer upload trainee meal photos'
  ) THEN
    CREATE POLICY "Trainer upload trainee meal photos"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'meal-photos'
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
      AND policyname = 'Trainer update trainee meal photos'
  ) THEN
    CREATE POLICY "Trainer update trainee meal photos"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'meal-photos'
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
      AND policyname = 'Trainer delete trainee meal photos'
  ) THEN
    CREATE POLICY "Trainer delete trainee meal photos"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'meal-photos'
        AND auth.uid() IS NOT NULL
        AND public.is_trainer_of_trainee(((storage.foldername(name))[1])::uuid)
      );
  END IF;
END $$;

-- Trainee evolution progress entries + photos (private storage)

CREATE TABLE public.trainee_progress_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  recorded_at DATE NOT NULL DEFAULT CURRENT_DATE,
  weight_kg   NUMERIC CHECK (weight_kg IS NULL OR weight_kg > 0),
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_progress_entries_user_date
  ON public.trainee_progress_entries(user_id, recorded_at DESC);

CREATE TABLE public.trainee_progress_photos (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_id     UUID NOT NULL REFERENCES public.trainee_progress_entries(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  sort_order   INTEGER NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_progress_photos_entry
  ON public.trainee_progress_photos(entry_id, sort_order);

CREATE OR REPLACE FUNCTION public.update_progress_entry_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER on_progress_entry_updated
  BEFORE UPDATE ON public.trainee_progress_entries
  FOR EACH ROW EXECUTE FUNCTION public.update_progress_entry_timestamp();

ALTER TABLE public.trainee_progress_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainee_progress_photos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own progress entries"
  ON public.trainee_progress_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users manage own progress photos"
  ON public.trainee_progress_photos FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('progress-photos', 'progress-photos', false, 10485760)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'Users upload own progress photos'
  ) THEN
    CREATE POLICY "Users upload own progress photos"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'progress-photos'
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
      AND policyname = 'Users read own progress photos'
  ) THEN
    CREATE POLICY "Users read own progress photos"
      ON storage.objects FOR SELECT
      USING (
        bucket_id = 'progress-photos'
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
      AND policyname = 'Users update own progress photos'
  ) THEN
    CREATE POLICY "Users update own progress photos"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'progress-photos'
        AND auth.uid() IS NOT NULL
        AND (storage.foldername(name))[1] = auth.uid()::text
      )
      WITH CHECK (
        bucket_id = 'progress-photos'
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
      AND policyname = 'Users delete own progress photos'
  ) THEN
    CREATE POLICY "Users delete own progress photos"
      ON storage.objects FOR DELETE
      USING (
        bucket_id = 'progress-photos'
        AND auth.uid() IS NOT NULL
        AND (storage.foldername(name))[1] = auth.uid()::text
      );
  END IF;
END $$;

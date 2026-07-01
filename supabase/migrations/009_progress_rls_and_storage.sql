-- Complete progress gallery RLS + storage (tables existed without policies/bucket)

ALTER TABLE public.trainee_progress_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainee_progress_photos ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users manage own progress entries"
    ON public.trainee_progress_entries FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE POLICY "Users manage own progress photos"
    ON public.trainee_progress_photos FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

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

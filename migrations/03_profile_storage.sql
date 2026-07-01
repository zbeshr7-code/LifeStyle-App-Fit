-- 1. Create a storage bucket for avatars (Note: Buckets are often created via the UI, but policies are SQL)
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);

-- 2. Storage Policies for avatars bucket
CREATE POLICY "Public profiles are viewable by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- 3. Ensure profiles table has necessary columns (already exists from previous steps, but just in case)
-- ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;

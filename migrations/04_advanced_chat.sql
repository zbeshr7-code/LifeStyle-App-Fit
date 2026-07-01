-- 1. Create a storage bucket for chat media
-- insert into storage.buckets (id, name, public) values ('chat_media', 'chat_media', true);

-- 2. Storage Policies for chat_media bucket
CREATE POLICY "Chat media is viewable by participants"
ON storage.objects FOR SELECT
USING (bucket_id = 'chat_media');

CREATE POLICY "Users can upload chat media"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'chat_media');

-- 3. Update messages table to support media
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS type TEXT DEFAULT 'text' CHECK (type IN ('text', 'image', 'audio'));
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS duration INTEGER; -- For audio messages in seconds

-- Fix workout-media uploads (mime types + upsert updates)

UPDATE storage.buckets
SET
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
    'image/heif'
  ],
  file_size_limit = 10485760
WHERE id = 'workout-media';

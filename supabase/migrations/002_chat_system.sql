-- Chat system: direct trainer <-> trainee rooms

CREATE TYPE message_type AS ENUM ('text', 'image', 'file', 'audio');

CREATE TABLE public.chat_rooms (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE public.chat_room_members (
  room_id       UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  user_id       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_read_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  joined_at     TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  PRIMARY KEY (room_id, user_id)
);

CREATE TABLE public.chat_messages (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id           UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  sender_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type              message_type NOT NULL DEFAULT 'text',
  content           TEXT,
  media_url         TEXT,
  file_name         TEXT,
  file_size         INTEGER,
  audio_duration_ms INTEGER,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX idx_chat_messages_room_created ON public.chat_messages(room_id, created_at DESC);
CREATE INDEX idx_chat_room_members_user ON public.chat_room_members(user_id);

-- Update room timestamp on new message
CREATE OR REPLACE FUNCTION public.update_chat_room_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.chat_rooms SET updated_at = NEW.created_at WHERE id = NEW.room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_chat_message_created
  AFTER INSERT ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION public.update_chat_room_timestamp();

-- Helper: is member of room
CREATE OR REPLACE FUNCTION public.is_chat_room_member(p_room_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.chat_room_members
    WHERE room_id = p_room_id AND user_id = p_user_id
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Get or create direct room between trainer and trainee
CREATE OR REPLACE FUNCTION public.get_or_create_direct_room(p_peer_id UUID)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_my_role public.user_role;
  v_peer_role public.user_role;
  v_room_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_peer_id = v_user_id THEN
    RAISE EXCEPTION 'Cannot chat with yourself';
  END IF;

  SELECT role INTO v_my_role FROM public.profiles WHERE id = v_user_id;
  SELECT role INTO v_peer_role FROM public.profiles WHERE id = p_peer_id;

  IF v_my_role IS NULL OR v_peer_role IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_my_role = v_peer_role THEN
    RAISE EXCEPTION 'Chat allowed only between trainer and trainee';
  END IF;

  SELECT crm1.room_id INTO v_room_id
  FROM public.chat_room_members crm1
  JOIN public.chat_room_members crm2 ON crm1.room_id = crm2.room_id
  WHERE crm1.user_id = v_user_id
    AND crm2.user_id = p_peer_id
  LIMIT 1;

  IF v_room_id IS NOT NULL THEN
    RETURN v_room_id;
  END IF;

  INSERT INTO public.chat_rooms DEFAULT VALUES RETURNING id INTO v_room_id;

  INSERT INTO public.chat_room_members (room_id, user_id)
  VALUES (v_room_id, v_user_id), (v_room_id, p_peer_id);

  RETURN v_room_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Room list with unread counts for current user
CREATE OR REPLACE FUNCTION public.get_chat_rooms_for_user()
RETURNS TABLE (
  room_id UUID,
  peer_id UUID,
  peer_first_name TEXT,
  peer_last_name TEXT,
  peer_avatar_url TEXT,
  peer_role public.user_role,
  last_message_type message_type,
  last_message_content TEXT,
  last_message_at TIMESTAMPTZ,
  unread_count BIGINT
) AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  RETURN QUERY
  WITH my_rooms AS (
    SELECT crm.room_id, crm.last_read_at
    FROM public.chat_room_members crm
    WHERE crm.user_id = v_user_id
  ),
  peers AS (
    SELECT crm.room_id, p.id AS peer_id,
           p.first_name::TEXT, p.last_name::TEXT,
           p.avatar_url, p.role AS peer_role
    FROM public.chat_room_members crm
    JOIN public.profiles p ON p.id = crm.user_id
    WHERE crm.room_id IN (SELECT mr1.room_id FROM my_rooms mr1)
      AND crm.user_id != v_user_id
  ),
  last_msgs AS (
    SELECT DISTINCT ON (cm.room_id)
      cm.room_id, cm.type AS last_message_type, cm.content AS last_message_content,
      cm.created_at AS last_message_at
    FROM public.chat_messages cm
    WHERE cm.room_id IN (SELECT mr2.room_id FROM my_rooms mr2)
    ORDER BY cm.room_id, cm.created_at DESC
  ),
  unread AS (
    SELECT cm.room_id, COUNT(*) AS unread_count
    FROM public.chat_messages cm
    JOIN my_rooms mr ON mr.room_id = cm.room_id
    WHERE cm.sender_id != v_user_id
      AND cm.created_at > mr.last_read_at
    GROUP BY cm.room_id
  )
  SELECT
    mr.room_id,
    p.peer_id,
    p.first_name::TEXT AS peer_first_name,
    p.last_name::TEXT AS peer_last_name,
    p.avatar_url AS peer_avatar_url,
    p.peer_role,
    lm.last_message_type,
    lm.last_message_content,
    lm.last_message_at,
    COALESCE(u.unread_count, 0)
  FROM my_rooms mr
  JOIN peers p ON p.room_id = mr.room_id
  LEFT JOIN last_msgs lm ON lm.room_id = mr.room_id
  LEFT JOIN unread u ON u.room_id = mr.room_id
  ORDER BY COALESCE(lm.last_message_at, (SELECT created_at FROM public.chat_rooms WHERE id = mr.room_id)) DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Mark room as read
CREATE OR REPLACE FUNCTION public.mark_chat_room_read(p_room_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.chat_room_members
  SET last_read_at = timezone('utc', now())
  WHERE room_id = p_room_id AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- RLS
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Members can view their rooms"
  ON public.chat_rooms FOR SELECT
  USING (public.is_chat_room_member(id, auth.uid()));

CREATE POLICY "Members can view room membership"
  ON public.chat_room_members FOR SELECT
  USING (public.is_chat_room_member(room_id, auth.uid()));

CREATE POLICY "Members can update own read status"
  ON public.chat_room_members FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Members can view messages"
  ON public.chat_messages FOR SELECT
  USING (public.is_chat_room_member(room_id, auth.uid()));

CREATE POLICY "Members can send messages"
  ON public.chat_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND public.is_chat_room_member(room_id, auth.uid())
  );

-- Allow reading opposite-role profiles for chat picker (no self-join under RLS)
CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS public.user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE POLICY "Users can view profiles for chat"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR (
      public.get_auth_user_role() IS NOT NULL
      AND role IS NOT NULL
      AND role != public.get_auth_user_role()
    )
  );

-- Storage bucket for chat media
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('chat-media', 'chat-media', false, 52428800)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Chat members can upload media"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'chat-media'
    AND auth.uid() IS NOT NULL
    AND public.is_chat_room_member((storage.foldername(name))[1]::uuid, auth.uid())
  );

CREATE POLICY "Chat members can read media"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'chat-media'
    AND public.is_chat_room_member((storage.foldername(name))[1]::uuid, auth.uid())
  );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

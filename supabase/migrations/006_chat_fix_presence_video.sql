-- Fix chat rooms list RPC (wrong column aliases) + presence + video message type

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;

DO $$
BEGIN
  ALTER TYPE message_type ADD VALUE IF NOT EXISTS 'video';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

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

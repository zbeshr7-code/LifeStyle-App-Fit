-- Trainer–trainee assignment: each trainee picks one trainer

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_trainer_id
  ON public.profiles (trainer_id)
  WHERE trainer_id IS NOT NULL;

-- Prevent trainers from having a trainer_id
CREATE OR REPLACE FUNCTION public.validate_trainer_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.role = 'trainer' AND NEW.trainer_id IS NOT NULL THEN
    RAISE EXCEPTION 'Trainers cannot have a trainer_id';
  END IF;
  IF NEW.trainer_id IS NOT NULL AND NEW.role != 'trainee' THEN
    RAISE EXCEPTION 'Only trainees can have a trainer_id';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

DROP TRIGGER IF EXISTS on_profile_trainer_id_validate ON public.profiles;
CREATE TRIGGER on_profile_trainer_id_validate
  BEFORE INSERT OR UPDATE OF trainer_id, role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.validate_trainer_id();

-- Trainee assigns or changes their trainer
CREATE OR REPLACE FUNCTION public.assign_trainer(p_trainer_id UUID)
RETURNS public.profiles AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_me public.profiles;
  v_trainer public.profiles;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT * INTO v_me FROM public.profiles WHERE id = v_user_id;
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;
  IF v_me.role != 'trainee' THEN
    RAISE EXCEPTION 'Only trainees can assign a trainer';
  END IF;

  SELECT * INTO v_trainer FROM public.profiles WHERE id = p_trainer_id;
  IF v_trainer IS NULL THEN
    RAISE EXCEPTION 'Trainer not found';
  END IF;
  IF v_trainer.role != 'trainer' THEN
    RAISE EXCEPTION 'Selected user is not a trainer';
  END IF;
  IF NOT v_trainer.is_active OR v_trainer.is_deleted THEN
    RAISE EXCEPTION 'Trainer is not available';
  END IF;

  UPDATE public.profiles
  SET trainer_id = p_trainer_id,
      updated_at = timezone('utc', now())
  WHERE id = v_user_id
  RETURNING * INTO v_me;

  RETURN v_me;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trainee: get assigned trainer profile
CREATE OR REPLACE FUNCTION public.get_my_trainer()
RETURNS public.profiles AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_trainer_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT trainer_id INTO v_trainer_id
  FROM public.profiles
  WHERE id = v_user_id AND role = 'trainee';

  IF v_trainer_id IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN (
    SELECT p FROM public.profiles p
    WHERE p.id = v_trainer_id
      AND p.role = 'trainer'
      AND p.is_active = true
      AND p.is_deleted = false
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Trainer: list assigned trainees
CREATE OR REPLACE FUNCTION public.get_my_trainees()
RETURNS SETOF public.profiles AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT p.*
  FROM public.profiles p
  WHERE p.trainer_id = v_user_id
    AND p.role = 'trainee'
    AND p.is_active = true
    AND p.is_deleted = false
  ORDER BY p.first_name, p.last_name;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Trainee: list trainers available for assignment
CREATE OR REPLACE FUNCTION public.list_available_trainers()
RETURNS SETOF public.profiles AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  RETURN QUERY
  SELECT p.*
  FROM public.profiles p
  WHERE p.role = 'trainer'
    AND p.is_active = true
    AND p.is_deleted = false
  ORDER BY p.first_name, p.last_name;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Enforce assignment in chat room creation
CREATE OR REPLACE FUNCTION public.get_or_create_direct_room(p_peer_id UUID)
RETURNS UUID AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_my_role public.user_role;
  v_peer_role public.user_role;
  v_my_trainer_id UUID;
  v_room_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF p_peer_id = v_user_id THEN
    RAISE EXCEPTION 'Cannot chat with yourself';
  END IF;

  SELECT role, trainer_id INTO v_my_role, v_my_trainer_id
  FROM public.profiles WHERE id = v_user_id;

  SELECT role INTO v_peer_role FROM public.profiles WHERE id = p_peer_id;

  IF v_my_role IS NULL OR v_peer_role IS NULL THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  IF v_my_role = v_peer_role THEN
    RAISE EXCEPTION 'Chat allowed only between trainer and trainee';
  END IF;

  IF v_my_role = 'trainee' THEN
    IF v_my_trainer_id IS NULL OR v_my_trainer_id != p_peer_id THEN
      RAISE EXCEPTION 'Chat allowed only with your assigned trainer';
    END IF;
  ELSE
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = p_peer_id
        AND trainer_id = v_user_id
        AND role = 'trainee'
    ) THEN
      RAISE EXCEPTION 'Chat allowed only with your assigned trainees';
    END IF;
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

-- RLS: trainers read assigned trainees; trainees read assigned trainer
CREATE OR REPLACE FUNCTION public.get_my_trainer_id()
RETURNS UUID AS $$
  SELECT trainer_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Users can view profiles for chat" ON public.profiles;

CREATE POLICY "Users can view profiles for chat"
  ON public.profiles FOR SELECT
  USING (
    auth.uid() = id
    OR (
      public.get_auth_user_role() IS NOT NULL
      AND role IS NOT NULL
      AND role != public.get_auth_user_role()
      AND (
        (public.get_auth_user_role() = 'trainer' AND trainer_id = auth.uid())
        OR (public.get_auth_user_role() = 'trainee' AND id = public.get_my_trainer_id())
      )
    )
  );

CREATE POLICY "Trainees can list trainers for assignment"
  ON public.profiles FOR SELECT
  USING (
    role = 'trainer'
    AND is_active = true
    AND is_deleted = false
    AND public.get_auth_user_role() = 'trainee'::public.user_role
  );

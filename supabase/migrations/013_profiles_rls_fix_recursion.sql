-- Fix infinite recursion in profiles RLS (no subqueries on profiles in policies)

CREATE OR REPLACE FUNCTION public.get_my_trainer_id()
RETURNS UUID AS $$
  SELECT trainer_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Users can view profiles for chat" ON public.profiles;
DROP POLICY IF EXISTS "Trainees can list trainers for assignment" ON public.profiles;

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

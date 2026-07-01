-- Fix infinite RLS recursion: chat profile policy must not subquery profiles under RLS.

CREATE OR REPLACE FUNCTION public.get_auth_user_role()
RETURNS public.user_role AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
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
    )
  );

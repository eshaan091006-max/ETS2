-- ====================================================================
-- MIGRATION: Row Level Security (RLS) Policies for Core Tables
-- ====================================================================
--
-- Why is this needed?
-- RLS prevents unauthorized users from editing or viewing data. Since you have
-- enabled RLS on your tables (or are about to), you need explicit policies to:
-- 1. Allow SELECT access to everyone (so users can view events, scores, etc.).
-- 2. Allow ALL (Insert/Update/Delete) access to users logged in as admins.
--
-- INSTRUCTIONS:
-- Run this ENTIRE script in your Supabase SQL Editor (https://supabase.com/dashboard)
-- ====================================================================

-- 1️⃣ Enable RLS on core tables
ALTER TABLE public.department ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contingents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.form_links ENABLE ROW LEVEL SECURITY;

-- Helper function to check if the current user is an admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'user_role', 
    ''
  ) = 'admin';
END;
$$;


-- ====================================================================
-- 2️⃣ Department Table Policies
-- ====================================================================
DROP POLICY IF EXISTS "Allow public read access to departments" ON public.department;
CREATE POLICY "Allow public read access to departments"
  ON public.department
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow admins full write access to departments" ON public.department;
CREATE POLICY "Allow admins full write access to departments"
  ON public.department
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ====================================================================
-- 3️⃣ Events Table Policies
-- ====================================================================
DROP POLICY IF EXISTS "Allow public read access to events" ON public.events;
CREATE POLICY "Allow public read access to events"
  ON public.events
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow admins full write access to events" ON public.events;
CREATE POLICY "Allow admins full write access to events"
  ON public.events
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ====================================================================
-- 4️⃣ Contingents Table Policies
-- ====================================================================
DROP POLICY IF EXISTS "Allow public read access to contingents" ON public.contingents;
CREATE POLICY "Allow public read access to contingents"
  ON public.contingents
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow admins full write access to contingents" ON public.contingents;
CREATE POLICY "Allow admins full write access to contingents"
  ON public.contingents
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ====================================================================
-- 5️⃣ Participations Table Policies
-- ====================================================================
DROP POLICY IF EXISTS "Allow public read access to participations" ON public.participations;
CREATE POLICY "Allow public read access to participations"
  ON public.participations
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Allow admins full write access to participations" ON public.participations;
CREATE POLICY "Allow admins full write access to participations"
  ON public.participations
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());


-- ====================================================================
-- 6️⃣ Form Links Table Policies
-- ====================================================================
DROP POLICY IF EXISTS "Admins can view all form links" ON public.form_links;
CREATE POLICY "Admins can view all form links"
  ON public.form_links
  FOR SELECT
  TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS "Contingents can see only visible form links" ON public.form_links;
DROP POLICY IF EXISTS "Contingents can view visible form links" ON public.form_links;
CREATE POLICY "Contingents can view visible form links"
  ON public.form_links
  FOR SELECT
  TO authenticated
  USING (
    coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'user_role', '') = 'contingent'
    AND (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'contingent_id')::bigint = ANY(visible_to)
  );

DROP POLICY IF EXISTS "Allow admins full write access to form_links" ON public.form_links;
CREATE POLICY "Allow admins full write access to form_links"
  ON public.form_links
  FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

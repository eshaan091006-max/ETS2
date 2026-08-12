-- Migration: Convert `visible_to` column on `form_links` to bigint[]
-- This migration drops the existing RLS policy that depends on the column,
-- alters the column type, sets a sensible default, and re‑creates the policy.
-- Replace the placeholder condition in the CREATE POLICY statement with the
-- actual logic you use in your project (e.g., checking that the current user ID
-- is present in the array).

BEGIN;

-- 1️⃣ Drop the policy that references `visible_to`
DROP POLICY IF EXISTS "Contingents can see only visible form links" ON public.form_links;

ALTER TABLE public.form_links
  ALTER COLUMN visible_to
  TYPE bigint[]
  USING ARRAY[visible_to];

-- 3️⃣ Set a default empty array (no visibility)
ALTER TABLE public.form_links
  ALTER COLUMN visible_to SET DEFAULT '{}'::bigint[];

-- 4️⃣ Re‑create the policy (compare UUID as text to integer as text)
CREATE POLICY "Contingents can see only visible form links"
  ON public.form_links
  FOR SELECT USING (
    auth.uid()::text = ANY(visible_to::text[])
  );

COMMIT;

-- Migration: Add collab_dept_ids column to events table
BEGIN;

ALTER TABLE public.events 
ADD COLUMN IF NOT EXISTS collab_dept_ids int4[] DEFAULT '{}';

COMMIT;

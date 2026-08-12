-- Migration: Update "Local Performing Arts" to "Indian Performing Arts"
BEGIN;

UPDATE public.department
SET name = 'Indian Performing Arts', code = 'IPA'
WHERE name = 'Local Performing Arts' OR code = 'LPA';

COMMIT;

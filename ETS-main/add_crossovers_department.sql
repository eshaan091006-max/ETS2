-- Migration: Add "Crossovers" department safely
BEGIN;

INSERT INTO public.department (department_id, name, code)
SELECT 6, 'Crossovers', 'CO'
WHERE NOT EXISTS (
    SELECT 1 FROM public.department WHERE department_id = 6 OR name = 'Crossovers'
);

COMMIT;

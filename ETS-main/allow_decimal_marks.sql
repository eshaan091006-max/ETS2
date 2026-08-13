-- Allow decimal marks for participations.
--
-- marks_scored and highest_marks were integer columns, so the app could only
-- ever award whole points. numeric keeps the existing values exactly (no
-- floating-point drift on sums) while accepting half-points like 8.5.
--
-- -1 remains the "not marked yet" sentinel in both columns.

ALTER TABLE participations
  ALTER COLUMN marks_scored TYPE numeric USING marks_scored::numeric;

ALTER TABLE events
  ALTER COLUMN highest_marks TYPE numeric USING highest_marks::numeric;

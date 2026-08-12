-- Migration: Update audit_logs trigger to include contingents and extra participation data
BEGIN;

-- 1️⃣ Create trigger function to log contingent changes
CREATE OR REPLACE FUNCTION log_contingent_changes()
RETURNS TRIGGER AS $$
DECLARE
  jwt_claims jsonb;
  user_identifier text;
BEGIN
  -- Get current JWT claims if available
  BEGIN
    jwt_claims := current_setting('request.jwt.claims', true)::jsonb;
  EXCEPTION WHEN OTHERS THEN
    jwt_claims := NULL;
  END;

  -- Identify the user who made the change
  user_identifier := coalesce(
    jwt_claims ->> 'username',
    jwt_claims ->> 'email',
    current_user
  );

  -- Insert audit log
  INSERT INTO public.audit_logs (
    table_name,
    action,
    record_id,
    old_data,
    new_data,
    changed_by
  ) VALUES (
    TG_TABLE_NAME,
    TG_OP,
    coalesce(NEW.contingent_id::text, OLD.contingent_id::text),
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN row_to_json(OLD)::jsonb ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW)::jsonb ELSE NULL END,
    user_identifier
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2️⃣ Attach trigger to contingents table
DROP TRIGGER IF EXISTS trg_log_contingent_changes ON public.contingents;
CREATE TRIGGER trg_log_contingent_changes
  AFTER INSERT OR UPDATE OR DELETE
  ON public.contingents
  FOR EACH ROW
  EXECUTE FUNCTION log_contingent_changes();

-- 3️⃣ Update participation trigger to include contingent_code and event_name in jsonb
CREATE OR REPLACE FUNCTION log_participation_changes()
RETURNS TRIGGER AS $$
DECLARE
  jwt_claims jsonb;
  user_identifier text;
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  -- Get current JWT claims if available
  BEGIN
    jwt_claims := current_setting('request.jwt.claims', true)::jsonb;
  EXCEPTION WHEN OTHERS THEN
    jwt_claims := NULL;
  END;

  -- Identify the user who made the change
  user_identifier := coalesce(
    jwt_claims ->> 'username',
    jwt_claims ->> 'email',
    current_user
  );

  -- Prepare OLD data with contingent code and event name
  IF TG_OP IN ('UPDATE', 'DELETE') THEN
    v_old_data := row_to_json(OLD)::jsonb || 
                  jsonb_build_object(
                    'contingent_code', (SELECT contingent_code FROM public.contingents WHERE contingent_id = OLD.contingent_id),
                    'event_name', (SELECT event_name FROM public.events WHERE event_id = OLD.event_id)
                  );
  ELSE
    v_old_data := NULL;
  END IF;

  -- Prepare NEW data with contingent code and event name
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    v_new_data := row_to_json(NEW)::jsonb || 
                  jsonb_build_object(
                    'contingent_code', (SELECT contingent_code FROM public.contingents WHERE contingent_id = NEW.contingent_id),
                    'event_name', (SELECT event_name FROM public.events WHERE event_id = NEW.event_id)
                  );
  ELSE
    v_new_data := NULL;
  END IF;

  -- Insert audit log
  INSERT INTO public.audit_logs (
    table_name,
    action,
    record_id,
    old_data,
    new_data,
    changed_by
  ) VALUES (
    TG_TABLE_NAME,
    TG_OP,
    coalesce(NEW.participation_id::text, OLD.participation_id::text),
    v_old_data,
    v_new_data,
    user_identifier
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- 1. Update public.is_admin() to exclude volunteer admins
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'user_role', 
    ''
  ) = 'admin' AND NOT coalesce(
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'is_volunteer')::boolean, 
    false
  );
END;
$$;

-- 2. Create is_admin_or_volunteer() helper function
CREATE OR REPLACE FUNCTION public.is_admin_or_volunteer()
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

-- 3. Update login_admin_rpc to include is_volunteer in signed JWT claims
CREATE OR REPLACE FUNCTION login_admin_rpc(input_username text, input_password text)
RETURNS TABLE (username text, is_volunteer boolean, token text) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    admin_record record;
    jwt_token text;
    jwt_secret_val text;
BEGIN
    SELECT * INTO admin_record 
    FROM public.admins 
    WHERE LOWER(admins.username) = LOWER(input_username) AND admins.password = input_password;

    IF FOUND THEN
        -- Try fetching from vault_settings table first, fallback to postgres setting
        BEGIN
            SELECT value INTO jwt_secret_val FROM public.vault_settings WHERE key = 'jwt_secret';
        EXCEPTION WHEN OTHERS THEN
            jwt_secret_val := NULL;
        END;

        IF jwt_secret_val IS NULL OR jwt_secret_val = '' THEN
            jwt_secret_val := coalesce(current_setting('app.settings.jwt_secret', true), '');
        END IF;

        SELECT sign(
            row_to_json(r), jwt_secret_val
        ) INTO jwt_token
        FROM (
            SELECT 
                'authenticated' as role,
                'admin' as user_role,
                input_username as username,
                admin_record.is_volunteer as is_volunteer,
                floor(extract(epoch from now() + interval '7 days'))::bigint as exp
        ) r;

        RETURN QUERY SELECT admin_record.username, admin_record.is_volunteer, jwt_token;
    END IF;
    RETURN;
END;
$$;

-- 4. Update Form Links SELECT policy to allow volunteer admins to view all form links
DROP POLICY IF EXISTS "Admins can view all form links" ON public.form_links;
CREATE POLICY "Admins can view all form links"
  ON public.form_links
  FOR SELECT
  TO authenticated
  USING (public.is_admin_or_volunteer());

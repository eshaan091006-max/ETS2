-- Run this SQL in your Supabase SQL Editor to make both Admin and Contingent logins case-insensitive

-- 1. Update Admin Login RPC to be case-insensitive on username
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
                floor(extract(epoch from now() + interval '7 days'))::bigint as exp
        ) r;

        RETURN QUERY SELECT admin_record.username, admin_record.is_volunteer, jwt_token;
    END IF;
    RETURN;
END;
$$;


-- 2. Update Contingent Login RPC to be case-insensitive on contingent_code
CREATE OR REPLACE FUNCTION login_contingent_rpc(input_code text, input_password text)
RETURNS TABLE (
    contingent_id int, 
    contingent_code text, 
    password text,
    reset_count int,
    token text
) 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
    cont_record record;
    jwt_token text;
    jwt_secret_val text;
BEGIN
    SELECT * INTO cont_record 
    FROM public.contingents 
    WHERE LOWER(contingents.contingent_code::text) = LOWER(input_code) AND contingents.password = input_password;

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
                'contingent' as user_role,
                cont_record.contingent_id as contingent_id,
                floor(extract(epoch from now() + interval '7 days'))::bigint as exp
        ) r;

        RETURN QUERY SELECT 
            cont_record.contingent_id::int, 
            cont_record.contingent_code::text, 
            cont_record.password::text, 
            cont_record.reset_count::int, 
            jwt_token;
    END IF;
    RETURN;
END;
$$;

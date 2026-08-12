    -- ====================================================================
    -- COMBINED MIGRATION: JWT Extensions, Tables, Functions, and Secret Setup
    -- ====================================================================
    --
    -- INSTRUCTIONS:
    -- 1. Run this ENTIRE script in your Supabase SQL Editor (https://supabase.com/dashboard)
    -- 2. If it runs successfully, log out of your app, clear site storage (F12 -> Clear Storage),
    --    refresh the page, and log back in.
    -- 3. If it fails, please copy and paste the EXACT error message you get.
    --
    -- ====================================================================

    -- 1. Enable extensions
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    CREATE EXTENSION IF NOT EXISTS pgjwt;

    -- Drop hmac functions to avoid return/signature changes conflict
    DROP FUNCTION IF EXISTS public.hmac(text, text, text);
    DROP FUNCTION IF EXISTS public.hmac(bytea, bytea, text);

    -- Create a wrapper for hmac in public schema to delegate to extensions.hmac
    CREATE OR REPLACE FUNCTION public.hmac(data text, key text, type text)
    RETURNS bytea
    LANGUAGE sql
    SECURITY DEFINER
    SET search_path = public, extensions
    AS $$
    SELECT extensions.hmac(data::bytea, key::bytea, type);
    $$;

    -- 2. Create the settings table and enable RLS (for security)
    CREATE TABLE IF NOT EXISTS public.vault_settings (
        key text PRIMARY KEY,
        value text NOT NULL
    );

    ALTER TABLE public.vault_settings ENABLE ROW LEVEL SECURITY;

    -- 3. Insert/Update the JWT secret key
    -- Make sure this secret is your project's JWT Secret from settings -> API
    INSERT INTO public.vault_settings (key, value)
    VALUES ('jwt_secret', 'fOj6g8+xlOUhpvX+qkAEKbu3F0ckS6IF7x60GkW0uvhAVfw5PmTsvIJDy855cxmpnTn8KK+aWStj31YnCRO4OQ==')
    ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

    -- 4. Recreate Admin Login RPC function
    DROP FUNCTION IF EXISTS login_admin_rpc(text, text);
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

    -- 5. Recreate Contingent Login RPC function
    DROP FUNCTION IF EXISTS login_contingent_rpc(text, text);
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

    -- 6. Setup Verification RPC Function
    CREATE OR REPLACE FUNCTION public.verify_jwt_secret_setup()
    RETURNS TABLE (
    status text,
    secret_configured boolean,
    secret_length int,
    message text
    ) 
    LANGUAGE plpgsql
    SECURITY DEFINER
    AS $$
    DECLARE
    configured_secret text;
    BEGIN
    SELECT value INTO configured_secret FROM public.vault_settings WHERE key = 'jwt_secret';
    
    IF configured_secret IS NULL OR configured_secret = '' THEN
        RETURN QUERY SELECT 
        'ERROR'::text, 
        false, 
        0, 
        'jwt_secret is not configured in public.vault_settings.'::text;
    ELSIF length(configured_secret) < 32 THEN
        RETURN QUERY SELECT 
        'WARNING'::text, 
        true, 
        length(configured_secret), 
        'Secret is configured but seems too short. Make sure it is your exact JWT secret from Supabase Dashboard.'::text;
    ELSE
        RETURN QUERY SELECT 
        'SUCCESS'::text, 
        true, 
        length(configured_secret), 
        'JWT secret is successfully configured in public.vault_settings!'::text;
    END IF;
    END;
    $$;

    -- Run verification
    SELECT * FROM public.verify_jwt_secret_setup();

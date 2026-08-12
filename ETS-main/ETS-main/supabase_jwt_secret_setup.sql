-- ====================================================================
-- MIGRATION: Set app settings and JWT secret in Supabase
-- ====================================================================
--
-- Why is this needed?
-- The custom login RPC functions (`login_admin_rpc` and `login_contingent_rpc`)
-- generate custom JWT tokens for role-based access. These tokens must be signed
-- with the project's actual Supabase JWT Secret so that Supabase's API Gateway
-- (PostgREST) can successfully verify and decode them.
--
-- On hosted Supabase databases, setting server-level parameters using ALTER DATABASE
-- is often blocked with a "permission denied" error.
-- To solve this, we create a secure configuration table (`public.vault_settings`) 
-- that stores your secret. Since the login functions run as SECURITY DEFINER,
-- they bypass Row Level Security (RLS) to read the secret privately and securely.
--
-- ====================================================================
-- STEP 1: Get your JWT Secret from the Supabase Dashboard
-- ====================================================================
-- 1. Go to your Supabase Project Dashboard (https://supabase.com/dashboard)
-- 2. Open Settings (gear icon in the sidebar) -> API
-- 3. Scroll down to JWT Settings and copy the "JWT Secret" (click reveal/copy).
--
-- ====================================================================
-- STEP 2: Configure your Database
-- ====================================================================
-- Replace the placeholder secret below with the secret you copied,
-- then run this entire block in the Supabase SQL Editor.

-- 1. Create the settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.vault_settings (
    key text PRIMARY KEY,
    value text NOT NULL
);

-- 2. Enable RLS so it is completely private and secure
ALTER TABLE public.vault_settings ENABLE ROW LEVEL SECURITY;

-- 3. Insert or update the JWT secret
-- Replace 'fOj6g8+xlOUhpvX+qkAEKbu3F0ckS6IF7x60GkW0uvhAVfw5PmTsvIJDy855cxmpnTn8KK+aWStj31YnCRO4OQ==' with your actual secret if needed.
INSERT INTO public.vault_settings (key, value)
VALUES ('jwt_secret', 'fOj6g8+xlOUhpvX+qkAEKbu3F0ckS6IF7x60GkW0uvhAVfw5PmTsvIJDy855cxmpnTn8KK+aWStj31YnCRO4OQ==')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;

-- ====================================================================
-- STEP 3: Verify the Setup
-- ====================================================================
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

-- Run verification immediately to check status
SELECT * FROM public.verify_jwt_secret_setup();

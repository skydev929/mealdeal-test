-- Add RPC functions for signup validation
-- These functions allow checking email/username existence without exposing user data

-- Function to check if email exists (returns boolean)
CREATE OR REPLACE FUNCTION public.check_email_exists(p_email TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles WHERE email = p_email
  );
END;
$$;

-- Function to check if username exists (returns boolean)
CREATE OR REPLACE FUNCTION public.check_username_exists(p_username TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM user_profiles WHERE username = p_username AND username IS NOT NULL
  );
END;
$$;

-- Grant execute permission to everyone (for signup validation)
GRANT EXECUTE ON FUNCTION public.check_email_exists TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_username_exists TO anon, authenticated;


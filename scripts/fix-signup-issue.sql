-- Quick fix for signup RLS issue
-- Run this in Supabase SQL Editor if signup is still failing

-- Option 1: Temporarily disable RLS (for testing only - not recommended for production)
-- ALTER TABLE user_profiles DISABLE ROW LEVEL SECURITY;

-- Option 2: Drop and recreate the insert policy with better conditions
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (
    -- Allow authenticated users to insert their own profile
    auth.uid() = id
  );

-- Option 3: Use SECURITY DEFINER function (recommended)
-- This function runs with the privileges of the function creator (bypasses RLS)
CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_user_id UUID,
  p_email TEXT,
  p_username TEXT DEFAULT NULL,
  p_plz TEXT DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO user_profiles (id, email, username, plz)
  VALUES (p_user_id, p_email, p_username, p_plz)
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = COALESCE(EXCLUDED.username, user_profiles.username),
    plz = COALESCE(EXCLUDED.plz, user_profiles.plz);
    
  INSERT INTO user_roles (user_id, role)
  VALUES (p_user_id, 'user')
  ON CONFLICT (user_id, role) DO NOTHING;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_user_profile TO authenticated;


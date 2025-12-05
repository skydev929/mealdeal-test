-- Create RPC function for user profile creation (bypasses RLS)
-- This function allows frontend to create/update user profiles with username and PLZ

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
    email = COALESCE(EXCLUDED.email, user_profiles.email),
    username = COALESCE(EXCLUDED.username, user_profiles.username),
    plz = COALESCE(EXCLUDED.plz, user_profiles.plz);
    
  INSERT INTO user_roles (user_id, role)
  VALUES (p_user_id, 'user')
  ON CONFLICT (user_id, role) DO NOTHING;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.create_user_profile TO authenticated;


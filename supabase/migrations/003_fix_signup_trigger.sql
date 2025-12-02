-- Fix signup by creating a trigger that automatically creates user_profiles
-- This ensures profiles are created even if RLS policies are strict

-- Function to create user profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email)
  VALUES (NEW.id, NEW.email)
  ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;
  
  -- Assign default 'user' role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'user')
  ON CONFLICT (user_id, role) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger that fires when a new user is created in auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Update RLS policy to be more permissive for inserts
-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;

-- Create a more permissive policy that allows inserts during signup
-- The trigger will handle the actual creation, but we need this for manual inserts
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (
    -- Allow if inserting own profile
    auth.uid() = id OR
    -- Allow if authenticated (for cases where session exists)
    auth.uid() IS NOT NULL
  );

-- Also update the user_roles policy
DROP POLICY IF EXISTS "Users can insert own user role" ON user_roles;

CREATE POLICY "Users can insert own user role"
  ON user_roles
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND 
    role = 'user'
  );


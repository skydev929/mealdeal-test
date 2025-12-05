-- Fix signup by creating a trigger that automatically creates user_profiles
-- This ensures profiles are created even if RLS policies are strict

-- Function to create user profile when auth user is created
-- Also saves username and PLZ from user metadata if provided
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_username TEXT;
  v_plz TEXT;
BEGIN
  -- Extract username and PLZ from metadata
  v_username := NEW.raw_user_meta_data->>'username';
  v_plz := NEW.raw_user_meta_data->>'plz';
  
  -- Check if username already exists (if provided)
  IF v_username IS NOT NULL AND LENGTH(TRIM(v_username)) > 0 THEN
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE username = v_username AND id != NEW.id) THEN
      -- Username already exists, set to NULL to avoid constraint violation
      v_username := NULL;
    END IF;
  END IF;
  
  -- Insert user profile
  INSERT INTO public.user_profiles (id, email, username, plz)
  VALUES (NEW.id, NEW.email, v_username, v_plz)
  ON CONFLICT (id) DO UPDATE SET 
    email = COALESCE(EXCLUDED.email, user_profiles.email),
    username = COALESCE(EXCLUDED.username, user_profiles.username),
    plz = COALESCE(EXCLUDED.plz, user_profiles.plz);
  
  -- Assign default 'user' role
  INSERT INTO public.user_roles (user_id, role)
  VALUES (NEW.id, 'user')
  ON CONFLICT (user_id, role) DO NOTHING;
  
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Handle unique constraint violations gracefully
    -- If username conflict, insert without username
    INSERT INTO public.user_profiles (id, email, plz)
    VALUES (NEW.id, NEW.email, v_plz)
    ON CONFLICT (id) DO UPDATE SET 
      email = COALESCE(EXCLUDED.email, user_profiles.email),
      plz = COALESCE(EXCLUDED.plz, user_profiles.plz);
    
    -- Still assign role
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


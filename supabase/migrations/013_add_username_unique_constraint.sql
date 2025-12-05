-- Add unique constraint to username column
-- This ensures usernames are unique across all users

-- First, handle any existing duplicate usernames (set to NULL)
-- This is safe because username is optional
UPDATE user_profiles 
SET username = NULL 
WHERE username IN (
  SELECT username 
  FROM user_profiles 
  WHERE username IS NOT NULL 
  GROUP BY username 
  HAVING COUNT(*) > 1
);

-- Add unique constraint to username
-- Only apply to non-null values (allows multiple NULLs)
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_profiles_username_unique 
ON user_profiles(username) 
WHERE username IS NOT NULL;

-- Add a check constraint to ensure username is not empty string if provided
ALTER TABLE user_profiles 
ADD CONSTRAINT check_username_not_empty 
CHECK (username IS NULL OR LENGTH(TRIM(username)) > 0);


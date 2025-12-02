-- Script to assign admin role to a user
-- Replace 'USER_EMAIL_HERE' with the actual email address of the user

-- Method 1: Assign admin role by email (recommended)
-- This will find the user by email and assign the admin role

INSERT INTO user_roles (user_id, role)
SELECT 
    up.id as user_id,
    'admin' as role
FROM user_profiles up
WHERE up.email = 'USER_EMAIL_HERE'  -- Replace with actual email
ON CONFLICT (user_id, role) DO NOTHING;

-- Verify the role was assigned
SELECT 
    up.id,
    up.email,
    ur.role,
    up.created_at
FROM user_profiles up
LEFT JOIN user_roles ur ON up.id = ur.user_id
WHERE up.email = 'USER_EMAIL_HERE';  -- Replace with actual email

-- Method 2: Assign admin role by user ID (if you know the UUID)
-- Uncomment and replace USER_ID_HERE with the actual UUID
/*
INSERT INTO user_roles (user_id, role)
VALUES ('USER_ID_HERE', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;
*/

-- Method 3: List all users with their roles (to find the user first)
-- Uncomment to see all users
/*
SELECT 
    up.id,
    up.email,
    up.username,
    up.plz,
    COALESCE(
        string_agg(ur.role, ', ' ORDER BY ur.role), 
        'no role'
    ) as roles,
    up.created_at
FROM user_profiles up
LEFT JOIN user_roles ur ON up.id = ur.user_id
GROUP BY up.id, up.email, up.username, up.plz, up.created_at
ORDER BY up.created_at DESC;
*/


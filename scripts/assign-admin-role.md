# How to Assign Admin Role to a User

## Method 1: Using Supabase Dashboard (Easiest)

1. **Go to Supabase Dashboard:**
   - Navigate to: https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr
   - Go to **SQL Editor** in the left sidebar

2. **Run this SQL query:**
   ```sql
   -- Replace 'your-email@example.com' with the actual user email
   INSERT INTO user_roles (user_id, role)
   SELECT 
       up.id as user_id,
       'admin' as role
   FROM user_profiles up
   WHERE up.email = 'your-email@example.com'
   ON CONFLICT (user_id, role) DO NOTHING;
   ```

3. **Verify the role was assigned:**
   ```sql
   SELECT 
       up.id,
       up.email,
       ur.role,
       up.created_at
   FROM user_profiles up
   LEFT JOIN user_roles ur ON up.id = ur.user_id
   WHERE up.email = 'your-email@example.com';
   ```

## Method 2: Find User First, Then Assign

If you don't know the email, first list all users:

```sql
SELECT 
    up.id,
    up.email,
    up.username,
    COALESCE(
        string_agg(ur.role, ', ' ORDER BY ur.role), 
        'no role'
    ) as roles,
    up.created_at
FROM user_profiles up
LEFT JOIN user_roles ur ON up.id = ur.user_id
GROUP BY up.id, up.email, up.username, up.created_at
ORDER BY up.created_at DESC;
```

Then use the email or ID from the results to assign the admin role.

## Method 3: Using User ID (UUID)

If you know the user's UUID:

```sql
INSERT INTO user_roles (user_id, role)
VALUES ('USER_UUID_HERE', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;
```

## Method 4: Using Supabase CLI (Advanced)

If you have direct database access:

```bash
# Connect to the database and run SQL
psql "postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres" -c "INSERT INTO user_roles (user_id, role) SELECT id, 'admin' FROM user_profiles WHERE email = 'your-email@example.com' ON CONFLICT DO NOTHING;"
```

## Important Notes

- The `user_id` in `user_roles` must match the `id` in `user_profiles`
- The `user_profiles.id` should match the `auth.users.id` (UUID from Supabase Auth)
- The `ON CONFLICT DO NOTHING` prevents errors if the role already exists
- A user can have multiple roles, but typically you'll want just 'admin' or 'user'

## Troubleshooting

If the user doesn't exist in `user_profiles`:
1. They need to sign in at least once to create a profile
2. Or manually create the profile first:

```sql
-- First, get the auth user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Then create the profile (replace USER_ID with the UUID from above)
INSERT INTO user_profiles (id, email)
VALUES ('USER_ID', 'your-email@example.com')
ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

-- Then assign the admin role
INSERT INTO user_roles (user_id, role)
VALUES ('USER_ID', 'admin')
ON CONFLICT (user_id, role) DO NOTHING;
```


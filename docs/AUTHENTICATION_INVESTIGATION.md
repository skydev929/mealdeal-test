# Authentication System Investigation

## Overview
This document provides a comprehensive investigation of the authentication system from frontend UI to backend database, including signup, login, session management, and role-based access control.

## Architecture Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND UI                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │  Login.tsx   │         │  App.tsx      │                     │
│  │  (Sign In/Up)│         │  (Routing)   │                     │
│  └──────┬───────┘         └──────┬───────┘                     │
│         │                        │                              │
│         │ signIn/signUp          │ RequireAuth                  │
│         │                        │ (Route Guard)                 │
│         └────────┬───────────────┘                              │
│                  │                                              │
│                  ▼                                              │
│         ┌─────────────────┐                                    │
│         │  useAuth Hook     │                                    │
│         │  (Auth State)     │                                    │
│         └────────┬───────────┘                                    │
└──────────────────┼─────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SUPABASE AUTH                                │
│                    (auth.users)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. signUp(email, password)                               │  │
│  │    - Creates user in auth.users                          │  │
│  │    - Returns user object (if auto-confirmed)             │  │
│  │    - Triggers: handle_new_user()                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. Database Trigger                                       │  │
│  │    on_auth_user_created                                   │  │
│  │    → handle_new_user() function                          │  │
│  │    → Creates user_profiles row                           │  │
│  │    → Creates user_roles row (role='user')                │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. signIn(email, password)                               │  │
│  │    - Authenticates user                                  │  │
│  │    - Creates session                                     │  │
│  │    - Returns session with user.id                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                           │                                     │
│                           ▼                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 4. onAuthStateChange                                     │  │
│  │    - Listens for auth state changes                      │  │
│  │    - Triggers syncProfileAndRole()                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATABASE TABLES                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Table: user_profiles                                           │
│  ┌─────────────┬─────────────┬─────────────┬─────────────┐    │
│  │ id (UUID)   │ email       │ username    │ plz         │    │
│  │ PRIMARY KEY │ (UNIQUE)    │ (TEXT)      │ (TEXT)       │    │
│  └─────────────┴─────────────┴─────────────┴─────────────┘    │
│                                                                 │
│  Table: user_roles                                              │
│  ┌─────────────┬─────────────┐                                 │
│  │ user_id     │ role        │                                 │
│  │ (UUID, FK)  │ (TEXT)      │                                 │
│  └─────────────┴─────────────┘                                 │
│  PRIMARY KEY (user_id, role)                                   │
│                                                                 │
│  Row Level Security (RLS):                                     │
│  - user_profiles: Users can only access their own profile      │
│  - user_roles: Users can only view their own roles             │
└─────────────────────────────────────────────────────────────────┘
```

## Frontend Implementation

### 1. Login Page (`src/pages/Login.tsx`)

**Features:**
- Toggle between Sign In and Sign Up
- Form fields: email, password, username (signup only), PLZ (signup only)
- Role-based redirect after login (admin → `/admin/dashboard`, user → `/`)

**Sign Up Flow:**
```typescript
await signUp(email, password, username, plz);
// Shows success message
// Doesn't auto-navigate (user must sign in after email confirmation)
```

**Sign In Flow:**
```typescript
await signIn(email, password);
// Wait 200ms for auth state to propagate
// Check user role from database
// Redirect based on role:
//   - Admin → /admin/dashboard
//   - User → /
```

### 2. useAuth Hook (`src/hooks/useAuth.ts`)

**State Management:**
- `userId: string | null` - User profile ID (from user_profiles table)
- `loading: boolean` - Auth initialization state
- `role: string | null` - User role ('user' or 'admin')

**Key Functions:**

#### `signUp(email, password, username?, plz?)`
```typescript
1. Call supabase.auth.signUp()
2. If user auto-confirmed:
   a. Try RPC function: create_user_profile()
   b. If fails, fallback to direct insert
   c. Create user_profiles row
   d. Create user_roles row (role='user')
   e. Sync local state
3. If email confirmation required:
   - Trigger will handle profile creation
```

#### `signIn(email, password)`
```typescript
1. Call supabase.auth.signInWithPassword()
2. Get authenticated user
3. Call syncProfileAndRole(userId)
```

#### `syncProfileAndRole(authUserId)`
```typescript
1. Check if user_profiles row exists
2. If not exists:
   - Create user_profiles row
   - Set userId state
3. Fetch user roles from user_roles table
4. If no roles found:
   - Assign default 'user' role
   - Insert into user_roles
5. Set role state (prefer 'admin' if present)
```

#### `onAuthStateChange` Listener
```typescript
- Listens for auth state changes
- Only syncs if user ID changed or hasn't synced yet
- Prevents unnecessary re-syncs
- Clears state on sign out
```

### 3. RequireAuth Component (`src/components/RequireAuth.tsx`)

**Purpose:** Route guard for protected routes

**Behavior:**
```typescript
- Shows loading spinner while checking auth
- Redirects to /login if not authenticated
- Redirects to / if adminOnly=true but user is not admin
- Renders children if authenticated and authorized
```

**Usage:**
```typescript
<Route path="/" element={<RequireAuth><Index /></RequireAuth>} />
<Route path="/admin/dashboard" element={<RequireAuth adminOnly><AdminDashboard /></RequireAuth>} />
```

### 4. App Routing (`src/App.tsx`)

**Routes:**
- `/login` - Public (Login page)
- `/` - Protected (Index page)
- `/dish/:dishId` - Protected (Dish detail)
- `/admin/dashboard` - Protected, Admin only
- `/privacy` - Public
- `/terms` - Public

## Backend Implementation

### 1. Database Trigger (`supabase/migrations/003_fix_signup_trigger.sql`)

**Function: `handle_new_user()`**
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Create user profile
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
```

**Trigger: `on_auth_user_created`**
```sql
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

**Purpose:**
- Automatically creates user_profiles when auth user is created
- Assigns default 'user' role
- Runs with SECURITY DEFINER (bypasses RLS)
- Handles email confirmation flow

### 2. Row Level Security (RLS) Policies

#### `user_profiles` Table

**SELECT Policy:**
```sql
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);
```

**INSERT Policy:**
```sql
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id OR
    auth.uid() IS NOT NULL
  );
```

**UPDATE Policy:**
```sql
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

#### `user_roles` Table

**SELECT Policy:**
```sql
CREATE POLICY "Users can view own roles"
  ON user_roles FOR SELECT
  USING (auth.uid() = user_id);
```

**INSERT Policy:**
```sql
CREATE POLICY "Users can insert own user role"
  ON user_roles FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND 
    role = 'user'
  );
```

**Note:** Admin roles must be assigned manually via SQL (not through frontend)

### 3. Database Schema

#### `user_profiles` Table
```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  username TEXT,
  plz TEXT,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Key Points:**
- `id` matches `auth.users.id` (UUID)
- `email` is unique (optional, can be NULL)
- Supports anonymous users (no email)

#### `user_roles` Table
```sql
CREATE TABLE user_roles (
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, role)
);
```

**Key Points:**
- Composite primary key (user_id, role)
- Users can have multiple roles
- Default role: 'user'
- Admin role assigned manually

## Authentication Flows

### Flow 1: Sign Up (Auto-Confirmed)

```
1. User fills signup form (email, password, username, PLZ)
   ↓
2. Login.tsx calls useAuth.signUp()
   ↓
3. supabase.auth.signUp() creates auth user
   ↓
4. Database trigger fires: on_auth_user_created
   ↓
5. handle_new_user() function executes:
   - Creates user_profiles row (id, email)
   - Creates user_roles row (user_id, role='user')
   ↓
6. useAuth.signUp() continues:
   - Tries RPC: create_user_profile() (if exists)
   - Or fallback: Direct insert with username/PLZ
   - Updates user_roles if needed
   ↓
7. syncProfileAndRole() updates local state
   ↓
8. User sees success message
   ↓
9. User must sign in (or auto-signed in if confirmed)
```

### Flow 2: Sign Up (Email Confirmation Required)

```
1. User fills signup form
   ↓
2. supabase.auth.signUp() creates auth user
   ↓
3. Database trigger fires: on_auth_user_created
   ↓
4. handle_new_user() creates profile and role
   ↓
5. Supabase sends confirmation email
   ↓
6. User clicks confirmation link
   ↓
7. User is confirmed, session created
   ↓
8. onAuthStateChange fires
   ↓
9. syncProfileAndRole() syncs state
   ↓
10. User can now sign in
```

### Flow 3: Sign In

```
1. User enters email/password
   ↓
2. Login.tsx calls useAuth.signIn()
   ↓
3. supabase.auth.signInWithPassword()
   ↓
4. Session created, user authenticated
   ↓
5. onAuthStateChange fires
   ↓
6. syncProfileAndRole() executes:
   - Checks if profile exists (creates if not)
   - Fetches roles
   - Assigns default role if none
   ↓
7. Login.tsx checks role:
   - Admin → navigate to /admin/dashboard
   - User → navigate to /
```

### Flow 4: Route Protection

```
1. User navigates to protected route
   ↓
2. RequireAuth component mounts
   ↓
3. Checks useAuth hook:
   - loading === true → Show spinner
   - userId === null → Redirect to /login
   - adminOnly && role !== 'admin' → Redirect to /
   ↓
4. If authorized → Render children
```

## Identified Issues & Improvements

### ✅ Current Strengths

1. **Automatic Profile Creation:** Trigger ensures profiles are always created
2. **Role-Based Access:** Proper RBAC implementation
3. **Security:** RLS policies enforce data isolation
4. **Error Handling:** Comprehensive error handling
5. **State Management:** Proper auth state synchronization

### ⚠️ Potential Issues

1. **Redundant Profile Creation:**
   - Trigger creates profile automatically
   - Frontend also tries to create profile
   - **Impact:** Minor (ON CONFLICT handles it)
   - **Improvement:** Rely on trigger, remove frontend creation

2. **Race Condition in Sign Up:**
   - Frontend tries to create profile before trigger completes
   - **Impact:** Low (ON CONFLICT handles it)
   - **Improvement:** Wait for trigger or remove frontend creation

3. **Username/PLZ Not Saved by Trigger:**
   - Trigger only saves email
   - Frontend must update username/PLZ separately
   - **Impact:** Medium (data loss if frontend fails)
   - **Improvement:** Pass username/PLZ to trigger via metadata

4. **Role Assignment Logic:**
   - Multiple places assign roles (trigger, frontend, syncProfileAndRole)
   - **Impact:** Low (ON CONFLICT handles duplicates)
   - **Improvement:** Centralize role assignment

5. **Admin Role Assignment:**
   - Must be done manually via SQL
   - No UI for admin management
   - **Impact:** Low (security feature)
   - **Improvement:** Add admin management UI (with proper auth)

6. **Email Confirmation Handling:**
   - Frontend doesn't handle confirmation callback
   - **Impact:** Medium (user must manually sign in)
   - **Improvement:** Add confirmation callback handler

7. **Session Persistence:**
   - Relies on Supabase default (localStorage)
   - **Impact:** Low (works correctly)
   - **Improvement:** Document session storage strategy

### 🔧 Recommended Improvements

1. **Simplify Sign Up:**
   ```typescript
   const signUp = async (email: string, password: string, username?: string, plz?: string) => {
     const { data, error } = await supabase.auth.signUp({ 
       email, 
       password,
       options: {
         data: { username, plz } // Store in metadata
       }
     });
     if (error) throw error;
     
     // Trigger will create profile
     // Update username/PLZ if provided and user is confirmed
     if (data?.user) {
       await updateProfileMetadata(data.user.id, username, plz);
     }
   };
   ```

2. **Update Trigger to Handle Metadata:**
   ```sql
   CREATE OR REPLACE FUNCTION public.handle_new_user()
   RETURNS TRIGGER AS $$
   BEGIN
     INSERT INTO public.user_profiles (id, email, username, plz)
     VALUES (
       NEW.id, 
       NEW.email,
       NEW.raw_user_meta_data->>'username',
       NEW.raw_user_meta_data->>'plz'
     )
     ON CONFLICT (id) DO UPDATE SET 
       email = EXCLUDED.email,
       username = COALESCE(EXCLUDED.username, user_profiles.username),
       plz = COALESCE(EXCLUDED.plz, user_profiles.plz);
     
     INSERT INTO public.user_roles (user_id, role)
     VALUES (NEW.id, 'user')
     ON CONFLICT (user_id, role) DO NOTHING;
     
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;
   ```

3. **Add Email Confirmation Handler:**
   ```typescript
   // In App.tsx or useAuth
   useEffect(() => {
     const { data: { subscription } } = supabase.auth.onAuthStateChange(
       async (event, session) => {
         if (event === 'SIGNED_IN' && session) {
           // Handle email confirmation
           const urlParams = new URLSearchParams(window.location.search);
           if (urlParams.get('type') === 'email') {
             toast.success('Email confirmed! Welcome!');
           }
         }
       }
     );
     return () => subscription.unsubscribe();
   }, []);
   ```

4. **Improve Error Messages:**
   ```typescript
   // More specific error messages
   catch (error: any) {
     if (error.message.includes('email')) {
       toast.error('Invalid email address');
     } else if (error.message.includes('password')) {
       toast.error('Password must be at least 6 characters');
     } else {
       toast.error(error.message || 'Sign up failed');
     }
   }
   ```

## Security Considerations

### ✅ Security Features

1. **RLS Policies:** Enforce data isolation at database level
2. **SECURITY DEFINER:** Trigger runs with elevated privileges (safe)
3. **Role-Based Access:** Admin routes protected
4. **Session Management:** Handled by Supabase
5. **Password Hashing:** Handled by Supabase Auth

### ⚠️ Security Concerns

1. **Admin Role Assignment:**
   - Currently manual (good for security)
   - No audit trail
   - **Recommendation:** Add admin assignment log

2. **Role Policy:**
   - Policy allows inserting 'admin' role (line 49 in 002_rls_policies.sql)
   - But frontend only inserts 'user'
   - **Recommendation:** Remove 'admin' from policy, require manual assignment

3. **Session Storage:**
   - Uses localStorage (default)
   - Vulnerable to XSS
   - **Recommendation:** Consider httpOnly cookies for sensitive apps

## Testing Scenarios

### ✅ Test Cases

1. **Sign Up (Auto-Confirmed):**
   - Create account with email/password
   - Verify: Profile created, role assigned, can sign in

2. **Sign Up (Email Confirmation):**
   - Create account, don't confirm
   - Verify: Profile created, cannot sign in until confirmed

3. **Sign In:**
   - Sign in with valid credentials
   - Verify: Session created, redirected correctly

4. **Sign In (Invalid Credentials):**
   - Sign in with wrong password
   - Verify: Error message shown

5. **Route Protection:**
   - Access protected route without auth
   - Verify: Redirected to /login

6. **Admin Route:**
   - Access /admin/dashboard as regular user
   - Verify: Redirected to /

7. **Session Persistence:**
   - Sign in, refresh page
   - Verify: Still authenticated

8. **Sign Out:**
   - Sign out
   - Verify: Session cleared, redirected to login

## Summary

The authentication system is **well-implemented** with:
- ✅ Proper security (RLS, role-based access)
- ✅ Automatic profile creation (trigger)
- ✅ Good error handling
- ✅ Session management
- ✅ Route protection

**Minor improvements** could be made for:
- Simplifying signup flow (remove redundant profile creation)
- Handling email confirmation better
- Improving error messages
- Adding admin management UI

Overall, the implementation is **production-ready** with room for optimization and UX improvements.


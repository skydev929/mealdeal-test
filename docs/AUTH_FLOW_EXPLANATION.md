# Authentication Flow & Token Relationship

## Current Implementation Overview

This document explains how the authentication system works, including the relationship between access tokens and refresh tokens.

## Token Types

### 1. Access Token (JWT)
- **Purpose:** Used for API requests to authenticate the user
- **Lifetime:** Short-lived (typically 1 hour)
- **Storage:** Stored in `sessionStorage` as part of the session object
- **Format:** JSON Web Token (JWT) containing user information
- **Usage:** Sent with every API request to Supabase

### 2. Refresh Token
- **Purpose:** Used to obtain new access tokens when they expire
- **Lifetime:** Long-lived (typically 30 days)
- **Storage:** Stored in `sessionStorage` alongside access token
- **Format:** Opaque token string
- **Usage:** Automatically used by Supabase to refresh expired access tokens

## Current Authentication Flow

### Configuration (`src/integrations/supabase/client.ts`)

```typescript
{
  auth: {
    storage: sessionStorage,        // Tokens stored in browser sessionStorage
    persistSession: true,            // Session persists across page reloads
    autoRefreshToken: true,          // Automatically refresh expired access tokens
    detectSessionInUrl: false,       // Don't auto-signin from URL params
  }
}
```

### Initial Page Load Flow (`src/hooks/useAuth.ts`)

```
1. Component Mounts
   ↓
2. useEffect Runs
   ↓
3. init() Function Starts
   ↓
4. STEP 1: getSession()
   - Reads from sessionStorage
   - Returns: { session: { access_token, refresh_token, user, ... } }
   - If access token expired → Supabase auto-refreshes using refresh token
   - If refresh token expired → Returns null session
   ↓
5. STEP 2: getUser() (if session exists)
   - Validates the access token is still valid
   - Ensures token hasn't been revoked
   - May trigger refresh if token is expired
   - Returns: { user: { id, email, ... } }
   ↓
6. STEP 3: Restore Session State
   - If valid session → Set userId, role, userProfile
   - If no session → Clear state
   ↓
7. STEP 4: Register onAuthStateChange Listener
   - Only registered AFTER session is restored
   - Prevents premature null events
   ↓
8. Loading Complete
   - setLoading(false)
   - User can now use the app
```

### Sign In Flow

```
1. User Enters Credentials
   ↓
2. signInWithPassword({ email, password })
   - Supabase validates credentials
   - Returns: { session: { access_token, refresh_token, user } }
   - Tokens stored in sessionStorage automatically
   ↓
3. getUser()
   - Validates the new session
   ↓
4. syncProfileAndRole()
   - Fetches user profile from database
   - Fetches user roles
   - Updates local state
   ↓
5. onAuthStateChange Fires
   - Event: 'SIGNED_IN'
   - Session already set, so no additional work needed
   ↓
6. User Logged In ✅
```

### Page Refresh Flow (Fixed)

```
1. Page Reloads
   ↓
2. init() Runs
   ↓
3. getSession() Reads from sessionStorage
   - Access token might be expired
   - Refresh token should still be valid (if within 30 days)
   ↓
4. Supabase Auto-Refresh (if needed)
   - If access token expired → Uses refresh token
   - Gets new access token from Supabase
   - Updates sessionStorage with new tokens
   - Returns refreshed session
   ↓
5. getUser() Validates
   - Confirms new access token is valid
   ↓
6. Session Restored
   - userId set from session
   - User stays logged in ✅
   ↓
7. onAuthStateChange Registered
   - Only after session is restored
   - Won't fire with null (already restored)
```

### Token Refresh Flow (Automatic)

```
1. Access Token Expires (after ~1 hour)
   ↓
2. Next API Request or getSession() Call
   ↓
3. Supabase Detects Expired Access Token
   ↓
4. Auto-Refresh Triggered (autoRefreshToken: true)
   - Uses refresh token from sessionStorage
   - Calls Supabase auth endpoint
   - Gets new access token
   ↓
5. New Tokens Stored
   - New access token stored in sessionStorage
   - Refresh token may be rotated (new one issued)
   - Session updated
   ↓
6. Request Continues
   - Original request retried with new token
   - User doesn't notice the refresh
```

### Sign Out Flow

```
1. User Clicks Sign Out
   ↓
2. signOut() Called
   - Supabase clears session
   - Removes tokens from sessionStorage
   - Invalidates refresh token on server
   ↓
3. onAuthStateChange Fires
   - Event: 'SIGNED_OUT'
   - Session is null
   ↓
4. State Cleared
   - userId = null
   - role = null
   - userProfile = null
   ↓
5. Redirect to Login
```

## Token Relationship

### How They Work Together

```
┌─────────────────────────────────────────────────┐
│           Authentication Session                │
├─────────────────────────────────────────────────┤
│  Access Token (1 hour)  →  Used for API calls  │
│  Refresh Token (30 days) →  Used to get new     │
│                            access tokens        │
└─────────────────────────────────────────────────┘

When Access Token Expires:
  Access Token (expired) + Refresh Token (valid)
  → Supabase auto-refreshes
  → New Access Token + (possibly new) Refresh Token
  → User stays logged in seamlessly

When Refresh Token Expires:
  Access Token (any state) + Refresh Token (expired)
  → No refresh possible
  → Session becomes null
  → User must sign in again
```

### Token Lifecycle

```
Sign In
  ↓
Access Token (1h) + Refresh Token (30d) created
  ↓
Access Token used for requests
  ↓
After 1 hour → Access Token expires
  ↓
Supabase auto-refreshes (using Refresh Token)
  ↓
New Access Token (1h) + (possibly new) Refresh Token (30d)
  ↓
Cycle continues...
  ↓
After 30 days → Refresh Token expires
  ↓
No refresh possible → User must sign in again
```

## Key Implementation Details

### 1. Session Storage
- **Location:** Browser `sessionStorage`
- **Key Format:** `sb-<project-ref>-auth-token`
- **Contains:** Full session object with both tokens
- **Persistence:** Survives page reloads, cleared on tab close

### 2. Auto-Refresh Mechanism
- **Trigger:** Automatic on any Supabase API call
- **Condition:** Access token expired but refresh token valid
- **Process:** Transparent to user (happens in background)
- **Result:** New access token, seamless experience

### 3. Session Restoration
- **Order:** `getSession()` → `getUser()` → restore state → register listener
- **Why:** Prevents race conditions with `onAuthStateChange`
- **Result:** Session properly restored from storage

### 4. Error Handling
- **Network Errors:** Don't clear session (might be temporary)
- **Invalid Token:** Clear session (token revoked)
- **Expired Token:** Let Supabase auto-refresh (handled automatically)

## Security Considerations

### Access Token
- ✅ Short-lived (1 hour) - limits exposure if compromised
- ✅ Automatically refreshed - no user interruption
- ✅ Validated on each request - ensures it's still valid

### Refresh Token
- ✅ Long-lived (30 days) - good user experience
- ✅ Stored securely in sessionStorage
- ✅ Invalidated on sign out - can't be reused
- ✅ Rotated on refresh - old tokens become invalid

### Session Storage
- ✅ Cleared on tab close - more secure than localStorage
- ✅ Not accessible to other tabs - isolation
- ✅ Survives page reloads - good UX

## Best Practices Followed

1. ✅ **getSession() before getUser()** - Restore first, validate second
2. ✅ **Register listeners after restoration** - Prevents race conditions
3. ✅ **Trust autoRefreshToken** - Let Supabase handle refresh
4. ✅ **Handle errors gracefully** - Don't clear on network errors
5. ✅ **Validate tokens** - Use getUser() to ensure validity
6. ✅ **Clear on sign out** - Proper cleanup

## Current Flow Summary

**On Page Load:**
1. Read session from sessionStorage (`getSession()`)
2. Validate token (`getUser()`)
3. Restore user state
4. Register auth state listener

**During Use:**
- Access token used for API requests
- Auto-refreshed when expired (transparent)
- User stays logged in seamlessly

**On Sign Out:**
- Tokens cleared from sessionStorage
- Refresh token invalidated on server
- State cleared locally


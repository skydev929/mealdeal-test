# Authentication Token Investigation

## Current Issue
- User logs in successfully → tokens stored in sessionStorage
- User refreshes page → gets logged out immediately
- Token exists in sessionStorage but not being read/restored properly
- **CRITICAL:** This happens even when access token is NOT expired (just logged in, immediate refresh)
- This means it's NOT a token expiration issue, but a session restoration issue

## Understanding Supabase Token System

### Token Types
1. **Access Token (JWT)**
   - Short-lived (typically 1 hour)
   - Used for API requests
   - Stored in sessionStorage as part of session

2. **Refresh Token**
   - Long-lived (typically 30 days)
   - Used to get new access tokens
   - Stored in sessionStorage alongside access token

### How Supabase Handles Tokens
- `autoRefreshToken: true` → Supabase automatically refreshes expired access tokens
- `persistSession: true` → Session persists in storage (sessionStorage in this case)
- `getSession()` → Reads session from storage, may trigger auto-refresh if needed
- `getUser()` → Validates current access token, may trigger refresh if expired

## Current Auth Flow Analysis

### On Page Load (useAuth.ts lines 24-94)

```typescript
1. getSession() → Reads from sessionStorage
2. If session exists:
   - Immediately calls getUser() to validate
   - If getUser() fails → signs out user
3. If no session → clears state
```

### Potential Issues Identified

#### Issue 1: SessionStorage Reading Order (CRITICAL)
**Problem:**
- `onAuthStateChange` listener is registered BEFORE `getSession()` completes
- When listener is registered, it fires immediately with current state
- At that moment, Supabase hasn't read from sessionStorage yet
- So it fires with `null` session, clearing state
- Then `getSession()` reads from storage, but state is already cleared

**Flow:**
```
Page Load → onAuthStateChange listener registered (line 132)
         → onAuthStateChange fires IMMEDIATELY with null (before storage read)
         → Sets userId = null, clears state
         → getSession() called (line 27, async)
         → getSession() reads from sessionStorage, gets valid session
         → getUser() called (line 34, validates token)
         → But userId already null from step 2, RequireAuth redirects
```

**Note:** `getUser()` after `getSession()` is CORRECT (best practice), but the issue is the order of operations.

#### Issue 2: onAuthStateChange Race Condition (Lines 132-184)
**Problem:**
- `onAuthStateChange` fires when session changes
- On page load, it might fire with `null` session BEFORE Supabase restores from storage
- This could clear userId before session is actually restored

**Flow:**
```
Page Load → onAuthStateChange fires with null session
         → Sets userId = null
         → getSession() restores session (but too late, userId already null)
         → RequireAuth sees userId = null → redirects to login
```

#### Issue 3: RequireAuth Dependency (RequireAuth.tsx)
**Problem:**
- `RequireAuth` checks `userId` immediately
- If `userId` is null (even temporarily), redirects to login
- Doesn't wait for session restoration to complete

## Root Cause Hypothesis

**Most Likely:** The combination of:
1. **`onAuthStateChange` firing with null session BEFORE `getSession()` completes**
   - On page load, `onAuthStateChange` fires immediately
   - It fires with `null` session before Supabase reads from sessionStorage
   - This clears `userId` before session restoration happens
   - `RequireAuth` sees `userId = null` and redirects

2. **Race condition between `init()` and `onAuthStateChange`**
   - `init()` calls `getSession()` (async)
   - `onAuthStateChange` listener fires synchronously on mount
   - Listener fires before `getSession()` completes
   - Listener sees no session yet → clears state

3. **Premature `getUser()` validation**
   - Even if session is restored, calling `getUser()` immediately might fail
   - This could be due to network issues or timing

**Key Insight:** Since this happens with FRESH tokens (just logged in), the issue is:
- NOT token expiration
- NOT refresh token logic
- BUT session restoration timing/race condition

## What Should Happen

### Correct Flow:
```
Page Load → getSession() (reads from sessionStorage)
         → If access token expired, Supabase auto-refreshes using refresh token
         → Session restored with new access token
         → getUser() succeeds
         → userId set
         → User stays logged in
```

### Current Broken Flow (Even with Fresh Tokens):
```
Page Load → onAuthStateChange listener registered
         → onAuthStateChange fires IMMEDIATELY with null session (before storage read)
         → Sets userId = null, clears state
         → getSession() starts (async, reads from sessionStorage)
         → getSession() completes with valid session
         → But userId already null, RequireAuth already redirected
         → OR: getSession() completes → getUser() called → fails for some reason
         → signOut() called → clears everything
```

### Why This Happens:
1. **onAuthStateChange fires synchronously** when listener is registered
2. At that moment, Supabase hasn't read from sessionStorage yet
3. So it fires with `null` session
4. This clears `userId` before `getSession()` can restore the session

## Key Observations

1. **Token Storage:** Tokens ARE in sessionStorage (confirmed by user)
2. **Token Reading:** `getSession()` should read them, but something breaks
3. **Not Expiration:** User just logged in, so tokens are fresh
4. **Timing Issue:** Likely a race condition between:
   - Session restoration
   - Token validation
   - Auth state change events

## Recommended Fixes (Following Best Practices)

### Best Practice: getSession() → getUser() Pattern
**Why:** This is the recommended Supabase pattern:
- `getSession()` reads from storage and may trigger auto-refresh
- `getUser()` validates the token and ensures it's still valid
- Calling `getUser()` after `getSession()` is correct and should be kept

### Fix 1: Fix Session Restoration Order (CRITICAL)
**Problem:** `onAuthStateChange` fires with `null` BEFORE `getSession()` reads from sessionStorage
**Root Cause:** When listener is registered, Supabase hasn't read from sessionStorage yet
**Solution:**
- Call `getSession()` FIRST and wait for it to complete
- Only AFTER `getSession()` completes, register `onAuthStateChange` listener
- This ensures session is restored from storage before listener can clear it

### Fix 2: Ignore Initial onAuthStateChange Null Event
**Problem:** Even after fixing order, `onAuthStateChange` might fire with null on registration
**Solution:**
- Track if initial session restoration is complete
- Ignore `onAuthStateChange` null events until after `getSession()` completes
- Use a flag: `initialSessionLoaded` to track this

### Fix 3: Keep getUser() After getSession() (Best Practice)
**Why Keep It:**
- `getUser()` validates the token is still valid
- It ensures the session hasn't been revoked
- It's a security best practice
- The issue is NOT `getUser()` - it's the timing/order

**Fix:**
- Keep `getUser()` after `getSession()` (this is correct)
- But only call it AFTER session is restored from storage
- Don't clear session if `getUser()` fails - let Supabase handle refresh

### Fix 4: Better Error Handling for getUser()
**Problem:** Currently clears session if `getUser()` fails
**Solution:**
- If `getUser()` fails, it might be a network issue or token refresh in progress
- Don't immediately sign out
- Trust Supabase's `autoRefreshToken` to handle it
- Only clear if there's a definitive error (not just a failure)

### Fix 5: Ensure Loading State Prevents Premature Redirects
**Problem:** `RequireAuth` redirects before session restoration completes
**Solution:**
- Keep `loading=true` until `getSession()` AND `getUser()` complete
- `RequireAuth` should wait for `loading=false` before checking `userId`
- This prevents premature redirects during restoration

## Questions to Answer

1. **What does `getSession()` return on page refresh?**
   - Does it return the session from storage? ✓ (User confirmed token is in sessionStorage)
   - Does it return null? (Need to check)

2. **When does `onAuthStateChange` fire?**
   - Does it fire with null session on init? ✓ (Most likely - this is the issue)
   - Does it fire after session is restored? (Need to check order)

3. **Is `getUser()` necessary?**
   - Or can we trust `getSession()` alone?
   - Does `getUser()` trigger refresh or just validate?
   - **With fresh tokens, `getUser()` shouldn't fail - so why does it?**

4. **What's the timing?**
   - Does `onAuthStateChange` fire BEFORE `getSession()` completes?
   - Is there a race between listener registration and session restoration?

## Additional Observations

### Why Fresh Tokens Still Fail:
- If token is fresh and valid, `getUser()` should succeed
- But user still gets logged out
- This confirms the problem is NOT `getUser()` failing
- But rather `onAuthStateChange` clearing state BEFORE `getSession()` reads from sessionStorage

### SessionStorage Reading Issue:
- Tokens ARE in sessionStorage (confirmed)
- `getSession()` SHOULD read them
- But `onAuthStateChange` fires before `getSession()` completes
- This is a timing/order issue, not a storage issue

### Best Practices to Follow:
1. ✅ Call `getSession()` first to restore from storage
2. ✅ Call `getUser()` after `getSession()` to validate (keep this)
3. ✅ Register `onAuthStateChange` AFTER initial session restoration
4. ✅ Ignore initial null events from `onAuthStateChange`
5. ✅ Trust Supabase's `autoRefreshToken` for token refresh

### The Real Issue (SessionStorage Reading):
The sequence is likely:
1. Component mounts
2. `useEffect` runs
3. `onAuthStateChange` listener registered → fires immediately with `null` (before storage read)
4. State cleared (`userId = null`)
5. `getSession()` called (async) → reads from sessionStorage
6. `getSession()` completes with valid session
7. `getUser()` called → validates token
8. But `userId` already null from step 4, so `RequireAuth` redirects

**Root Cause:** `onAuthStateChange` fires synchronously when registered, before Supabase reads from sessionStorage. At that moment, there's no session in memory, so it fires with `null`.

**Solution:** 
1. Call `getSession()` FIRST and wait for completion
2. THEN register `onAuthStateChange` listener
3. Use a flag to ignore initial null events
4. Keep `getUser()` after `getSession()` (best practice)


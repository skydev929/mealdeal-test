import { useEffect, useState, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';

export const useAuth = () => {
  const [userId, setUserId] = useState<string | null>(null); // profile id
  const [loading, setLoading] = useState(true);
  const [role, setRole] = useState<string | null>(null);
  const currentAuthUserIdRef = useRef<string | null>(null);
  const hasSyncedRef = useRef(false);

  useEffect(() => {
    let isMounted = true;

    const init = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();

        if (session?.user && isMounted) {
          currentAuthUserIdRef.current = session.user.id;
          await syncProfileAndRole(session.user.id);
          hasSyncedRef.current = true;
        }
      } catch (error) {
        console.error('useAuth init error', error);
      } finally {
        if (isMounted) {
          setLoading(false);
        }
      }
    };

    init();

    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (_event, session) => {
      if (!isMounted) return;

      // Only sync if the user ID actually changed or if we haven't synced yet
      const newAuthUserId = session?.user?.id || null;
      const authUserIdChanged = newAuthUserId !== currentAuthUserIdRef.current;
      const needsSync = authUserIdChanged || (newAuthUserId && !hasSyncedRef.current);

      if (session?.user) {
        currentAuthUserIdRef.current = session.user.id;
        
        // Only set loading and sync if we actually need to
        if (needsSync) {
          setLoading(true);
          try {
            await syncProfileAndRole(session.user.id);
            hasSyncedRef.current = true;
          } catch (error) {
            console.error('Error in auth state change:', error);
            if (isMounted) {
              setUserId(null);
              setRole(null);
            }
          } finally {
            if (isMounted) {
              setLoading(false);
            }
          }
        }
      } else {
        // No session -> clear state
        currentAuthUserIdRef.current = null;
        hasSyncedRef.current = false;
        if (isMounted) {
          setUserId(null);
          setRole(null);
          setLoading(false);
        }
      }
    });

    return () => {
      isMounted = false;
      subscription.unsubscribe();
    };
  }, []);

  const syncProfileAndRole = async (authUserId: string) => {
    try {
      // Ensure a user_profiles row exists with id = auth user id
      const { data: profile, error: selErr } = await supabase
        .from('user_profiles')
        .select('id, plz')
        .eq('id', authUserId)
        .single();

      if (!profile) {
        const { data: inserted, error: insertError } = await supabase
          .from('user_profiles')
          .insert({ id: authUserId, email: (await supabase.auth.getUser()).data.user?.email })
          .select()
          .single();

        if (insertError) {
          console.error('Error creating profile:', insertError);
          throw insertError;
        }

        if (inserted) {
          setUserId(inserted.id);
        }
      } else {
        setUserId(profile.id);
      }

      // Get roles for the profile
      const { data: roles, error: rolesError } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', authUserId);

      if (rolesError) {
        console.error('Error fetching roles:', rolesError);
        // Don't throw, just set default role
        setRole('user');
        return;
      }

      if (roles && roles.length > 0) {
        // Prefer admin if present
        const hasAdmin = roles.find((r: any) => r.role === 'admin');
        setRole(hasAdmin ? 'admin' : roles[0].role);
      } else {
        // If no role found, assign 'user' by default
        const { error: insertRoleError } = await supabase.from('user_roles').insert({ user_id: authUserId, role: 'user' });
        if (insertRoleError) {
          console.error('Error inserting default role:', insertRoleError);
        }
        setRole('user');
      }
    } catch (error) {
      console.error('syncProfileAndRole error', error);
      // Don't clear userId/role on error - keep existing state
      // The error will be handled by the caller
      throw error;
    }
  };

  const signIn = async (email: string, password: string) => {
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;

    const authUser = (await supabase.auth.getUser()).data.user;
    if (authUser) {
      await syncProfileAndRole(authUser.id);
    }
  };

  const signUp = async (email: string, password: string, username?: string, plz?: string) => {
    // Use Supabase signUp with metadata to pass username and PLZ
    // The trigger will automatically create the profile with this metadata
    const { data, error } = await supabase.auth.signUp({ 
      email, 
      password,
      options: {
        data: {
          username: username || null,
          plz: plz || null,
        }
      }
    });
    
    // Handle Supabase auth errors with user-friendly messages
    if (error) {
      const errorMsg = error.message?.toLowerCase() || '';
      
      // Email already exists
      if (errorMsg.includes('already registered') || 
          errorMsg.includes('already exists') || 
          errorMsg.includes('user already registered') ||
          error.code === 'signup_disabled') {
        throw new Error('This email address is already registered. Please sign in instead or use a different email address.');
      }
      
      // Invalid email format
      if (errorMsg.includes('invalid email') || errorMsg.includes('email format')) {
        throw new Error('Please enter a valid email address (e.g., yourname@example.com).');
      }
      
      // Password too short
      if (errorMsg.includes('password') && (errorMsg.includes('short') || errorMsg.includes('length'))) {
        throw new Error('Password must be at least 6 characters long. Please choose a stronger password.');
      }
      
      // Weak password
      if (errorMsg.includes('weak password') || errorMsg.includes('password is too weak')) {
        throw new Error('Password is too weak. Please choose a stronger password with at least 6 characters.');
      }
      
      // Generic error with helpful message
      throw new Error(error.message || 'Failed to create account. Please check your information and try again.');
    }

    // The trigger handle_new_user() will automatically:
    // 1. Create user_profiles row with email, username, and PLZ from metadata
    // 2. Create user_roles row with 'user' role
    // No need to manually create/update profile - trigger handles it all

    // If a user object is returned (auto-confirmed), sync local state
    const createdUser = data?.user;
    if (createdUser) {
      // Wait a moment for trigger to complete
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Sync local state (profile should already exist from trigger)
      try {
        await syncProfileAndRole(createdUser.id);
      } catch (err) {
        console.error('Error syncing profile after signUp:', err);
        // Not fatal - trigger created profile, state will sync on next auth change
      }
    } else {
      // Email confirmation required - profile will be created when user confirms email
      // The trigger will handle profile creation automatically with metadata
    }

    return data;
  };

  const signOut = async () => {
    await supabase.auth.signOut();
    setUserId(null);
    setRole(null);
  };

  const updatePLZ = async (plz: string) => {
    if (!userId) return;
    const { error } = await supabase
      .from('user_profiles')
      .update({ plz })
      .eq('id', userId);
    if (error) throw error;
  };

  return { userId, loading, role, signIn, signUp, signOut, updatePLZ } as const;
};

export default useAuth;

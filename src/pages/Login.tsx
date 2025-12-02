import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import useAuth from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { toast } from 'sonner';
import { Loader2 } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [plz, setPlz] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSignUp, setIsSignUp] = useState(false);
  const { signIn, signUp } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    try {
      if (isSignUp) {
        await signUp(email, password, username, plz);
        toast.success('Account created. If your account requires confirmation, please verify your email before signing in.');
        setIsSignUp(false);
        // after signup, don't auto-navigate; user should sign in (or confirm email)
        return;
      }

      await signIn(email, password);
      
      // Wait a moment for auth state to propagate
      await new Promise(resolve => setTimeout(resolve, 200));
      
      // Check role directly from database after sign in
      const { data: { session } } = await supabase.auth.getSession();
      
      if (!session?.user) {
        toast.success('Signed in');
        navigate('/');
        return;
      }
      
      // Get the role from user_roles table
      const { data: roles, error: roleError } = await supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', session.user.id);
      
      if (roleError) {
        console.error('Error fetching user role:', roleError);
        toast.success('Signed in');
        navigate('/');
        return;
      }
      
      // Check if user has admin role
      const isAdmin = roles?.some((r: any) => r.role === 'admin') || false;
      
      console.log('Login - User roles:', roles, 'Is Admin:', isAdmin);
      
      if (isAdmin) {
        toast.success('Welcome back, admin!');
        navigate('/admin/dashboard');
      } else {
        toast.success('Signed in');
        navigate('/');
      }
    } catch (error: any) {
      toast.error(error.message || 'Sign in failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-background to-muted p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl text-center">Sign In</CardTitle>
          <CardDescription className="text-center">Sign in to access MealDeal features</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            {isSignUp && (
              <div className="space-y-2">
                <Label htmlFor="username">Username</Label>
                <Input id="username" type="text" placeholder="Your name" value={username} onChange={(e) => setUsername(e.target.value)} disabled={isLoading} />
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input id="email" type="email" placeholder="you@domain.com" value={email} onChange={(e) => setEmail(e.target.value)} required disabled={isLoading} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input id="password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required disabled={isLoading} />
            </div>

            {isSignUp && (
              <div className="space-y-2">
                <Label htmlFor="plz">PLZ</Label>
                <Input id="plz" type="text" value={plz} onChange={(e) => setPlz(e.target.value)} disabled={isLoading} />
              </div>
            )}
            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {isSignUp ? 'Sign Up' : 'Sign In'}
            </Button>

            <div className="text-center mt-2">
              <button type="button" className="text-sm text-primary underline" onClick={() => setIsSignUp(!isSignUp)}>
                {isSignUp ? 'Have an account? Sign in' : "Don't have an account? Sign up"}
              </button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}

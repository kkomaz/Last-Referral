import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Link as LinkIcon } from 'lucide-react';
import { supabase } from '../lib/supabase';
import UsernameRegistration from '../components/UsernameRegistration';

const Register: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [userId, setUserId] = useState<string | null>(null);
  const navigate = useNavigate();

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Create user in Supabase Auth
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
      });

      if (error) {
        setError(error.message);
        return;
      }

      if (data.user) {
        // Create a profile for the user
        const { error: profileError } = await supabase.from('profiles').insert({
          id: data.user.id,
          username: '', // Will be set during username registration
          bio: 'Tech enthusiast sharing my favorite products and services.',
          avatar_url:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80',
        });

        if (profileError) {
          console.error('Error creating profile:', profileError);
          setError('Failed to create user profile. Please try again.');
          return;
        }

        // Set the user ID for username registration
        setUserId(data.user.id);
      }
    } catch (err) {
      setError('An unexpected error occurred');
      console.error('Registration error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleUsernameComplete = (username: string) => {
    // Redirect to dashboard after username is set
    navigate('/admin');
  };

  // If we have a user ID but no username yet, show the username registration form
  if (userId) {
    return (
      <div className="min-h-screen flex flex-col bg-[#f7f9fb]">
        <header className="bg-white border-b border-gray-200 py-4">
          <div className="container mx-auto px-4 flex items-center">
            <Link to="/" className="flex items-center gap-2">
              <LinkIcon size={24} className="text-[#7b68ee]" />
              <span className="text-xl font-bold text-[#2b2d42]">EasyRef</span>
            </Link>
          </div>
        </header>

        <div className="flex-grow flex items-center justify-center p-4">
          <UsernameRegistration
            onComplete={handleUsernameComplete}
            standalone={false}
          />
        </div>

        <footer className="mt-auto py-6 bg-white border-t border-gray-200">
          <div className="container mx-auto px-4 text-center text-gray-500">
            <p>© {new Date().getFullYear()} EasyRef. All rights reserved.</p>
          </div>
        </footer>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col bg-[#f7f9fb]">
      <header className="bg-white border-b border-gray-200 py-4">
        <div className="container mx-auto px-4 flex items-center">
          <Link to="/" className="flex items-center gap-2">
            <LinkIcon size={24} className="text-[#7b68ee]" />
            <span className="text-xl font-bold text-[#2b2d42]">EasyRef</span>
          </Link>
        </div>
      </header>

      <div className="flex-grow flex items-center justify-center p-4">
        <div className="bg-white p-8 rounded-lg shadow-md max-w-md w-full">
          <h1 className="text-2xl font-bold text-center text-[#2b2d42] mb-6">
            Create Your EasyRef
          </h1>

          <p className="text-gray-600 text-center mb-8">
            Join thousands of creators sharing their favorite products and
            earning rewards.
          </p>

          {error && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-md text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleRegister}>
            <div className="mb-4">
              <label
                htmlFor="email"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Email
              </label>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full p-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-300"
                placeholder="Enter your email"
                required
              />
            </div>

            <div className="mb-6">
              <label
                htmlFor="password"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Password
              </label>
              <input
                type="password"
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full p-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-300"
                placeholder="Choose a password (min. 6 characters)"
                minLength={6}
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className={`w-full py-3 bg-[#7b68ee] hover:bg-[#6a5acd] text-white rounded-md font-medium transition-colors ${
                loading ? 'opacity-70 cursor-not-allowed' : ''
              }`}
            >
              {loading ? 'Creating account...' : 'Create Account'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-600">
              Already have an account?{' '}
              <Link to="/login" className="text-[#7b68ee] hover:underline">
                Sign in
              </Link>
            </p>
          </div>

          <div className="mt-6 text-center">
            <p className="text-sm text-gray-500">
              By signing up, you agree to our{' '}
              <a href="/terms" className="text-[#7b68ee] hover:underline">
                Terms of Service
              </a>{' '}
              and{' '}
              <a href="/privacy" className="text-[#7b68ee] hover:underline">
                Privacy Policy
              </a>
            </p>
          </div>
        </div>
      </div>

      <footer className="mt-auto py-6 bg-white border-t border-gray-200">
        <div className="container mx-auto px-4 text-center text-gray-500">
          <p>© {new Date().getFullYear()} EasyRef. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Register;

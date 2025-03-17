import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { usePrivy } from '@privy-io/react-auth';
import { Link as LinkIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import ThemeToggle from './ThemeToggle';

interface UsernameRegistrationProps {
  onComplete: (username: string) => void;
  standalone?: boolean;
}

const UsernameRegistration: React.FC<UsernameRegistrationProps> = ({
  onComplete,
  standalone = true,
}) => {
  const { user, ready } = usePrivy();
  const [username, setUsername] = useState('');
  const [isAvailable, setIsAvailable] = useState<boolean | null>(null);
  const [isChecking, setIsChecking] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  // Check username availability when input changes
  useEffect(() => {
    const checkUsername = async () => {
      if (!username || username.length < 3) {
        setIsAvailable(null);
        return;
      }

      setIsChecking(true);
      setError('');

      try {
        // Check if username follows the pattern (alphanumeric and underscores only)
        const usernamePattern = /^[a-zA-Z0-9_]+$/;
        if (!usernamePattern.test(username)) {
          setIsAvailable(false);
          setError(
            'Username can only contain letters, numbers, and underscores'
          );
          setIsChecking(false);
          return;
        }

        // Check if username already exists in the database
        const { data, error } = await supabase
          .from('profiles')
          .select('username')
          .eq('username', username.toLowerCase())
          .maybeSingle();

        if (error) {
          console.error('Error checking username:', error);
          setError('Error checking username availability');
          setIsAvailable(null);
        } else {
          setIsAvailable(!data);
          if (data) {
            setError('Username is already taken');
          }
        }
      } catch (err) {
        console.error('Error in checkUsername:', err);
        setError('An unexpected error occurred');
        setIsAvailable(null);
      } finally {
        setIsChecking(false);
      }
    };

    const debounceTimer = setTimeout(checkUsername, 500);
    return () => clearTimeout(debounceTimer);
  }, [username]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!isAvailable || isChecking || !user || !ready) {
      return;
    }

    setLoading(true);
    setError('');

    try {
      // Create new profile with username
      const { data: newProfile, error: insertError } = await supabase
        .from('profiles')
        .insert({
          privy_id: user.id,
          username: username.toLowerCase(),
          bio: 'Tech enthusiast sharing my favorite products and services.',
        })
        .select()
        .single();

      if (insertError) {
        console.error('Error creating profile:', insertError);
        setError('Failed to create profile. Please try again.');
        return;
      }

      // Fetch the complete profile data to ensure we have all fields
      const { data: fullProfile, error: fetchError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', newProfile.id)
        .single();

      if (fetchError) {
        console.error('Error fetching complete profile:', fetchError);
        setError('Failed to fetch complete profile. Please try again.');
        return;
      }

      // Transform the profile data to match UserProfile interface
      const userProfile = {
        id: fullProfile.id,
        username: fullProfile.username || '',
        bio:
          fullProfile.bio ||
          'Tech enthusiast sharing my favorite products and services.',
        avatarUrl: fullProfile.avatar_url || '',
        socialLinks: {
          twitter: fullProfile.twitter || '',
          instagram: fullProfile.instagram || '',
          linkedin: fullProfile.linkedin || '',
          website: fullProfile.website || '',
        },
      };

      // Update the global state through the callback
      onComplete(username.toLowerCase());

      // Force a refresh of the Supabase client
      await supabase.auth.refreshSession();
    } catch (err) {
      console.error('Error in handleSubmit:', err);
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  if (!ready) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-primary-light dark:border-primary-dark border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-muted-light dark:text-muted-dark">Loading...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
        <div className="text-center">
          <p className="text-muted-light dark:text-muted-dark mb-4">
            You need to be logged in to set a username.
          </p>
          <Link
            to="/login"
            className="px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors"
          >
            Go to Login
          </Link>
        </div>
      </div>
    );
  }

  const formContent = (
    <div className="bg-card-light dark:bg-card-dark p-8 rounded-lg shadow-md max-w-md w-full">
      <h2 className="text-2xl font-bold text-text-light dark:text-text-dark mb-6">
        Choose Your Username
      </h2>
      <p className="text-muted-light dark:text-muted-dark mb-6">
        This will be your unique URL:{' '}
        <span className="font-medium">
          easyref.com/{username || 'username'}
        </span>
        <br />
        <span className="text-sm text-red-500 dark:text-red-400 font-medium">
          Note: You cannot change your username later!
        </span>
      </p>

      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label
            htmlFor="username"
            className="block text-sm font-medium text-text-light dark:text-text-dark mb-1"
          >
            Username
          </label>
          <input
            type="text"
            id="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className={`w-full p-3 border rounded-md focus:outline-none focus:ring-2 bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark ${
              isAvailable === true
                ? 'border-green-300 dark:border-green-600 focus:ring-green-300 dark:focus:ring-green-600'
                : isAvailable === false
                ? 'border-red-300 dark:border-red-600 focus:ring-red-300 dark:focus:ring-red-600'
                : 'border-border-light dark:border-border-dark focus:ring-primary-light dark:focus:ring-primary-dark'
            }`}
            placeholder="Enter a unique username"
            minLength={3}
            maxLength={30}
            required
          />

          {isChecking && (
            <p className="mt-1 text-sm text-muted-light dark:text-muted-dark">
              Checking availability...
            </p>
          )}

          {isAvailable === true && !isChecking && (
            <p className="mt-1 text-sm text-green-600 dark:text-green-400">
              Username is available!
            </p>
          )}

          {error && (
            <p className="mt-1 text-sm text-red-600 dark:text-red-400">
              {error}
            </p>
          )}

          <p className="mt-2 text-xs text-muted-light dark:text-muted-dark">
            Username must be at least 3 characters and can only contain letters,
            numbers, and underscores.
          </p>
        </div>

        <button
          type="submit"
          disabled={!isAvailable || isChecking || loading}
          className={`w-full py-3 rounded-md font-medium transition-colors ${
            isAvailable && !isChecking && !loading
              ? 'bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white'
              : 'bg-gray-200 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
          }`}
        >
          {loading ? 'Saving...' : 'Claim Username'}
        </button>
      </form>
    </div>
  );

  if (!standalone) {
    return formContent;
  }

  return (
    <div className="min-h-screen flex flex-col bg-background-light dark:bg-background-dark">
      <header className="bg-card-light dark:bg-card-dark border-b border-border-light dark:border-border-dark py-4">
        <div className="container mx-auto px-4 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2">
            <LinkIcon
              size={24}
              className="text-primary-light dark:text-primary-dark"
            />
            <span className="text-xl font-bold text-text-light dark:text-text-dark">
              EasyRef
            </span>
          </Link>
          <ThemeToggle />
        </div>
      </header>

      <div className="flex-grow flex items-center justify-center p-4">
        {formContent}
      </div>
    </div>
  );
};

export default UsernameRegistration;

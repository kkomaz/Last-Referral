import React, { useState, useEffect } from 'react';
import { usePrivy } from '@privy-io/react-auth';
import { Link as LinkIcon, ArrowRight, ArrowLeft } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import ThemeToggle from './ThemeToggle';

const PrivyAuth: React.FC = () => {
  const { login, authenticated, ready } = usePrivy();
  const navigate = useNavigate();
  const [accessCode, setAccessCode] = useState('');
  const [isAccessCodeValid, setIsAccessCodeValid] = useState(false);

  useEffect(() => {
    if (ready && authenticated) {
      navigate('/admin');
    }
  }, [ready, authenticated, navigate]);

  const handleAccessCodeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const code = e.target.value;
    setAccessCode(code);
    setIsAccessCodeValid(code === 'referralfriends');
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

  if (authenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-primary-light dark:border-primary-dark border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
          <p className="text-muted-light dark:text-muted-dark">
            You're authenticated! Redirecting...
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex flex-col md:flex-row bg-background-light dark:bg-background-dark">
      {/* Left side - Sign in form */}
      <div className="w-full md:w-[480px] flex flex-col">
        <header className="bg-card-light dark:bg-card-dark border-b border-border-light dark:border-border-dark py-4 px-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => navigate('/')}
                className="p-2 hover:bg-background-light dark:hover:bg-background-dark rounded-md transition-colors"
                aria-label="Go back"
              >
                <ArrowLeft
                  size={20}
                  className="text-text-light dark:text-text-dark"
                />
              </button>
              <Link to="/" className="flex items-center gap-2">
                <LinkIcon
                  size={24}
                  className="text-primary-light dark:text-primary-dark"
                />
                <span className="text-xl font-bold text-text-light dark:text-text-dark">
                  EasyRef
                </span>
              </Link>
            </div>
            <ThemeToggle />
          </div>
        </header>

        <div className="flex-grow flex flex-col justify-center px-6 py-12">
          <div className="max-w-sm mx-auto w-full">
            <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-3">
              Welcome back
            </h1>
            <p className="text-muted-light dark:text-muted-dark mb-8">
              Sign in to manage your referral links and track your rewards.
            </p>

            <input
              type="text"
              value={accessCode}
              onChange={handleAccessCodeChange}
              placeholder="Enter access code"
              className="w-full mb-4 p-3 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-300"
            />

            <button
              onClick={() => login()}
              disabled={!isAccessCodeValid}
              className={`w-full py-3 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md font-medium transition-colors flex items-center justify-center gap-2 ${
                !isAccessCodeValid ? 'opacity-50 cursor-not-allowed' : ''
              }`}
            >
              <span>Sign In / Sign Up</span>
              <ArrowRight size={18} />
            </button>

            <div className="mt-6">
              <p className="text-sm text-muted-light dark:text-muted-dark">
                By signing in, you agree to our{' '}
                <a
                  href="/terms"
                  className="text-primary-light dark:text-primary-dark hover:underline"
                >
                  Terms of Service
                </a>{' '}
                and{' '}
                <a
                  href="/privacy"
                  className="text-primary-light dark:text-primary-dark hover:underline"
                >
                  Privacy Policy
                </a>
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Right side - Illustration/Content */}
      <div className="hidden md:flex flex-1 bg-card-light dark:bg-card-dark border-l border-border-light dark:border-border-dark">
        <div className="w-full max-w-4xl mx-auto px-16 py-20 flex flex-col">
          {/* Hero Section */}
          <div className="text-center mb-16">
            <h2 className="text-5xl font-bold text-text-light dark:text-text-dark mb-6">
              Share. Connect.{' '}
              <span className="text-primary-light dark:text-primary-dark">
                Earn.
              </span>
            </h2>
            <p className="text-xl text-muted-light dark:text-muted-dark max-w-2xl mx-auto">
              Join thousands of creators sharing their favorite products and
              earning rewards through EasyRef.
            </p>
          </div>

          {/* Main Image */}
          <div className="relative w-full aspect-[16/9] mb-16">
            <img
              src="https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=2400&q=80"
              alt="Dashboard Preview"
              className="w-full h-full object-cover rounded-2xl shadow-2xl"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-card-light/10 dark:from-card-dark/10 to-transparent rounded-2xl"></div>
          </div>

          {/* Features Grid */}
          <div className="grid grid-cols-3 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 rounded-2xl bg-primary-light/10 dark:bg-primary-dark/10 flex items-center justify-center mx-auto mb-4">
                <LinkIcon
                  size={28}
                  className="text-primary-light dark:text-primary-dark"
                />
              </div>
              <h3 className="text-lg font-semibold text-text-light dark:text-text-dark mb-2">
                Organize Links
              </h3>
              <p className="text-sm text-muted-light dark:text-muted-dark">
                Keep all your referral links organized and easy to share from
                one place.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 rounded-2xl bg-primary-light/10 dark:bg-primary-dark/10 flex items-center justify-center mx-auto mb-4">
                <svg
                  className="w-7 h-7 text-primary-light dark:text-primary-dark"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
                  />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-text-light dark:text-text-dark mb-2">
                Track Analytics
              </h3>
              <p className="text-sm text-muted-light dark:text-muted-dark">
                Monitor your performance with detailed analytics and insights.
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 rounded-2xl bg-primary-light/10 dark:bg-primary-dark/10 flex items-center justify-center mx-auto mb-4">
                <svg
                  className="w-7 h-7 text-primary-light dark:text-primary-dark"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-text-light dark:text-text-dark mb-2">
                Maximize Earnings
              </h3>
              <p className="text-sm text-muted-light dark:text-muted-dark">
                Optimize your strategy with data-driven insights.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PrivyAuth;

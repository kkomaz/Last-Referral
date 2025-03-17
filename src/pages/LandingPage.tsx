import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Link as LinkIcon, ArrowRight } from 'lucide-react';
import ThemeToggle from '../components/ThemeToggle';

const LandingPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (email) {
      // Here you would typically send this to your backend
      console.log('Email submitted:', email);
      setSubmitted(true);
      setEmail('');
    }
  };

  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="bg-card-light/80 dark:bg-card-dark/80 backdrop-blur-sm border-b border-border-light dark:border-border-dark">
        <div className="max-w-7xl mx-auto px-4 py-3">
          <div className="flex justify-between items-center">
            <Link to="/" className="flex items-center gap-2">
              <LinkIcon
                size={24}
                className="text-primary-light dark:text-primary-dark"
              />
              <span className="text-xl font-bold text-text-light dark:text-text-dark">
                ReferralTree
              </span>
            </Link>
            <div className="flex items-center gap-4">
              <ThemeToggle />
              <Link
                to="/login"
                className="px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors"
              >
                Early Access
              </Link>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-grow flex items-center justify-center px-4 py-16 md:py-24 bg-gradient-to-br from-primary-light/5 via-background-light to-secondary-light/5 dark:from-primary-dark/10 dark:via-background-dark dark:to-secondary-dark/10">
        <div className="w-full max-w-3xl mx-auto text-center">
          <div className="relative mb-12">
            <div className="absolute -inset-1 bg-gradient-to-r from-primary-light via-primary-light/50 to-secondary-light dark:from-primary-dark dark:via-primary-dark/50 dark:to-secondary-dark rounded-lg blur opacity-20"></div>
            <h1 className="relative text-4xl md:text-6xl lg:text-7xl font-bold text-text-light dark:text-text-dark mb-8">
              The Future of{' '}
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary-light to-secondary-light dark:from-primary-dark dark:to-secondary-dark">
                Referral Marketing
              </span>
            </h1>
          </div>

          <div className="relative max-w-xl mx-auto">
            {submitted ? (
              <div className="bg-green-50/80 dark:bg-green-900/20 backdrop-blur-sm text-green-600 dark:text-green-400 px-6 py-4 rounded-lg mb-8">
                Thanks for your interest! We'll keep you updated on our
                progress.
              </div>
            ) : (
              <></>
              // <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-3 mb-8">
              //   <input
              //     type="email"
              //     value={email}
              //     onChange={(e) => setEmail(e.target.value)}
              //     placeholder="Enter your email"
              //     className="flex-1 px-4 py-3 rounded-lg border border-border-light dark:border-border-dark bg-card-light/80 dark:bg-card-dark/80 backdrop-blur-sm text-text-light dark:text-text-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark"
              //     required
              //   />
              //   <button
              //     type="submit"
              //     className="px-6 py-3 bg-gradient-to-r from-primary-light to-primary-light/90 dark:from-primary-dark dark:to-primary-dark/90 hover:opacity-90 text-white rounded-lg transition-all duration-300 flex items-center justify-center gap-2 whitespace-nowrap shadow-lg shadow-primary-light/20 dark:shadow-primary-dark/20"
              //   >
              //     <span>Get Updates</span>
              //     <ArrowRight size={18} />
              //   </button>
              // </form>
            )}
            <p className="text-sm text-muted-light dark:text-muted-dark">
              Be the first to know when we launch. No spam, just important
              updates.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-card-light/80 dark:bg-card-dark/80 backdrop-blur-sm border-t border-border-light dark:border-border-dark py-6">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-2">
              <LinkIcon
                size={20}
                className="text-primary-light dark:text-primary-dark"
              />
              <span className="text-sm font-medium text-text-light dark:text-text-dark">
                ReferralTree
              </span>
            </div>
            <p className="text-sm text-muted-light dark:text-muted-dark">
              © {new Date().getFullYear()} ReferralTree. All rights reserved.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPage;

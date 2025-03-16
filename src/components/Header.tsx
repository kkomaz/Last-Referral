import React, { useState } from 'react';
import { Link as RouterLink, useNavigate } from 'react-router-dom';
import { Link as LinkIcon, Menu, X, User, Settings, LogOut, Shield } from 'lucide-react';
import { UserProfile } from '../types';
import { usePrivy } from '@privy-io/react-auth';
import ThemeToggle from './ThemeToggle';
import SubscriptionBadge from './SubscriptionBadge';

interface HeaderProps {
  currentUser?: UserProfile;
}

const Header: React.FC<HeaderProps> = ({ currentUser }) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const navigate = useNavigate();
  const { logout, authenticated } = usePrivy();

  const handleNavigateToProfile = () => {
    if (currentUser) {
      navigate(`/${currentUser.username}`);
      setProfileMenuOpen(false);
    }
  };

  const handleNavigateToSettings = () => {
    navigate('/settings');
    setProfileMenuOpen(false);
  };

  const handleNavigateToSuperAdmin = () => {
    navigate('/super-admin');
    setProfileMenuOpen(false);
  };

  const handleSignOut = async () => {
    try {
      // Sign out from Privy
      logout();
      
      // Redirect to home page after sign out
      navigate('/');
      setProfileMenuOpen(false);
    } catch (error) {
      console.error('Error in handleSignOut:', error);
    }
  };

  // Get first letter of username for the avatar
  const getInitial = () => {
    if (currentUser && currentUser.username) {
      return currentUser.username.charAt(0).toUpperCase();
    }
    return 'U';
  };

  console.log(currentUser, '::currentUser');

  return (
    <header className="bg-card-light dark:bg-card-dark border-b border-border-light dark:border-border-dark sticky top-0 z-10">
      <div className="max-w-7xl mx-auto px-4 py-3 flex justify-between items-center">
        <RouterLink to="/" className="flex items-center gap-2">
          <LinkIcon size={24} className="text-primary-light dark:text-primary-dark" />
          <span className="text-xl font-bold text-text-light dark:text-text-dark">ReferralTree</span>
        </RouterLink>
        
        {/* User Profile or Auth Buttons */}
        <div className="flex items-center gap-3">
          <ThemeToggle />
          
          {authenticated && currentUser ? (
            <div className="relative">
              <button 
                onClick={() => setProfileMenuOpen(!profileMenuOpen)}
                className="flex items-center gap-2 focus:outline-none"
              >
                {currentUser.avatarUrl ? (
                  <img 
                    src={currentUser.avatarUrl} 
                    alt={currentUser.username}
                    className="w-8 h-8 rounded-full object-cover"
                    onError={(e) => {
                      const img = e.target as HTMLImageElement;
                      img.style.display = 'none';
                      img.parentElement!.classList.add('bg-primary-light', 'dark:bg-primary-dark', 'text-white', 'flex', 'items-center', 'justify-center', 'font-medium');
                      img.parentElement!.innerHTML = getInitial();
                    }}
                  />
                ) : (
                  <div className="w-8 h-8 rounded-full bg-primary-light dark:bg-primary-dark text-white flex items-center justify-center font-medium">
                    {getInitial()}
                  </div>
                )}
                <div className="hidden md:flex items-center gap-2">
                  <span className="font-medium text-text-light dark:text-text-dark">{currentUser.username}</span>
                  <SubscriptionBadge tier={currentUser.tier} />
                </div>
              </button>
              
              {/* Profile Dropdown */}
              {profileMenuOpen && (
                <div className="absolute right-0 mt-2 w-48 bg-card-light dark:bg-card-dark rounded-md shadow-lg py-1 z-20 border border-border-light dark:border-border-dark">
                  <button 
                    onClick={handleNavigateToProfile}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-text-light dark:text-text-dark hover:bg-background-light dark:hover:bg-gray-700 w-full text-left"
                  >
                    <User size={16} />
                    <span>View Public Profile</span>
                  </button>
                  <button 
                    onClick={handleNavigateToSettings}
                    className="flex items-center gap-2 px-4 py-2 text-sm text-text-light dark:text-text-dark hover:bg-background-light dark:hover:bg-gray-700 w-full text-left"
                  >
                    <Settings size={16} />
                    <span>Settings</span>
                  </button>
                  {currentUser.is_admin && (
                    <button 
                      onClick={handleNavigateToSuperAdmin}
                      className="flex items-center gap-2 px-4 py-2 text-sm text-text-light dark:text-text-dark hover:bg-background-light dark:hover:bg-gray-700 w-full text-left"
                    >
                      <Shield size={16} />
                      <span>Super Admin</span>
                    </button>
                  )}
                  <button 
                    className="flex items-center gap-2 px-4 py-2 text-sm text-text-light dark:text-text-dark hover:bg-background-light dark:hover:bg-gray-700 w-full text-left"
                    onClick={handleSignOut}
                  >
                    <LogOut size={16} />
                    <span>Sign Out</span>
                  </button>
                </div>
              )}
            </div>
          ) : (
            <>
              <button 
                onClick={() => navigate('/login')}
                className="hidden md:block px-4 py-2 border border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark rounded-md hover:bg-opacity-10 hover:bg-primary-light dark:hover:bg-opacity-10 dark:hover:bg-primary-dark transition-colors"
              >
                Sign In
              </button>
              <button 
                onClick={() => navigate('/login')}
                className="px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors"
              >
                Get Started
              </button>
            </>
          )}
          
          {/* Mobile Menu Button */}
          <button 
            className="md:hidden text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark focus:outline-none"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>
      </div>
      
      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden bg-card-light dark:bg-card-dark border-b border-border-light dark:border-border-dark py-4">
          <nav className="container mx-auto px-4 flex flex-col gap-4">
            <RouterLink 
              to="/admin" 
              className="text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark font-medium py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Dashboard
            </RouterLink>
            <RouterLink 
              to="/admin" 
              className="text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark font-medium py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              My Referrals
            </RouterLink>
            <RouterLink 
              to="/admin/analytics" 
              className="text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark font-medium py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Analytics
            </RouterLink>
            <RouterLink 
              to="/settings" 
              className="text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark font-medium py-2"
              onClick={() => setMobileMenuOpen(false)}
            >
              Settings
            </RouterLink>
            {currentUser?.is_admin && (
              <RouterLink 
                to="/super-admin" 
                className="text-text-light dark:text-text-dark hover:text-primary-light dark:hover:text-primary-dark font-medium py-2"
                onClick={() => setMobileMenuOpen(false)}
              >
                Super Admin
              </RouterLink>
            )}
            
            {!authenticated && (
              <div className="flex flex-col gap-3 mt-2">
                <button 
                  onClick={() => {
                    navigate('/login');
                    setMobileMenuOpen(false);
                  }}
                  className="px-4 py-2 border border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark rounded-md hover:bg-opacity-10 hover:bg-primary-light dark:hover:bg-opacity-10 dark:hover:bg-primary-dark transition-colors text-center"
                >
                  Sign In
                </button>
                <button 
                  onClick={() => {
                    navigate('/login');
                    setMobileMenuOpen(false);
                  }}
                  className="px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors text-center"
                >
                  Get Started
                </button>
              </div>
            )}
          </nav>
        </div>
      )}
    </header>
  );
};

export default Header;
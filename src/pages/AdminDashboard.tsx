import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { UserProfile } from '../types';
import { User, Settings, CreditCard } from 'lucide-react';
import SettingsPage from './Settings';
import Subscriptions from './Subscriptions';

interface AdminDashboardProps {
  currentUser: UserProfile;
  isAuthenticated?: boolean;
  onProfileUpdate?: (updatedProfile: UserProfile) => void;
}

const AdminDashboard: React.FC<AdminDashboardProps> = ({
  currentUser,
  isAuthenticated = false,
  onProfileUpdate,
}) => {
  const navigate = useNavigate();
  const location = useLocation();
  const [activeView, setActiveView] = useState<string>(
    location.pathname.includes('settings')
      ? 'settings'
      : location.pathname.includes('subscriptions')
      ? 'subscriptions'
      : 'dashboard'
  );

  const handleNavigation = (path: string, view: string) => {
    setActiveView(view);
    navigate(path, { replace: true });
  };

  const menuItems = [
    {
      icon: <User size={20} />,
      label: 'View Public Profile',
      onClick: () => navigate(`/${currentUser.username}`),
      view: 'profile',
    },
    {
      icon: <Settings size={20} />,
      label: 'Update Profile',
      onClick: () => handleNavigation('/admin/settings', 'settings'),
      view: 'settings',
    },
    // {
    //   icon: <CreditCard size={20} />,
    //   label: 'My Subscriptions',
    //   onClick: () => handleNavigation('/admin/subscriptions', 'subscriptions'),
    //   view: 'subscriptions'
    // },
  ];

  const renderContent = () => {
    switch (activeView) {
      case 'settings':
        return (
          <SettingsPage
            currentUser={currentUser}
            onProfileUpdate={onProfileUpdate}
            embedded={true}
          />
        );
      case 'subscriptions':
        return <Subscriptions currentUser={currentUser} />;
      default:
        return (
          <div className="p-6">
            <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-6">
              Welcome, {currentUser.username}!
            </h1>
            <p className="text-muted-light dark:text-muted-dark">
              Select an option from the sidebar to get started.
            </p>
          </div>
        );
    }
  };

  return (
    <div className="flex h-[calc(100vh-64px)]">
      {/* Sidebar */}
      <div className="w-64 bg-card-light dark:bg-card-dark border-r border-border-light dark:border-border-dark">
        <div className="p-4">
          <h2 className="text-lg font-semibold text-text-light dark:text-text-dark mb-6">
            Dashboard
          </h2>
          <nav className="space-y-2">
            {menuItems.map((item, index) => (
              <button
                key={index}
                onClick={item.onClick}
                className={`w-full flex items-center gap-3 px-4 py-2 text-left rounded-md transition-colors ${
                  activeView === item.view
                    ? 'bg-primary-light dark:bg-primary-dark text-white'
                    : 'text-text-light dark:text-text-dark hover:bg-background-light dark:hover:bg-background-dark'
                }`}
              >
                {item.icon}
                <span>{item.label}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 bg-background-light dark:bg-background-dark overflow-auto">
        <div className="max-w-6xl mx-auto">{renderContent()}</div>
      </div>
    </div>
  );
};

export default AdminDashboard;

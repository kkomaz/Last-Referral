import { PrivyClientConfig } from '@privy-io/react-auth';

// Privy configuration
export const privyConfig: PrivyClientConfig = {
  // Use the provided Privy App ID
  appId: 'cm7soujsm01zeat9o834zvjko',
  // Configure login methods
  loginMethods: ['email', 'wallet', 'google', 'twitter', 'discord', 'github'],
  // Appearance customization
  appearance: {
    theme: 'light',
    accentColor: '#7b68ee',
    logo: 'https://images.unsplash.com/photo-1611224885990-ab7363d7f2a9?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
  },
  // Redirect to dashboard after login
  onSuccess: (user, isNewUser) => {
    window.location.href = '/admin';
  },
};
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { PrivyProvider } from '@privy-io/react-auth';
import App from './App.tsx';
import './index.css';
import { ThemeProvider } from './contexts/ThemeContext';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ThemeProvider>
      <PrivyProvider
        appId="cm7soujsm01zeat9o834zvjko"
        config={{
          loginMethods: ['email', 'wallet', 'google', 'twitter', 'discord', 'github'],
          appearance: {
            theme: 'light',
            accentColor: '#7b68ee',
            logo: 'https://images.unsplash.com/photo-1611224885990-ab7363d7f2a9?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          },
          onSuccess: (user, isNewUser) => {
            window.location.href = '/admin';
          },
        }}
      >
        <App />
      </PrivyProvider>
    </ThemeProvider>
  </StrictMode>
);
import React, { useState, useEffect } from 'react';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  useLocation,
} from 'react-router-dom';
import { usePrivy } from '@privy-io/react-auth';
import AdminDashboard from './pages/AdminDashboard';
import PublicProfile from './pages/PublicProfile';
import LandingPage from './pages/LandingPage';
import Settings from './pages/Settings';
import SuperAdmin from './pages/SuperAdmin';
import Header from './components/Header';
import PrivyAuth from './components/PrivyAuth';
import UsernameRegistration from './components/UsernameRegistration';
import SuccessPage from './pages/SuccessPage';
import CancelPage from './pages/CancelPage';
import { ReferralData, UserProfile } from './types';
import { supabase, setPrivyAuthForSupabase } from './lib/supabase';

// Helper component to conditionally render header
const HeaderWrapper = ({ currentUser }: { currentUser: UserProfile | null }) => {
  const location = useLocation();
  const isAdminRoute = location.pathname.startsWith('/admin') || location.pathname.startsWith('/settings') || location.pathname.startsWith('/super-admin');
  
  if (!isAdminRoute) return null;
  return <Header currentUser={currentUser} />;
};

function App() {
  const { ready, authenticated, user, getAccessToken } = usePrivy();
  const [currentUser, setCurrentUser] = useState<UserProfile | null>(null);
  const [hasUsername, setHasUsername] = useState<boolean>(false);
  const [referrals, setReferrals] = useState<ReferralData[]>([]);

  // Set up Privy authentication with Supabase
  useEffect(() => {
    const setupAuth = async () => {
      if (!ready || !authenticated || !user) {
        return;
      }

      try {
        // Get the Privy JWT token
        const privyToken = await getAccessToken();
        
        if (!privyToken) {
          console.warn('No Privy token available');
          return;
        }

        // Set up Supabase with Privy token
        const success = await setPrivyAuthForSupabase(privyToken);
        
        if (success) {
          // After setting auth, fetch the user profile
          await fetchUserProfile();
        } else {
          console.error('Failed to set up Supabase authentication');
        }
      } catch (error) {
        console.error('Error setting up authentication:', error);
      }
    };

    setupAuth();
  }, [ready, authenticated, user, getAccessToken]);

  const fetchUserProfile = async () => {
    console.log('Fetching user profile:', { ready, authenticated, user });
    if (!ready || !authenticated || !user) {
      return;
    }

    try {
      const { data: profile, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('privy_id', user.id)
        .maybeSingle();

      if (error) {
        console.error('Error fetching profile:', error);
        return;
      }

      console.log('Fetched profile:', profile);

      if (profile) {
        const userProfile: UserProfile = {
          id: profile.id,
          username: profile.username || '',
          bio: profile.bio || 'Tech enthusiast sharing my favorite products and services.',
          avatarUrl: profile.avatar_url || '',
          email: profile.email || '',
          primaryColor: profile.primary_color || '#7b68ee',
          secondaryColor: profile.secondary_color || '#2b2d42',
          bodyColor: profile.body_color || '#f7f9fb',
          cardColor: profile.card_color || '#ffffff',
          socialLinks: {
            twitter: profile.twitter || '',
            instagram: profile.instagram || '',
            linkedin: profile.linkedin || '',
            website: profile.website || '',
          },
          tier: profile.tier,
          maxReferrals: profile.max_referrals,
          maxTags: profile.max_tags,
          is_admin: profile.is_admin
        };
        setCurrentUser(userProfile);
        setHasUsername(!!profile.username);
      } else {
        console.log('No profile found, setting currentUser to null');
        setCurrentUser(null);
        setHasUsername(false);
      }
    } catch (error) {
      console.error('Error in fetchUserProfile:', error);
    }
  };

  useEffect(() => {
    fetchUserProfile();
  }, [ready, authenticated, user]);

  useEffect(() => {
    const fetchReferrals = async () => {
      if (!authenticated || !currentUser) return;

      try {
        console.log('Fetching referrals for user:', currentUser.id);
        
        const { data, error } = await supabase
          .from('referrals')
          .select(`
            *,
            referral_tags (
              tag: tags (
                id,
                name
              )
            )
          `)
          .eq('user_id', currentUser.id)
          .order('created_at', { ascending: false });

        if (error) {
          console.error('Error fetching referrals:', error);
          return;
        }

        console.log('Raw referrals data:', data);

        if (data) {
          const transformedData: ReferralData[] = data.map((item) => ({
            id: item.id,
            title: item.title,
            description: item.description || '',
            url: item.url,
            imageUrl: item.image_url || '',
            subtitle: item.subtitle || '',
            isExpanded: false,
            userId: item.user_id,
            tags: item.referral_tags
              .map(rt => rt.tag)
              .filter(Boolean)
              .sort((a, b) => a.name.localeCompare(b.name))
          }));

          console.log('Setting referrals:', transformedData);
          setReferrals(transformedData);
        }
      } catch (error) {
        console.error('Error in fetchReferrals:', error);
      }
    };

    fetchReferrals();
  }, [authenticated, currentUser]);

  const handleUsernameComplete = async (username: string) => {
    // Fetch the complete profile after username registration
    await fetchUserProfile();
  };

  const handleProfileUpdate = async (updatedProfile: UserProfile) => {
    setCurrentUser(updatedProfile);
    // Refetch the profile to ensure we have the latest data
    await fetchUserProfile();
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

  console.log('Current state:', { authenticated, currentUser, hasUsername });

  return (
    <Router>
      <div className="min-h-screen flex flex-col bg-background-light dark:bg-background-dark">
        {authenticated && currentUser && <HeaderWrapper currentUser={currentUser} />}

        <div className="flex-grow">
          <Routes>
            <Route 
              path="/" 
              element={authenticated ? <Navigate to="/admin" /> : <LandingPage />} 
            />
            <Route path="/login" element={<PrivyAuth />} />
            <Route
              path="/admin/*"
              element={
                authenticated ? (
                  hasUsername ? (
                    <AdminDashboard
                      currentUser={currentUser!}
                      isAuthenticated={authenticated}
                      onProfileUpdate={handleProfileUpdate}
                    />
                  ) : (
                    <UsernameRegistration onComplete={handleUsernameComplete} />
                  )
                ) : (
                  <Navigate to="/login" />
                )
              }
            />
            <Route
              path="/settings"
              element={
                authenticated && hasUsername ? (
                  <Settings 
                    currentUser={currentUser!}
                    onProfileUpdate={handleProfileUpdate}
                  />
                ) : (
                  <Navigate to="/login" />
                )
              }
            />
            <Route
              path="/super-admin"
              element={
                authenticated && hasUsername && currentUser?.is_admin ? (
                  <SuperAdmin />
                ) : (
                  <Navigate to="/admin" />
                )
              }
            />
            <Route
              path="/:username"
              element={
                <PublicProfile
                  referrals={referrals}
                  currentUser={currentUser!}
                  setReferrals={setReferrals}
                />
              }
            />
            <Route
              path="/success"
              element={
                authenticated && currentUser ? (
                  <SuccessPage userId={currentUser.id} />
                ) : (
                  <Navigate to="/login" />
                )
              }
            />
            <Route path="/cancel" element={<CancelPage />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { UserProfile } from '../types';
import { Search, Crown, UserX, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import SubscriptionBadge from '../components/SubscriptionBadge';

const SuperAdmin: React.FC = () => {
  const [profiles, setProfiles] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedProfile, setSelectedProfile] = useState<UserProfile | null>(null);
  const [updatingTier, setUpdatingTier] = useState(false);
  const navigate = useNavigate();

  useEffect(() => {
    fetchProfiles();
  }, []);

  const fetchProfiles = async () => {
    try {
      const { data, error } = await supabase
        .rpc('admin_get_profiles');
      
      if (error) throw error;

      setProfiles(data.map(p => ({
        id: p.id,
        username: p.username || '',
        bio: p.bio || '',
        avatarUrl: p.avatar_url || '',
        email: p.email || '',
        tier: p.tier,
        maxReferrals: p.max_referrals,
        maxTags: p.max_tags,
        is_admin: p.is_admin,
        socialLinks: {
          twitter: p.twitter || '',
          instagram: p.instagram || '',
          linkedin: p.linkedin || '',
          website: p.website || ''
        }
      })));
    } catch (error) {
      console.error('Error fetching profiles:', error);
      toast.error('Failed to load profiles');
      navigate('/admin');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateTier = async (profile: UserProfile, newTier: 'basic' | 'premium') => {
    try {
      setUpdatingTier(true);
      setSelectedProfile(profile);

      // Use the admin_update_user_tier RPC function
      const { data, error } = await supabase
        .rpc('admin_update_user_tier', {
          p_profile_id: profile.id,
          p_new_tier: newTier,
          p_reason: `Manual ${newTier} tier update by admin`
        });

      if (error) throw error;

      toast.success(`Updated ${profile.username} to ${newTier} tier`);
      await fetchProfiles();
    } catch (error) {
      console.error('Error updating tier:', error);
      toast.error('Failed to update tier');
    } finally {
      setUpdatingTier(false);
      setSelectedProfile(null);
    }
  };

  const filteredProfiles = profiles.filter(profile => 
    profile.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
    profile.email?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-2xl font-bold text-text-light dark:text-text-dark">
          Super Admin Dashboard
        </h1>
        
        <div className="relative">
          <input
            type="text"
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 pr-4 py-2 rounded-lg border border-border-light dark:border-border-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark"
          />
          <Search className="absolute left-3 top-2.5 text-muted-light dark:text-muted-dark" size={18} />
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 size={32} className="animate-spin text-primary-light dark:text-primary-dark" />
        </div>
      ) : filteredProfiles.length === 0 ? (
        <div className="text-center py-12 text-muted-light dark:text-muted-dark">
          No users found
        </div>
      ) : (
        <div className="grid gap-6">
          {filteredProfiles.map(profile => (
            <div 
              key={profile.id}
              className="bg-card-light dark:bg-card-dark rounded-lg p-6 border border-border-light dark:border-border-dark"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-center gap-4">
                  {profile.avatarUrl ? (
                    <img 
                      src={profile.avatarUrl} 
                      alt={profile.username}
                      className="w-12 h-12 rounded-full object-cover"
                    />
                  ) : (
                    <div className="w-12 h-12 rounded-full bg-primary-light dark:bg-primary-dark text-white flex items-center justify-center font-medium text-lg">
                      {profile.username.charAt(0).toUpperCase()}
                    </div>
                  )}
                  
                  <div>
                    <div className="flex items-center gap-2">
                      <h3 className="text-lg font-medium text-text-light dark:text-text-dark">
                        {profile.username}
                      </h3>
                      <SubscriptionBadge tier={profile.tier} />
                      {profile.is_admin && (
                        <span className="px-2 py-0.5 text-xs font-medium bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400 rounded-full">
                          Admin
                        </span>
                      )}
                    </div>
                    
                    {profile.email && (
                      <p className="text-sm text-muted-light dark:text-muted-dark mt-1">
                        {profile.email}
                      </p>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  {profile.tier === 'basic' ? (
                    <button
                      onClick={() => handleUpdateTier(profile, 'premium')}
                      disabled={updatingTier && selectedProfile?.id === profile.id}
                      className="flex items-center gap-2 px-4 py-2 bg-primary-light dark:bg-primary-dark text-white rounded-lg hover:bg-opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {updatingTier && selectedProfile?.id === profile.id ? (
                        <>
                          <Loader2 size={16} className="animate-spin" />
                          <span>Upgrading...</span>
                        </>
                      ) : (
                        <>
                          <Crown size={16} />
                          <span>Upgrade to Premium</span>
                        </>
                      )}
                    </button>
                  ) : (
                    <button
                      onClick={() => handleUpdateTier(profile, 'basic')}
                      disabled={updatingTier && selectedProfile?.id === profile.id}
                      className="flex items-center gap-2 px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {updatingTier && selectedProfile?.id === profile.id ? (
                        <>
                          <Loader2 size={16} className="animate-spin" />
                          <span>Downgrading...</span>
                        </>
                      ) : (
                        <>
                          <UserX size={16} />
                          <span>Downgrade to Basic</span>
                        </>
                      )}
                    </button>
                  )}
                </div>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
                <div className="flex items-center gap-2 text-muted-light dark:text-muted-dark">
                  <span>Referrals:</span>
                  <span className="font-medium text-text-light dark:text-text-dark">
                    {profile.maxReferrals}
                  </span>
                </div>
                <div className="flex items-center gap-2 text-muted-light dark:text-muted-dark">
                  <span>Tags:</span>
                  <span className="font-medium text-text-light dark:text-text-dark">
                    {profile.maxTags}
                  </span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default SuperAdmin;
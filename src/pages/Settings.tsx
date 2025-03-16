import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { UserProfile } from '../types';
import { Loader2 } from 'lucide-react';
import toast, { Toaster } from 'react-hot-toast';

interface SettingsProps {
  currentUser: UserProfile;
  onProfileUpdate: (updatedProfile: UserProfile) => void;
  embedded?: boolean;
}

const Settings: React.FC<SettingsProps> = ({ 
  currentUser, 
  onProfileUpdate,
  embedded = false 
}) => {
  const [bio, setBio] = useState(currentUser.bio);
  const [avatarUrl, setAvatarUrl] = useState(currentUser.avatarUrl);
  const [email, setEmail] = useState(currentUser.email || '');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const { data, error } = await supabase
        .rpc('update_profile_v2', {
          p_profile_id: currentUser.id,
          p_bio: bio,
          p_avatar_url: avatarUrl,
          p_email: email || null
        });

      if (error) {
        throw error;
      }

      onProfileUpdate({
        ...currentUser,
        bio: data.bio,
        avatarUrl: data.avatar_url,
        email: data.email,
        socialLinks: {
          ...currentUser.socialLinks,
          twitter: data.twitter || '',
          instagram: data.instagram || '',
          linkedin: data.linkedin || '',
          website: data.website || ''
        }
      });

      toast.success('Profile updated successfully!', {
        duration: 2000,
        position: 'top-center',
        style: {
          background: '#10B981',
          color: '#FFFFFF',
          fontWeight: 500,
        },
        icon: '✓',
      });

      if (!embedded) {
        setTimeout(() => {
          navigate('/admin');
        }, 1000);
      }
    } catch (err) {
      console.error('Error updating profile:', err);
      
      toast.error('Failed to update profile. Please try again.', {
        duration: 3000,
        position: 'top-center',
        style: {
          background: '#EF4444',
          color: '#FFFFFF',
          fontWeight: 500,
        },
        icon: '✕',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const containerClass = embedded 
    ? 'p-8' 
    : 'container mx-auto px-4 py-12 max-w-3xl';

  return (
    <main className={containerClass}>
      <Toaster 
        toastOptions={{
          className: 'rounded-md shadow-lg',
          style: {
            maxWidth: '500px',
            padding: '12px 24px',
          },
        }}
      />

      <div className="bg-card-light dark:bg-card-dark rounded-xl p-8 shadow-sm">
        <h1 className="text-3xl font-bold text-text-light dark:text-text-dark mb-8">
          Profile Settings
        </h1>

        <form onSubmit={handleSubmit} className="space-y-8">
          <div>
            <label 
              htmlFor="email" 
              className="block text-base font-medium text-text-light dark:text-text-dark mb-3"
            >
              Email
            </label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-3 rounded-lg border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-background-light dark:bg-background-dark text-text-light dark:text-text-dark"
              placeholder="Enter your email address"
            />
          </div>

          <div>
            <label 
              htmlFor="bio" 
              className="block text-base font-medium text-text-light dark:text-text-dark mb-3"
            >
              Bio
            </label>
            <textarea
              id="bio"
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              className="w-full px-4 py-3 rounded-lg border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-background-light dark:bg-background-dark text-text-light dark:text-text-dark"
              rows={8}
              placeholder="Tell others about yourself..."
            />
          </div>

          <div>
            <label 
              htmlFor="avatarUrl" 
              className="block text-base font-medium text-text-light dark:text-text-dark mb-3"
            >
              Avatar URL
            </label>
            <input
              type="url"
              id="avatarUrl"
              value={avatarUrl}
              onChange={(e) => setAvatarUrl(e.target.value)}
              className="w-full px-4 py-3 rounded-lg border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-background-light dark:bg-background-dark text-text-light dark:text-text-dark"
              placeholder="https://example.com/avatar.jpg"
            />
            {avatarUrl && (
              <div className="mt-4">
                <p className="text-sm text-muted-light dark:text-muted-dark mb-3">Preview:</p>
                <img
                  src={avatarUrl}
                  alt="Avatar preview"
                  className="w-24 h-24 rounded-full object-cover border-2 border-border-light dark:border-border-dark"
                  onError={(e) => {
                    const img = e.target as HTMLImageElement;
                    img.src = 'https://via.placeholder.com/80';
                  }}
                />
              </div>
            )}
          </div>

          <div className="flex justify-end gap-4 pt-6 border-t border-border-light dark:border-border-dark">
            {!embedded && (
              <button
                type="button"
                onClick={() => navigate('/admin')}
                className="px-6 py-2.5 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
              >
                Cancel
              </button>
            )}
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex items-center justify-center gap-2 px-6 py-2.5 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-w-[120px]"
            >
              {isSubmitting ? (
                <>
                  <Loader2 size={18} className="animate-spin" />
                  <span>Saving...</span>
                </>
              ) : (
                <span>Save Changes</span>
              )}
            </button>
          </div>
        </form>
      </div>
    </main>
  );
};

export default Settings;
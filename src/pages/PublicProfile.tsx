import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Search, Twitter, Instagram, Linkedin, Globe, Copy, Settings, Plus, Eye, EyeOff, Tags, Edit, LayoutDashboard } from 'lucide-react';
import ReferralCard from '../components/ReferralCard';
import { ReferralData, UserProfile } from '../types';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';
import ThemeToggle from '../components/ThemeToggle';
import ColorPicker from '../components/ColorPicker';
import ReferralModal from '../components/ReferralModal';
import TagManagementModal from '../components/TagManagementModal';

interface PublicProfileProps {
  referrals: ReferralData[];
  currentUser: UserProfile;
  setReferrals: React.Dispatch<React.SetStateAction<ReferralData[]>>;
}

const PublicProfile: React.FC<PublicProfileProps> = ({ referrals, currentUser, setReferrals }) => {
  const { username } = useParams<{ username: string }>();
  const [searchTerm, setSearchTerm] = useState('');
  const [activeTag, setActiveTag] = useState<string>('');
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [showColorPicker, setShowColorPicker] = useState(false);
  const [isGuestView, setIsGuestView] = useState(false);
  const [showReferralModal, setShowReferralModal] = useState(false);
  const [showTagModal, setShowTagModal] = useState(false);
  const [editingReferral, setEditingReferral] = useState<ReferralData | null>(null);
  const [previewColors, setPreviewColors] = useState({
    primary: currentUser?.primaryColor || '#7b68ee',
    secondary: currentUser?.secondaryColor || '#2b2d42',
    body: currentUser?.bodyColor || '#f7f9fb',
    card: currentUser?.cardColor || '#ffffff'
  });
  const navigate = useNavigate();

  useEffect(() => {
    const fetchProfile = async () => {
      if (!username) return;
      
      setLoading(true);
      
      try {
        if (currentUser && currentUser.username === username) {
          setProfile(currentUser);
          setPreviewColors({
            primary: currentUser.primaryColor || '#7b68ee',
            secondary: currentUser.secondaryColor || '#2b2d42',
            body: currentUser.bodyColor || '#f7f9fb',
            card: currentUser.cardColor || '#ffffff'
          });
          setLoading(false);
          return;
        }
        
        const { data, error } = await supabase
          .from('profiles')
          .select(`
            id,
            username,
            bio,
            avatar_url,
            primary_color,
            secondary_color,
            body_color,
            card_color,
            twitter,
            instagram,
            linkedin,
            website
          `)
          .eq('username', username)
          .maybeSingle();
        
        if (error) {
          console.error('Error fetching profile:', error);
          setLoading(false);
          return;
        }
        
        if (data) {
          const userProfile: UserProfile = {
            id: data.id,
            username: data.username,
            bio: data.bio || 'Tech enthusiast sharing my favorite products and services.',
            avatarUrl: data.avatar_url || '',
            primaryColor: data.primary_color || '#7b68ee',
            secondaryColor: data.secondary_color || '#2b2d42',
            bodyColor: data.body_color || '#f7f9fb',
            cardColor: data.card_color || '#ffffff',
            socialLinks: {
              twitter: data.twitter || '',
              instagram: data.instagram || '',
              linkedin: data.linkedin || '',
              website: data.website || ''
            }
          };
          
          setProfile(userProfile);
          setPreviewColors({
            primary: userProfile.primaryColor || '#7b68ee',
            secondary: userProfile.secondaryColor || '#2b2d42',
            body: userProfile.bodyColor || '#f7f9fb',
            card: userProfile.cardColor || '#ffffff'
          });

          // Update meta tags for social sharing
          updateMetaTags(userProfile);
        }
      } catch (error) {
        console.error('Error in fetchProfile:', error);
      } finally {
        setLoading(false);
      }
    };
    
    fetchProfile();
  }, [username, currentUser]);

  // Function to update meta tags
  const updateMetaTags = (profile: UserProfile) => {
    // Update title
    document.title = `${profile.username} on ReferralTree`;

    // Update meta description
    const metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription) {
      metaDescription.setAttribute('content', profile.bio);
    }

    // Update OG meta tags
    const ogTitle = document.querySelector('meta[property="og:title"]');
    const ogDescription = document.querySelector('meta[property="og:description"]');
    const ogImage = document.querySelector('meta[property="og:image"]');
    const ogUrl = document.querySelector('meta[property="og:url"]');

    if (ogTitle) ogTitle.setAttribute('content', `${profile.username} on ReferralTree`);
    if (ogDescription) ogDescription.setAttribute('content', profile.bio);
    if (ogImage) ogImage.setAttribute('content', profile.avatarUrl || 'https://referraltree.com/default-og-image.jpg');
    if (ogUrl) ogUrl.setAttribute('content', `https://referraltree.com/${profile.username}`);

    // Update Twitter meta tags
    const twitterTitle = document.querySelector('meta[property="twitter:title"]');
    const twitterDescription = document.querySelector('meta[property="twitter:description"]');
    const twitterImage = document.querySelector('meta[property="twitter:image"]');
    const twitterUrl = document.querySelector('meta[property="twitter:url"]');

    if (twitterTitle) twitterTitle.setAttribute('content', `${profile.username} on ReferralTree`);
    if (twitterDescription) twitterDescription.setAttribute('content', profile.bio);
    if (twitterImage) twitterImage.setAttribute('content', profile.avatarUrl || 'https://referraltree.com/default-og-image.jpg');
    if (twitterUrl) twitterUrl.setAttribute('content', `https://referraltree.com/${profile.username}`);
  };

  // Clean up meta tags when component unmounts
  useEffect(() => {
    return () => {
      // Reset meta tags to default values
      document.title = 'ReferralTree - Share Your Favorite Products';
      
      const metaDescription = document.querySelector('meta[name="description"]');
      if (metaDescription) {
        metaDescription.setAttribute('content', 'Share your favorite products and services, track referrals, and earn rewards with ReferralTree.');
      }

      // Reset OG meta tags
      const ogTitle = document.querySelector('meta[property="og:title"]');
      const ogDescription = document.querySelector('meta[property="og:description"]');
      const ogImage = document.querySelector('meta[property="og:image"]');
      const ogUrl = document.querySelector('meta[property="og:url"]');

      if (ogTitle) ogTitle.setAttribute('content', 'ReferralTree');
      if (ogDescription) ogDescription.setAttribute('content', 'Share your favorite products and services, track referrals, and earn rewards.');
      if (ogImage) ogImage.setAttribute('content', 'https://referraltree.com/default-og-image.jpg');
      if (ogUrl) ogUrl.setAttribute('content', 'https://referraltree.com');

      // Reset Twitter meta tags
      const twitterTitle = document.querySelector('meta[property="twitter:title"]');
      const twitterDescription = document.querySelector('meta[property="twitter:description"]');
      const twitterImage = document.querySelector('meta[property="twitter:image"]');
      const twitterUrl = document.querySelector('meta[property="twitter:url"]');

      if (twitterTitle) twitterTitle.setAttribute('content', 'ReferralTree');
      if (twitterDescription) twitterDescription.setAttribute('content', 'Share your favorite products and services, track referrals, and earn rewards.');
      if (twitterImage) twitterImage.setAttribute('content', 'https://referraltree.com/default-og-image.jpg');
      if (twitterUrl) twitterUrl.setAttribute('content', 'https://referraltree.com');
    };
  }, []);

  const handleColorChange = async (newColors: typeof previewColors) => {
    if (profile?.id === currentUser.id) {
      try {
        const { data, error } = await supabase
          .rpc('update_profile_v2', {
            p_profile_id: profile.id,
            p_primary_color: newColors.primary,
            p_secondary_color: newColors.secondary,
            p_body_color: newColors.body,
            p_card_color: newColors.card
          });

        if (error) {
          throw error;
        }

        setPreviewColors(newColors);
        setProfile(prev => prev ? {
          ...prev,
          primaryColor: newColors.primary,
          secondaryColor: newColors.secondary,
          bodyColor: newColors.body,
          cardColor: newColors.card
        } : null);

        toast.success('Colors updated successfully!');
      } catch (error) {
        console.error('Error updating colors:', error);
        toast.error('Failed to update colors');
        
        if (profile) {
          const originalColors = {
            primary: profile.primaryColor || '#7b68ee',
            secondary: profile.secondaryColor || '#2b2d42',
            body: profile.bodyColor || '#f7f9fb',
            card: profile.cardColor || '#ffffff'
          };
          setPreviewColors(originalColors);
        }
      }
    }
  };

  const handlePreviewColors = (newColors: typeof previewColors) => {
    setPreviewColors(newColors);
  };

  const handleResetColors = () => {
    if (profile) {
      const originalColors = {
        primary: profile.primaryColor || '#7b68ee',
        secondary: profile.secondaryColor || '#2b2d42',
        body: profile.bodyColor || '#f7f9fb',
        card: profile.cardColor || '#ffffff'
      };
      setPreviewColors(originalColors);
    }
  };

  const handleAddReferral = () => {
    setEditingReferral(null);
    setShowReferralModal(true);
  };

  const handleEditReferral = (referral: ReferralData) => {
    setEditingReferral(referral);
    setShowReferralModal(true);
  };

  const handleManageTags = () => {
    setShowTagModal(true);
  };

  const handleReferralSave = async () => {
    if (profile) {
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
        .eq('user_id', profile.id)
        .order('created_at', { ascending: false });

      if (error) {
        console.error('Error fetching referrals:', error);
        return;
      }

      const updatedReferrals = data.map(item => ({
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

      setReferrals(updatedReferrals);
    }
  };

  const toggleExpand = (id: string) => {
    const updatedReferrals = referrals.map(ref => 
      ref.id === id ? { ...ref, isExpanded: !ref.isExpanded } : ref
    );
    setReferrals(updatedReferrals);
  };
  
  const handleCopyLink = (url: string) => {
    navigator.clipboard.writeText(url);
    toast.success('Link copied to clipboard!');
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center" style={{ backgroundColor: previewColors.body }}>
        <div className="text-center">
          <div className="w-16 h-16 border-4 border-t-transparent rounded-full animate-spin mx-auto mb-4" style={{ borderColor: previewColors.primary }}></div>
          <p className="text-muted-light dark:text-muted-dark">Loading profile...</p>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="container mx-auto px-4 py-16 text-center">
        <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-4">User not found</h1>
        <p className="text-muted-light dark:text-muted-dark">The user "{username}" does not exist or has not created a profile yet.</p>
        <button 
          onClick={() => navigate('/admin')}
          className="mt-6 px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors"
        >
          Go to Dashboard
        </button>
      </div>
    );
  }

  const isOwnProfile = currentUser && currentUser.id === profile.id;
  const userReferrals = profile ? referrals.filter(ref => ref.userId === profile.id) : [];
  const uniqueTags = Array.from(new Set(userReferrals.flatMap(ref => ref.tags.map(tag => tag.name))));
  
  const filteredReferrals = userReferrals.filter(ref => 
    (ref.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    ref.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
    ref.tags.some(tag => tag.name.toLowerCase().includes(searchTerm.toLowerCase()))) &&
    (activeTag === '' || ref.tags.some(tag => tag.name === activeTag))
  );

  return (
    <div className="min-h-screen relative" style={{ backgroundColor: previewColors.body }}>
      {/* Guest View Toggle - Absolute positioned */}
      {isOwnProfile && (
        <button
          onClick={() => setIsGuestView(!isGuestView)}
          className="absolute top-4 right-4 z-50 flex items-center gap-1 px-3 py-1.5 rounded-md border border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark hover:bg-primary-light hover:bg-opacity-5 transition-colors text-sm"
        >
          {isGuestView ? <Eye size={16} /> : <EyeOff size={16} />}
          <span>{isGuestView ? 'Exit Guest View' : 'View as Guest'}</span>
        </button>
      )}

      <div className="container mx-auto px-4 py-12 max-w-3xl text-center">
        <div className="flex flex-col items-center gap-6">
          {profile.avatarUrl ? (
            <img 
              src={profile.avatarUrl} 
              alt={profile.username}
              className="w-32 h-32 rounded-full object-cover border-4 border-white shadow-md"
            />
          ) : (
            <div className="w-32 h-32 rounded-full bg-white text-4xl font-medium flex items-center justify-center shadow-md">
              {profile.username.charAt(0).toUpperCase()}
            </div>
          )}
          
          <div className="text-center">
            <h1 className="text-3xl font-bold mb-3" style={{ color: previewColors.secondary }}>{profile.username}</h1>
            <p className="text-sm mb-4 max-w-2xl mx-auto" style={{ color: previewColors.secondary }}>{profile.bio}</p>
            
            <div className="flex flex-wrap justify-center gap-4 mb-4">
              {profile.socialLinks.twitter && (
                <a 
                  href={profile.socialLinks.twitter} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
                >
                  <Twitter size={18} />
                  <span>Twitter</span>
                </a>
              )}
              
              {profile.socialLinks.instagram && (
                <a 
                  href={profile.socialLinks.instagram} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
                >
                  <Instagram size={18} />
                  <span>Instagram</span>
                </a>
              )}
              
              {profile.socialLinks.linkedin && (
                <a 
                  href={profile.socialLinks.linkedin} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
                >
                  <Linkedin size={18} />
                  <span>LinkedIn</span>
                </a>
              )}
              
              {profile.socialLinks.website && (
                <a 
                  href={profile.socialLinks.website} 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="flex items-center gap-1 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
                >
                  <Globe size={18} />
                  <span>Website</span>
                </a>
              )}
            </div>

            {isOwnProfile && !isGuestView && (
              <div className="flex flex-col items-center gap-3 mt-4">
                <button
                  onClick={() => navigate('/admin')}
                  className="flex items-center gap-1 px-3 py-1.5 rounded-md bg-secondary-light dark:bg-secondary-dark text-white hover:bg-opacity-90 transition-colors text-sm"
                >
                  <LayoutDashboard size={16} />
                  <span>Go to Admin Dashboard</span>
                </button>
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowReferralModal(true)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-md bg-primary-light dark:bg-primary-dark text-white hover:bg-opacity-90 transition-colors text-sm"
                  >
                    <Plus size={16} />
                    <span>Add Referral</span>
                  </button>
                  <button
                    onClick={() => setShowTagModal(true)}
                    className="flex items-center gap-1 px-3 py-1.5 rounded-md border border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark hover:bg-primary-light hover:bg-opacity-5 transition-colors text-sm"
                  >
                    <Tags size={16} />
                    <span>Manage Tags</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
      
      <main className="container mx-auto px-4 py-8 max-w-5xl">
        <div className="flex justify-end items-center gap-3 mb-4">
          {isOwnProfile && !isGuestView && (
            <button
              onClick={() => setShowColorPicker(!showColorPicker)}
              className="flex items-center gap-1 px-3 py-1.5 rounded-md border border-primary-light dark:border-primary-dark text-primary-light dark:text-primary-dark hover:bg-primary-light hover:bg-opacity-5 transition-colors text-sm"
            >
              <Settings size={16} />
              <span>Customize Colors</span>
            </button>
          )}
        </div>

        {showColorPicker && isOwnProfile && !isGuestView && (
          <div className="mb-6">
            <ColorPicker
              colors={previewColors}
              onChange={handleColorChange}
              onPreview={handlePreviewColors}
              onReset={handleResetColors}
            />
          </div>
        )}

        <div className="mb-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <h2 className="text-2xl font-bold" style={{ color: previewColors.secondary }}>
            {profile.username}'s Referrals
            <span className="ml-2 text-sm font-normal text-muted-light dark:text-muted-dark">
              ({userReferrals.length})
            </span>
          </h2>
          
          <div className="relative w-full md:w-64">
            <input
              type="text"
              placeholder="Search referrals..."
              className="pl-10 pr-4 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 w-full"
              style={{ 
                backgroundColor: previewColors.card,
                borderColor: `${previewColors.primary}33`,
                color: previewColors.secondary
              }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            <Search className="absolute left-3 top-2.5 text-muted-light dark:text-muted-dark" size={18} />
          </div>
        </div>
        
        {uniqueTags.length > 0 && (
          <div className="mb-6 overflow-x-auto">
            <div className="flex gap-2 min-w-max pb-2">
              <button
                className={`px-4 py-2 rounded-md text-sm font-medium transition-colors`}
                style={{
                  backgroundColor: activeTag === '' ? previewColors.primary : previewColors.card,
                  color: activeTag === '' ? '#ffffff' : previewColors.secondary
                }}
                onClick={() => setActiveTag('')}
              >
                All
              </button>
              
              {uniqueTags.map(tag => (
                <button
                  key={tag}
                  className={`px-4 py-2 rounded-md text-sm font-medium transition-colors`}
                  style={{
                    backgroundColor: activeTag === tag ? previewColors.primary : previewColors.card,
                    color: activeTag === tag ? '#ffffff' : previewColors.secondary
                  }}
                  onClick={() => setActiveTag(tag)}
                >
                  {tag}
                </button>
              ))}
            </div>
          </div>
        )}
        
        {filteredReferrals.length === 0 ? (
          <div 
            className="rounded-lg shadow-md p-8 text-center"
            style={{ backgroundColor: previewColors.card }}
          >
            <p style={{ color: previewColors.secondary }}>
              No referrals found. Try a different search term.
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredReferrals.map(referral => (
              <ReferralCard 
                key={referral.id}
                referral={referral}
                onExpand={() => toggleExpand(referral.id)}
                onCopy={() => handleCopyLink(referral.url)}
                onEdit={() => isOwnProfile && !isGuestView && handleEditReferral(referral)}
                isAuthenticated={isOwnProfile && !isGuestView}
                customColors={previewColors}
              />
            ))}
          </div>
        )}
      </main>

      {profile && (
        <>
          <ReferralModal
            isOpen={showReferralModal}
            onClose={() => setShowReferralModal(false)}
            onSave={handleReferralSave}
            userId={profile.id}
            editingReferral={editingReferral || undefined}
          />

          <TagManagementModal
            isOpen={showTagModal}
            onClose={() => setShowTagModal(false)}
            userId={profile.id}
            onTagsUpdate={handleReferralSave}
          />
        </>
      )}
    </div>
  );
};

export default PublicProfile;
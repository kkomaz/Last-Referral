export interface ReferralData {
  id: string;
  title: string;
  description: string;
  url: string;
  imageUrl: string;
  subtitle: string;
  isExpanded: boolean;
  userId?: string;
  tags: Tag[];
}

export interface UserProfile {
  id: string;
  username: string;
  bio: string;
  avatarUrl: string;
  email?: string;
  primaryColor?: string;
  secondaryColor?: string;
  bodyColor?: string;
  cardColor?: string;
  tier: 'basic' | 'premium';
  maxReferrals: number;
  maxTags: number;
  is_admin?: boolean;
  socialLinks: {
    twitter?: string;
    instagram?: string;
    linkedin?: string;
    website?: string;
  };
}

export interface Tag {
  id: string;
  name: string;
  usage_count?: number;
}

// Re-export database types
export type { Database };
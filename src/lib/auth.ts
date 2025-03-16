import { supabase } from './supabase';
import { UserProfile } from '../types';

/**
 * Get user profile by Privy ID
 */
export async function getUserProfile(privyId: string): Promise<UserProfile | null> {
  try {
    const { data, error } = await supabase.rpc('get_profile_by_privy_id', {
      p_privy_id: privyId
    });

    if (error) {
      console.error('Error fetching profile:', error);
      return null;
    }

    if (!data) {
      return null;
    }

    return {
      id: data.id,
      username: data.username || '',
      bio: data.bio || 'Tech enthusiast sharing my favorite products and services.',
      avatarUrl: data.avatar_url || '',
      socialLinks: {
        twitter: data.twitter || '',
        instagram: data.instagram || '',
        linkedin: data.linkedin || '',
        website: data.website || '',
      },
    };
  } catch (error) {
    console.error('Error in getUserProfile:', error);
    return null;
  }
}

/**
 * Ensure user profile exists
 */
export async function ensureUserProfile(privyId: string, username?: string): Promise<string | null> {
  try {
    const { data, error } = await supabase.rpc('ensure_profile_exists', {
      p_privy_id: privyId,
      p_username: username
    });

    if (error) {
      console.error('Error ensuring profile exists:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in ensureUserProfile:', error);
    return null;
  }
}
import { supabase } from './supabase';
import { ReferralData } from '../types';

/**
 * Fetch user's referrals with tags
 */
export async function getUserReferrals(userId: string): Promise<ReferralData[]> {
  try {
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
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching referrals:', error);
      return [];
    }

    return data.map((item) => ({
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
  } catch (error) {
    console.error('Error in getUserReferrals:', error);
    return [];
  }
}

/**
 * Create a new referral with tags
 */
export async function createReferral(
  userId: string,
  data: {
    title: string;
    description?: string;
    url: string;
    imageUrl?: string;
    subtitle?: string;
    tagNames: string[];
  }
): Promise<ReferralData | null> {
  try {
    // Use RPC function to create referral and tags
    const { data: newReferral, error: rpcError } = await supabase.rpc('create_referral', {
      p_user_id: userId,
      p_title: data.title,
      p_description: data.description || null,
      p_url: data.url,
      p_image_url: data.imageUrl || null,
      p_subtitle: data.subtitle || null,
      p_tag_names: data.tagNames
    });

    if (rpcError) {
      console.error('Error creating referral:', rpcError);
      return null;
    }

    // Get the complete referral with tags using RPC
    const { data: completeReferral, error: fetchError } = await supabase.rpc(
      'get_referral_with_tags',
      { p_referral_id: newReferral.id }
    );

    if (fetchError) {
      console.error('Error fetching complete referral:', fetchError);
      return null;
    }

    return {
      id: completeReferral.id,
      title: completeReferral.title,
      description: completeReferral.description || '',
      url: completeReferral.url,
      imageUrl: completeReferral.image_url || '',
      subtitle: completeReferral.subtitle || '',
      isExpanded: false,
      userId: completeReferral.user_id,
      tags: (completeReferral.referral_tags || [])
        .map(rt => rt.tag)
        .filter(Boolean)
        .sort((a, b) => a.name.localeCompare(b.name))
    };
  } catch (error) {
    console.error('Error in createReferral:', error);
    return null;
  }
}

/**
 * Update an existing referral with tags
 */
export async function updateReferral(
  referralId: string,
  userId: string,
  data: {
    title: string;
    description?: string;
    url: string;
    imageUrl?: string;
    subtitle?: string;
    tagNames: string[];
  }
): Promise<ReferralData | null> {
  try {
    // Use RPC function to update referral and tags
    const { data: updatedReferral, error: rpcError } = await supabase.rpc('update_referral', {
      p_referral_id: referralId,
      p_user_id: userId,
      p_title: data.title,
      p_description: data.description || null,
      p_url: data.url,
      p_image_url: data.imageUrl || null,
      p_subtitle: data.subtitle || null,
      p_tag_names: data.tagNames
    });

    if (rpcError) {
      console.error('Error updating referral:', rpcError);
      return null;
    }

    // Get the complete referral with tags using RPC
    const { data: completeReferral, error: fetchError } = await supabase.rpc(
      'get_referral_with_tags',
      { p_referral_id: referralId }
    );

    if (fetchError) {
      console.error('Error fetching complete referral:', fetchError);
      return null;
    }

    return {
      id: completeReferral.id,
      title: completeReferral.title,
      description: completeReferral.description || '',
      url: completeReferral.url,
      imageUrl: completeReferral.image_url || '',
      subtitle: completeReferral.subtitle || '',
      isExpanded: false,
      userId: completeReferral.user_id,
      tags: (completeReferral.referral_tags || [])
        .map(rt => rt.tag)
        .filter(Boolean)
        .sort((a, b) => a.name.localeCompare(b.name))
    };
  } catch (error) {
    console.error('Error in updateReferral:', error);
    return null;
  }
}

/**
 * Delete a referral
 */
export async function deleteReferral(referralId: string, userId: string): Promise<boolean> {
  try {
    const { error } = await supabase.rpc('delete_referral', {
      p_referral_id: referralId,
      p_user_id: userId
    });

    if (error) {
      console.error('Error deleting referral:', error);
      return false;
    }

    return true;
  } catch (error) {
    console.error('Error in deleteReferral:', error);
    return false;
  }
}
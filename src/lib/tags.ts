import { supabase } from './supabase';
import { Tag } from '../types';

/**
 * Fetch all tags for a user
 */
export async function getUserTags(userId: string): Promise<Tag[]> {
  try {
    const { data, error } = await supabase
      .from('tags')
      .select(`
        id,
        name,
        referral_tags (
          count
        )
      `)
      .eq('user_id', userId)
      .order('name');

    if (error) {
      console.error('Error fetching tags:', error);
      return [];
    }

    return data.map(tag => ({
      id: tag.id,
      name: tag.name,
      usage_count: tag.referral_tags.length
    }));
  } catch (error) {
    console.error('Error in getUserTags:', error);
    return [];
  }
}

/**
 * Delete a tag using RPC function
 */
export async function deleteTag(tagId: string, userId: string): Promise<boolean> {
  try {
    const { data, error } = await supabase
      .rpc('delete_tag', {
        p_tag_id: tagId,
        p_user_id: userId
      });

    if (error) {
      console.error('Error deleting tag:', error);
      return false;
    }

    return data || false;
  } catch (error) {
    console.error('Error in deleteTag:', error);
    return false;
  }
}

/**
 * Add or update a tag
 */
export async function manageTag(
  userId: string,
  tagName: string
): Promise<Tag | null> {
  try {
    const { data, error } = await supabase.rpc('manage_tag', {
      p_name: tagName.toLowerCase(),
      p_user_id: userId
    });

    if (error) {
      console.error('Error managing tag:', error);
      return null;
    }

    return data;
  } catch (error) {
    console.error('Error in manageTag:', error);
    return null;
  }
}
import React, { useState, useEffect } from 'react';
import { Plus, Loader2, AlertCircle, X } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { Tag } from '../types';
import { deleteTag } from '../lib/tags';

interface TagManagementProps {
  userId: string;
  onTagsUpdate?: () => void;
}

const TagManagement: React.FC<TagManagementProps> = ({ userId, onTagsUpdate }) => {
  const [tags, setTags] = useState<(Tag & { referral_count?: number })[]>([]);
  const [newTag, setNewTag] = useState('');
  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  useEffect(() => {
    fetchTags();
  }, [userId]);

  const fetchTags = async () => {
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

      if (error) throw error;

      const tagsWithCount = data.map(tag => ({
        ...tag,
        referral_count: tag.referral_tags.length
      }));

      setTags(tagsWithCount);
    } catch (error) {
      console.error('Error fetching tags:', error);
      setError('Failed to load tags');
    } finally {
      setLoading(false);
    }
  };

  const handleAddTag = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTag.trim() || isSubmitting) return;

    setIsSubmitting(true);
    setError('');

    try {
      const { data, error } = await supabase.rpc('manage_tag', {
        p_name: newTag.toLowerCase(),
        p_user_id: userId
      });

      if (error) throw error;

      setNewTag('');
      await fetchTags();
      
      if (onTagsUpdate) {
        onTagsUpdate();
      }
    } catch (error) {
      console.error('Error adding tag:', error);
      setError('Failed to add tag');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteTag = async (tagId: string) => {
    setIsSubmitting(true);
    setError('');

    try {
      const success = await deleteTag(tagId);

      if (!success) {
        throw new Error('Failed to delete tag');
      }

      setTags(tags.filter(tag => tag.id !== tagId));
      setDeleteConfirm(null);
      
      if (onTagsUpdate) {
        onTagsUpdate();
      }
    } catch (error) {
      console.error('Error deleting tag:', error);
      setError('Failed to delete tag');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center p-8">
        <Loader2 className="w-6 h-6 animate-spin text-primary-light dark:text-primary-dark" />
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto p-4">
      <h2 className="text-2xl font-bold text-text-light dark:text-text-dark mb-6">
        Manage Tags
      </h2>

      {/* Add new tag form */}
      <form onSubmit={handleAddTag} className="mb-8">
        <div className="flex gap-2">
          <input
            type="text"
            value={newTag}
            onChange={(e) => setNewTag(e.target.value)}
            placeholder="Enter new tag name"
            className="flex-1 px-3 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
          />
          <button
            type="submit"
            disabled={isSubmitting || !newTag.trim()}
            className="flex items-center gap-2 px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isSubmitting ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <Plus className="w-4 h-4" />
            )}
            Add Tag
          </button>
        </div>
        {error && (
          <p className="mt-2 text-sm text-red-500 dark:text-red-400 flex items-center gap-1">
            <AlertCircle className="w-4 h-4" />
            {error}
          </p>
        )}
      </form>

      {/* Tags list */}
      <div className="space-y-4">
        {tags.length === 0 ? (
          <p className="text-center text-muted-light dark:text-muted-dark py-8">
            No tags created yet. Add your first tag above.
          </p>
        ) : (
          tags.map((tag) => (
            <div
              key={tag.id}
              className="flex items-center justify-between p-4 bg-card-light dark:bg-card-dark rounded-lg border border-border-light dark:border-border-dark"
            >
              <div>
                <h3 className="text-lg font-medium text-text-light dark:text-text-dark">
                  {tag.name}
                </h3>
                <p className="text-sm text-muted-light dark:text-muted-dark">
                  Used in {tag.referral_count} referral{tag.referral_count !== 1 ? 's' : ''}
                </p>
              </div>

              {deleteConfirm === tag.id ? (
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setDeleteConfirm(null)}
                    className="px-3 py-1 text-sm text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => handleDeleteTag(tag.id)}
                    disabled={isSubmitting}
                    className="px-3 py-1 bg-red-500 text-white rounded-md text-sm hover:bg-red-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-1"
                  >
                    {isSubmitting ? (
                      <Loader2 className="w-3 h-3 animate-spin" />
                    ) : (
                      <>
                        <X className="w-3 h-3" />
                        Confirm
                      </>
                    )}
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setDeleteConfirm(tag.id)}
                  className="text-red-500 hover:text-red-600 p-1 rounded-md transition-colors"
                  title="Delete tag"
                >
                  <X className="w-5 h-5" />
                </button>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default TagManagement;
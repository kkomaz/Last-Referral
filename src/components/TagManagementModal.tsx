import React, { useState, useEffect } from 'react';
import { Plus, Loader2, AlertCircle, X, Crown, AlertTriangle } from 'lucide-react';
import { Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Tag } from '../types';
import toast from 'react-hot-toast';

interface TagManagementModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  onTagsUpdate?: () => void;
  maxTags: number;
}

const TagManagementModal: React.FC<TagManagementModalProps> = ({
  isOpen,
  onClose,
  userId,
  onTagsUpdate,
  maxTags
}) => {
  const [tags, setTags] = useState<(Tag & { referral_count?: number })[]>([]);
  const [newTag, setNewTag] = useState('');
  const [loading, setLoading] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  // Reset states when modal closes
  useEffect(() => {
    if (!isOpen) {
      setDeleteError(null);
      setError('');
      setDeleteConfirm(null);
      setNewTag('');
    }
  }, [isOpen]);

  useEffect(() => {
    if (isOpen) {
      fetchTags();
    }
  }, [isOpen, userId]);

  const fetchTags = async () => {
    try {
      // Get all tags for the user
      const { data: tagsData, error: tagsError } = await supabase
        .from('tags')
        .select('id, name')
        .eq('user_id', userId)
        .order('name');

      if (tagsError) throw tagsError;

      // For each tag, count its actual usage in referral_tags
      const tagsWithCounts = await Promise.all(
        tagsData.map(async (tag) => {
          const { count } = await supabase
            .from('referral_tags')
            .select('*', { count: 'exact' })
            .eq('tag_id', tag.id);

          return {
            ...tag,
            referral_count: count || 0
          };
        })
      );

      console.log('Tags with counts:', tagsWithCounts);
      setTags(tagsWithCounts);
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
    } catch (error: any) {
      console.error('Error adding tag:', error);
      if (error.message.includes('Tag limit reached')) {
        setError('Tag limit reached. Upgrade to premium for more tags.');
      } else {
        setError('Failed to add tag');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteTag = async (tagId: string, referralCount: number) => {
    setIsSubmitting(true);
    setDeleteError(null);

    try {
      // Use the RPC function to delete the tag
      const { data, error } = await supabase.rpc('delete_tag', {
        p_tag_id: tagId,
        p_user_id: userId
      });

      if (error) {
        // Handle specific error messages
        if (error.message.includes('Tag is in use')) {
          setDeleteError(error.message);
        } else {
          throw error;
        }
        return;
      }

      // If deletion was successful, update the UI
      if (data) {
        setTags(tags.filter(tag => tag.id !== tagId));
        setDeleteConfirm(null);
        
        if (onTagsUpdate) {
          onTagsUpdate();
        }

        toast.success('Tag deleted successfully');
      }
    } catch (error) {
      console.error('Error deleting tag:', error);
      setDeleteError('Failed to delete tag');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleClose = () => {
    setDeleteError(null);
    setError('');
    setDeleteConfirm(null);
    setNewTag('');
    onClose();
  };

  if (!isOpen) return null;

  const currentTagCount = tags.length;
  const remainingTags = maxTags - currentTagCount;
  const isAtLimit = remainingTags <= 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={handleClose}
      />
      
      <div className="relative bg-card-light dark:bg-card-dark rounded-lg shadow-xl w-full max-w-2xl mx-4 overflow-hidden">
        <div className="flex justify-between items-center p-4 border-b border-border-light dark:border-border-dark">
          <h2 className="text-xl font-semibold text-text-light dark:text-text-dark">
            Manage Tags
          </h2>
          <button
            onClick={handleClose}
            className="text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6">
          {/* Tag Limit Warning */}
          {remainingTags <= 2 && (
            <div className={`mb-6 p-4 rounded-lg flex items-start gap-3 ${
              isAtLimit 
                ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                : 'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-400'
            }`}>
              <AlertCircle className="shrink-0 mt-0.5" size={20} />
              <div>
                <p className="font-medium">
                  {isAtLimit ? 'Tag limit reached' : 'Approaching tag limit'}
                </p>
                <p className="mt-1 text-sm opacity-90">
                  {isAtLimit
                    ? 'You\'ve reached your maximum number of tags.'
                    : `You can add ${remainingTags} more tag${remainingTags === 1 ? '' : 's'}.`
                  }
                </p>
                <div className="mt-3">
                  <Link
                    to="/admin/subscriptions"
                    className={`inline-flex items-center gap-2 text-sm font-medium ${
                      isAtLimit
                        ? 'text-red-700 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300'
                        : 'text-yellow-700 dark:text-yellow-400 hover:text-yellow-800 dark:hover:text-yellow-300'
                    }`}
                  >
                    <Crown size={16} />
                    <span>Upgrade to Premium</span>
                    <span className="ml-1">→</span>
                  </Link>
                </div>
              </div>
            </div>
          )}

          {/* Delete Error Message */}
          {deleteError && (
            <div className="mb-6 p-4 rounded-lg flex items-start gap-3 bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400">
              <AlertTriangle className="shrink-0 mt-0.5" size={20} />
              <div>
                <p className="font-medium">Unable to Delete Tag</p>
                <p className="mt-1 text-sm">{deleteError}</p>
              </div>
            </div>
          )}

          {/* Add new tag form */}
          <form onSubmit={handleAddTag} className="mb-8">
            <div className="flex gap-2">
              <input
                type="text"
                value={newTag}
                onChange={(e) => setNewTag(e.target.value)}
                placeholder="Enter new tag name"
                className="flex-1 px-3 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
                disabled={isAtLimit}
              />
              <button
                type="submit"
                disabled={isSubmitting || !newTag.trim() || isAtLimit}
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
            {loading ? (
              <div className="flex items-center justify-center p-8">
                <Loader2 className="w-6 h-6 animate-spin text-primary-light dark:text-primary-dark" />
              </div>
            ) : tags.length === 0 ? (
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
                        onClick={() => handleDeleteTag(tag.id, tag.referral_count || 0)}
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
      </div>
    </div>
  );
};

export default TagManagementModal;
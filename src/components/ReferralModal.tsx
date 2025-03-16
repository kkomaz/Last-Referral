import React, { useState, useEffect } from 'react';
import { X, Loader2 } from 'lucide-react';
import TagInput from './TagInput';
import { Tag } from '../types';
import { supabase } from '../lib/supabase';
import toast from 'react-hot-toast';

interface ReferralModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
  userId: string;
  editingReferral?: {
    id: string;
    title: string;
    description: string;
    url: string;
    imageUrl: string;
    subtitle: string;
    tags: Tag[];
  };
}

const ReferralModal: React.FC<ReferralModalProps> = ({
  isOpen,
  onClose,
  onSave,
  userId,
  editingReferral
}) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [url, setUrl] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [subtitle, setSubtitle] = useState('');
  const [selectedTags, setSelectedTags] = useState<Tag[]>([]);
  const [suggestedTags, setSuggestedTags] = useState<Tag[]>([]);
  const [formErrors, setFormErrors] = useState<{ [key: string]: string }>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    if (editingReferral) {
      setTitle(editingReferral.title);
      setDescription(editingReferral.description);
      setUrl(editingReferral.url);
      setImageUrl(editingReferral.imageUrl);
      setSubtitle(editingReferral.subtitle);
      setSelectedTags(editingReferral.tags);
    } else {
      resetForm();
    }
  }, [editingReferral]);

  useEffect(() => {
    const fetchTags = async () => {
      try {
        const { data: tags, error } = await supabase
          .from('tags')
          .select('id, name')
          .eq('user_id', userId)
          .order('name');

        if (error) throw error;
        setSuggestedTags(tags || []);
      } catch (error) {
        console.error('Error fetching tags:', error);
      }
    };

    if (isOpen) {
      fetchTags();
    }
  }, [isOpen, userId]);

  const resetForm = () => {
    setTitle('');
    setDescription('');
    setUrl('');
    setImageUrl('');
    setSubtitle('');
    setSelectedTags([]);
    setFormErrors({});
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const validateForm = () => {
    const errors: { [key: string]: string } = {};

    if (!title.trim()) {
      errors.title = 'Title is required';
    }

    if (!url.trim()) {
      errors.url = 'URL is required';
    } else {
      try {
        new URL(url);
      } catch {
        errors.url = 'Please enter a valid URL';
      }
    }

    if (!selectedTags?.length) {
      errors.tags = 'At least one tag is required';
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validateForm() || isSubmitting) {
      return;
    }

    setIsSubmitting(true);

    try {
      if (editingReferral) {
        const { error } = await supabase.rpc('update_referral', {
          p_referral_id: editingReferral.id,
          p_user_id: userId,
          p_title: title,
          p_description: description || null,
          p_url: url,
          p_image_url: imageUrl || null,
          p_subtitle: subtitle || null,
          p_tag_names: selectedTags.map(t => t.name)
        });

        if (error) throw error;
        toast.success('Referral updated successfully!');
      } else {
        const { error } = await supabase.rpc('create_referral', {
          p_user_id: userId,
          p_title: title,
          p_description: description || null,
          p_url: url,
          p_image_url: imageUrl || null,
          p_subtitle: subtitle || null,
          p_tag_names: selectedTags.map(t => t.name)
        });

        if (error) throw error;
        toast.success('Referral created successfully!');
      }

      onSave();
      handleClose();
    } catch (error) {
      console.error('Error saving referral:', error);
      toast.error('Failed to save referral. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleTagsChange = (tagNames: string[]) => {
    const selectedTags = tagNames.map((name) => {
      const existingTag = suggestedTags.find(
        (t) => t.name.toLowerCase() === name.toLowerCase()
      );
      return existingTag || { id: '', name };
    });

    setSelectedTags(selectedTags);

    if (selectedTags.length > 0) {
      setFormErrors((prev) => ({
        ...prev,
        tags: '',
      }));
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={handleClose}
      />
      
      <div className="relative bg-card-light dark:bg-card-dark rounded-lg shadow-xl w-full max-w-2xl mx-4 overflow-hidden">
        <div className="flex justify-between items-center p-4 border-b border-border-light dark:border-border-dark">
          <h2 className="text-xl font-semibold text-text-light dark:text-text-dark">
            {editingReferral ? 'Edit Referral' : 'Add New Referral'}
          </h2>
          <button
            onClick={handleClose}
            className="text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
          >
            <X size={24} />
          </button>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-text-light dark:text-text-dark mb-1">
                Title *
              </label>
              <input
                type="text"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className={`w-full px-3 py-2 rounded-md border focus:outline-none focus:ring-2 bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark ${
                  formErrors.title
                    ? 'border-red-500 dark:border-red-400 focus:ring-red-500 dark:focus:ring-red-400'
                    : 'border-border-light dark:border-border-dark focus:ring-primary-light dark:focus:ring-primary-dark'
                }`}
                placeholder="Enter title"
              />
              {formErrors.title && (
                <p className="mt-1 text-sm text-red-500 dark:text-red-400">
                  {formErrors.title}
                </p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-text-light dark:text-text-dark mb-1">
                Subtitle
              </label>
              <input
                type="text"
                value={subtitle}
                onChange={(e) => setSubtitle(e.target.value)}
                className="w-full px-3 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
                placeholder="Enter subtitle"
              />
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-text-light dark:text-text-dark mb-1">
                URL *
              </label>
              <input
                type="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                className={`w-full px-3 py-2 rounded-md border focus:outline-none focus:ring-2 bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark ${
                  formErrors.url
                    ? 'border-red-500 dark:border-red-400 focus:ring-red-500 dark:focus:ring-red-400'
                    : 'border-border-light dark:border-border-dark focus:ring-primary-light dark:focus:ring-primary-dark'
                }`}
                placeholder="Enter referral URL"
              />
              {formErrors.url && (
                <p className="mt-1 text-sm text-red-500 dark:text-red-400">
                  {formErrors.url}
                </p>
              )}
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-text-light dark:text-text-dark mb-1">
                Description
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="w-full px-3 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
                rows={3}
                placeholder="Enter description"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-text-light dark:text-text-dark mb-1">
                Image URL
              </label>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                className="w-full px-3 py-2 rounded-md border border-border-light dark:border-border-dark focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark bg-card-light dark:bg-card-dark text-text-light dark:text-text-dark"
                placeholder="Enter image URL"
              />
            </div>

            <div>
              <TagInput
                value={selectedTags.map((tag) => tag.name)}
                onChange={handleTagsChange}
                suggestions={suggestedTags}
                placeholder="Add tags..."
                required
                error={formErrors.tags}
              />
            </div>
          </div>

          <div className="mt-6 flex justify-end gap-3">
            <button
              onClick={handleClose}
              className="px-4 py-2 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark"
              disabled={isSubmitting}
            >
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="flex items-center justify-center gap-2 px-4 py-2 bg-primary-light dark:bg-primary-dark hover:bg-opacity-90 text-white rounded-md transition-colors disabled:opacity-50 disabled:cursor-not-allowed min-w-[120px]"
            >
              {isSubmitting ? (
                <>
                  <Loader2 size={16} className="animate-spin" />
                  <span>Saving...</span>
                </>
              ) : (
                <span>
                  {editingReferral ? 'Update Referral' : 'Add Referral'}
                </span>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReferralModal;
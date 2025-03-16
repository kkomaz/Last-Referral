import React from 'react';
import { X } from 'lucide-react';

interface DeleteConfirmationModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
}

const DeleteConfirmationModal: React.FC<DeleteConfirmationModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Modal */}
      <div className="relative bg-card-light dark:bg-card-dark rounded-lg shadow-xl w-full max-w-md mx-4 overflow-hidden">
        {/* Header */}
        <div className="flex justify-between items-center p-4 border-b border-border-light dark:border-border-dark">
          <h3 className="text-lg font-semibold text-text-light dark:text-text-dark">
            Delete Referral
          </h3>
          <button
            onClick={onClose}
            className="text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
          >
            <X size={20} />
          </button>
        </div>
        
        {/* Content */}
        <div className="p-6">
          <p className="text-text-light dark:text-text-dark mb-6">
            Are you sure you want to delete <span className="font-medium">"{title}"</span>? This action cannot be undone.
          </p>
          
          {/* Actions */}
          <div className="flex justify-end gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-muted-light dark:text-muted-dark hover:text-text-light dark:hover:text-text-dark transition-colors"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              className="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-md transition-colors"
            >
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DeleteConfirmationModal;
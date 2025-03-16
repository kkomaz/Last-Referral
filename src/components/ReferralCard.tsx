import React from 'react';
import { Copy, ExternalLink, ChevronDown, ChevronUp, Edit, Trash2 } from 'lucide-react';
import { ReferralData } from '../types';

interface ReferralCardProps {
  referral: ReferralData;
  onExpand: () => void;
  onCopy: () => void;
  onEdit?: () => void;
  onDelete?: () => void;
  isAuthenticated?: boolean;
  customColors?: {
    primary?: string;
    secondary?: string;
    body?: string;
    card?: string;
  };
}

const ReferralCard: React.FC<ReferralCardProps> = ({
  referral,
  onExpand,
  onCopy,
  onEdit,
  onDelete,
  isAuthenticated = false,
  customColors
}) => {
  const cardStyles = {
    backgroundColor: customColors?.card || '#ffffff',
    borderColor: `${customColors?.primary || '#7b68ee'}33`,
  } as React.CSSProperties;

  const tagStyles = {
    backgroundColor: `${customColors?.primary || '#7b68ee'}1a`,
    color: customColors?.primary || '#7b68ee',
  } as React.CSSProperties;

  const buttonStyles = {
    backgroundColor: customColors?.primary || '#7b68ee',
  } as React.CSSProperties;

  const textStyles = {
    color: customColors?.secondary || '#2b2d42',
  } as React.CSSProperties;

  return (
    <div className="rounded-lg shadow-md overflow-hidden transition-all duration-300 hover:shadow-lg border" style={cardStyles}>
      <div className="flex flex-col">
        {referral.imageUrl && (
          <div className="h-40 overflow-hidden">
            <img 
              src={referral.imageUrl} 
              alt={referral.title} 
              className="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
            />
          </div>
        )}
        
        <div className="p-5 flex-1">
          <div className="flex justify-between items-start gap-4">
            <h3 className="text-xl font-semibold line-clamp-1" style={textStyles}>
              {referral.title}
            </h3>
            {referral.tags && referral.tags.length > 0 && (
              <div className="flex flex-wrap gap-1 shrink-0">
                {referral.tags.map((tag) => (
                  <span 
                    key={tag.id || tag.name}
                    className="text-xs font-medium px-2 py-1 rounded-full whitespace-nowrap"
                    style={tagStyles}
                  >
                    {tag.name}
                  </span>
                ))}
              </div>
            )}
          </div>
          
          {referral.subtitle && (
            <div className="mt-2 text-sm font-medium text-green-500 dark:text-green-400">
              {referral.subtitle}
            </div>
          )}
          
          <p className={`mt-3 text-sm mb-4 ${referral.isExpanded ? '' : 'line-clamp-2'}`} style={textStyles}>
            {referral.description || 'No description provided.'}
          </p>
          
          <div className="flex flex-col gap-3">
            <div className="flex gap-2">
              <button 
                onClick={onCopy}
                className="flex-1 flex items-center justify-center gap-2 text-white py-2 px-3 rounded-md transition-colors text-sm hover:opacity-90"
                style={buttonStyles}
              >
                <Copy size={16} />
                <span>Copy Link</span>
              </button>
              
              <a 
                href={referral.url} 
                target="_blank" 
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-1 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-text-light dark:text-text-dark py-2 px-3 rounded-md transition-colors text-sm"
              >
                <ExternalLink size={16} />
                <span className="sr-only md:not-sr-only">Visit</span>
              </a>
            </div>
            
            <div className="flex justify-between items-center">
              {referral.description && (
                <button 
                  onClick={onExpand}
                  className="flex items-center justify-center gap-1 hover:opacity-80 text-sm font-medium"
                  style={{ color: customColors?.primary || '#7b68ee' }}
                >
                  {referral.isExpanded ? (
                    <>
                      <ChevronUp size={16} />
                      <span>Show Less</span>
                    </>
                  ) : (
                    <>
                      <ChevronDown size={16} />
                      <span>Show More</span>
                    </>
                  )}
                </button>
              )}
              
              {isAuthenticated && (
                <div className="flex gap-2">
                  <button 
                    onClick={onEdit}
                    className="text-muted-light dark:text-muted-dark hover:text-primary-light dark:hover:text-primary-dark p-1"
                    aria-label="Edit referral"
                  >
                    <Edit size={16} />
                  </button>
                  <button 
                    onClick={onDelete}
                    className="text-muted-light dark:text-muted-dark hover:text-red-500 dark:hover:text-red-400 p-1"
                    aria-label="Delete referral"
                  >
                    <Trash2 size={16} />
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReferralCard;
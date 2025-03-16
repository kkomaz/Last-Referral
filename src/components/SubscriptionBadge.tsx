import React from 'react';
import { Crown } from 'lucide-react';

interface SubscriptionBadgeProps {
  tier: 'basic' | 'premium';
  className?: string;
}

const SubscriptionBadge: React.FC<SubscriptionBadgeProps> = ({ tier, className = '' }) => {
  console.log(tier, '::tier');
  if (tier === 'basic') {
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-800 rounded-full ${className}`}>
        Basic
      </span>
    );
  }

  return (
    <span className={`inline-flex items-center gap-1 px-2 py-1 text-xs font-medium text-yellow-600 dark:text-yellow-400 bg-yellow-100 dark:bg-yellow-900/30 rounded-full ${className}`}>
      <Crown size={12} className="text-yellow-600 dark:text-yellow-400" />
      Premium
    </span>
  );
};

export default SubscriptionBadge;
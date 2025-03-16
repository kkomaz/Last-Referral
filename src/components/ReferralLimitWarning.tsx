import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Link } from 'react-router-dom';

interface ReferralLimitWarningProps {
  current: number;
  max: number;
}

const ReferralLimitWarning: React.FC<ReferralLimitWarningProps> = ({ current, max }) => {
  const remaining = max - current;
  const isNearLimit = remaining <= 2;
  const isAtLimit = remaining <= 0;

  if (!isNearLimit) return null;

  return (
    <div className={`rounded-lg p-4 mb-6 flex items-start gap-3 ${
      isAtLimit 
        ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
        : 'bg-yellow-50 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-400'
    }`}>
      <AlertTriangle className="shrink-0 mt-0.5" size={20} />
      <div className="flex-1">
        <p className="font-medium">
          {isAtLimit ? 'Referral limit reached' : 'Approaching referral limit'}
        </p>
        <p className="mt-1 text-sm opacity-90">
          {isAtLimit
            ? 'You\'ve reached your maximum number of referrals.'
            : `You can add ${remaining} more referral${remaining === 1 ? '' : 's'}.`
        }
        </p>
        <div className="mt-3">
          <Link
            to="/settings"
            className={`inline-flex items-center text-sm font-medium ${
              isAtLimit
                ? 'text-red-700 dark:text-red-400 hover:text-red-800 dark:hover:text-red-300'
                : 'text-yellow-700 dark:text-yellow-400 hover:text-yellow-800 dark:hover:text-yellow-300'
            }`}
          >
            Upgrade to Premium
            <span className="ml-2">→</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default ReferralLimitWarning;
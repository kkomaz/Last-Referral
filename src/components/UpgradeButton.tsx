import React, { useState } from 'react';
import { Crown, Loader2 } from 'lucide-react';
import { usePrivy } from '@privy-io/react-auth';
import { createCheckoutSession } from '../lib/stripe';
import toast from 'react-hot-toast';

interface UpgradeButtonProps {
  userId: string;
  onSuccess?: () => void;
}

const UpgradeButton: React.FC<UpgradeButtonProps> = ({ userId, onSuccess }) => {
  const [loading, setLoading] = useState(false);
  const { getAccessToken } = usePrivy();

  const handleUpgrade = async () => {
    if (!userId) {
      toast.error('Please log in to upgrade');
      return;
    }

    setLoading(true);
    try {
      // Get Privy token
      const privyToken = await getAccessToken();
      if (!privyToken) {
        throw new Error('Not authenticated');
      }

      const sessionId = await createCheckoutSession(userId, privyToken);

      // Initialize Stripe and redirect to checkout
      const stripe = await import('@stripe/stripe-js').then((m) =>
        m.loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY)
      );
      if (!stripe) {
        throw new Error('Failed to load Stripe');
      }

      const { error } = await stripe.redirectToCheckout({ sessionId });
      if (error) {
        throw error;
      }
    } catch (error) {
      console.error('Error starting upgrade:', error);
      toast.error('Failed to start upgrade process. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleUpgrade}
      disabled={loading}
      className="flex items-center justify-center gap-2 w-full py-3 px-4 bg-primary-light dark:bg-primary-dark text-white rounded-lg hover:bg-opacity-90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
    >
      {loading ? (
        <>
          <Loader2 size={18} className="animate-spin" />
          <span>Processing...</span>
        </>
      ) : (
        <>
          <Crown size={18} />
          <span>Upgrade to Pro</span>
        </>
      )}
    </button>
  );
};

export default UpgradeButton;

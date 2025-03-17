import React, { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { CheckCircle, Loader2, AlertCircle } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface SuccessPageProps {
  userId: string;
}

const SuccessPage: React.FC<SuccessPageProps> = ({ userId }) => {
  const navigate = useNavigate();
  const [processing, setProcessing] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isPremium, setIsPremium] = useState(false);

  useEffect(() => {
    const checkUpgradeStatus = async () => {
      if (!userId) {
        setError('User ID is missing. Please contact support.');
        setProcessing(false);
        return;
      }

      const maxAttempts = 10; // Try for 10 seconds
      const interval = 1000; // Check every 1 second
      let attempts = 0;

      const poll = async () => {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('tier')
          .eq('id', userId)
          .single();

        if (profileError) {
          setError('Error checking upgrade status. Please try again later.');
          setProcessing(false);
          return;
        }

        if (profile.tier === 'premium') {
          setIsPremium(true);
          setProcessing(false);
          setTimeout(() => navigate('/admin'), 2000);
          return;
        }

        attempts++;
        if (attempts >= maxAttempts) {
          setError(
            'Upgrade processing is taking longer than expected. Please check back later.'
          );
          setProcessing(false);
          return;
        }

        setTimeout(poll, interval);
      };

      await poll();
    };

    checkUpgradeStatus();
  }, [userId, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
      <div className="bg-card-light dark:bg-card-dark p-8 rounded-lg shadow-lg text-center max-w-md w-full mx-4">
        <div className="mb-6">
          {processing ? (
            <Loader2
              size={48}
              className="text-primary-light dark:text-primary-dark animate-spin mx-auto"
            />
          ) : error ? (
            <AlertCircle size={48} className="text-red-500 mx-auto" />
          ) : (
            <CheckCircle size={48} className="text-green-500 mx-auto" />
          )}
        </div>

        <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-4">
          {processing
            ? 'Processing Your Upgrade'
            : error
            ? 'Upgrade Issue'
            : 'Upgrade Complete!'}
        </h1>

        <p className="text-muted-light dark:text-muted-dark mb-6">
          {processing
            ? 'Please wait while we process your upgrade...'
            : error
            ? error
            : 'Thank you for upgrading to Premium! You now have access to all premium features.'}
        </p>

        {!processing && !error && (
          <p className="text-sm text-muted-light dark:text-muted-dark">
            Redirecting you to the dashboard...
          </p>
        )}
      </div>
    </div>
  );
};

export default SuccessPage;

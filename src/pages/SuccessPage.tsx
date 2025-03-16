import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { CheckCircle, Loader2 } from 'lucide-react';
import { handlePaymentSuccess } from '../lib/stripe';
import toast from 'react-hot-toast';

interface SuccessPageProps {
  userId: string;
}

const SuccessPage: React.FC<SuccessPageProps> = ({ userId }) => {
  const navigate = useNavigate();
  const [processing, setProcessing] = useState(true);

  useEffect(() => {
    const processPayment = async () => {
      try {
        const success = await handlePaymentSuccess(userId);
        if (success) {
          toast.success('Successfully upgraded to Premium!');
          setTimeout(() => {
            navigate('/admin');
          }, 2000);
        } else {
          throw new Error('Failed to process upgrade');
        }
      } catch (error) {
        console.error('Error processing payment:', error);
        toast.error('Failed to process upgrade. Please contact support.');
      } finally {
        setProcessing(false);
      }
    };

    processPayment();
  }, [userId, navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
      <div className="bg-card-light dark:bg-card-dark p-8 rounded-lg shadow-lg text-center max-w-md w-full mx-4">
        <div className="mb-6">
          {processing ? (
            <Loader2 size={48} className="text-primary-light dark:text-primary-dark animate-spin mx-auto" />
          ) : (
            <CheckCircle size={48} className="text-green-500 mx-auto" />
          )}
        </div>
        
        <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-4">
          {processing ? 'Processing Your Upgrade' : 'Upgrade Complete!'}
        </h1>
        
        <p className="text-muted-light dark:text-muted-dark mb-6">
          {processing 
            ? 'Please wait while we process your upgrade...'
            : 'Thank you for upgrading to Premium! You now have access to all premium features.'}
        </p>
        
        {!processing && (
          <p className="text-sm text-muted-light dark:text-muted-dark">
            Redirecting you to the dashboard...
          </p>
        )}
      </div>
    </div>
  );
};

export default SuccessPage;
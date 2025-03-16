import React from 'react';
import { XCircle } from 'lucide-react';
import { Link } from 'react-router-dom';

const CancelPage: React.FC = () => {
  return (
    <div className="min-h-screen flex items-center justify-center bg-background-light dark:bg-background-dark">
      <div className="bg-card-light dark:bg-card-dark p-8 rounded-lg shadow-lg text-center max-w-md w-full mx-4">
        <XCircle size={48} className="text-red-500 mx-auto mb-6" />
        
        <h1 className="text-2xl font-bold text-text-light dark:text-text-dark mb-4">
          Payment Cancelled
        </h1>
        
        <p className="text-muted-light dark:text-muted-dark mb-6">
          Your upgrade process was cancelled. No payment has been processed.
        </p>
        
        <Link
          to="/admin"
          className="inline-block px-6 py-3 bg-primary-light dark:bg-primary-dark text-white rounded-lg hover:bg-opacity-90 transition-colors"
        >
          Return to Dashboard
        </Link>
      </div>
    </div>
  );
};

export default CancelPage;
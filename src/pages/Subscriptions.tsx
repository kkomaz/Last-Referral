import React, { useState } from 'react';
import { Check, X, Crown } from 'lucide-react';
import UpgradeButton from '../components/UpgradeButton';
import { UserProfile } from '../types';

interface SubscriptionsProps {
  currentUser: UserProfile;
}

const Subscriptions: React.FC<SubscriptionsProps> = ({ currentUser }) => {
  const [isAnnual, setIsAnnual] = useState(false);

  const plans = [
    {
      name: 'Free',
      price: 0,
      features: [
        { name: 'Up to 10 referral links', included: true },
        { name: 'Basic analytics', included: true },
        { name: 'Public profile', included: true },
        { name: 'Custom tags', included: true },
        { name: 'Priority support', included: false },
        { name: 'Custom branding', included: false },
        { name: 'Advanced analytics', included: false },
        { name: 'API access', included: false },
      ],
      buttonText: 'Current Plan',
      isPopular: false,
    },
    {
      name: 'Pro',
      price: isAnnual ? 99 : 9.97,
      features: [
        { name: 'Unlimited referral links', included: true },
        { name: 'Advanced analytics', included: true },
        { name: 'Public profile', included: true },
        { name: 'Custom tags', included: true },
        { name: 'Priority support', included: true },
        { name: 'Custom branding', included: true },
        { name: 'API access', included: true },
        { name: 'Early access to new features', included: true },
      ],
      buttonText: 'Upgrade to Pro',
      isPopular: true,
    },
  ];

  return (
    <div className="p-6 max-w-6xl mx-auto">
      <div className="text-center mb-12">
        <h2 className="text-3xl font-bold text-text-light dark:text-text-dark mb-4">
          Simple, transparent pricing
        </h2>
        <p className="text-muted-light dark:text-muted-dark max-w-2xl mx-auto">
          Get started for free and upgrade when you need more features. All plans include basic features to help you grow your referral network.
        </p>
      </div>

      {/* Billing Toggle */}
      <div className="flex justify-center items-center gap-3 mb-8">
        <span className={`text-sm ${!isAnnual ? 'text-text-light dark:text-text-dark font-medium' : 'text-muted-light dark:text-muted-dark'}`}>
          Monthly billing
        </span>
        <button
          onClick={() => setIsAnnual(!isAnnual)}
          className="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary-light dark:focus:ring-primary-dark focus:ring-offset-2"
          style={{ backgroundColor: isAnnual ? '#7b68ee' : '#64748b' }}
        >
          <span
            className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
              isAnnual ? 'translate-x-6' : 'translate-x-1'
            }`}
          />
        </button>
        <span className={`text-sm ${isAnnual ? 'text-text-light dark:text-text-dark font-medium' : 'text-muted-light dark:text-muted-dark'}`}>
          Annual billing
          <span className="ml-1.5 text-primary-light dark:text-primary-dark">Save 17%</span>
        </span>
      </div>

      {/* Pricing Cards */}
      <div className="grid md:grid-cols-2 gap-8">
        {plans.map((plan) => (
          <div
            key={plan.name}
            className={`relative rounded-2xl bg-card-light dark:bg-card-dark border ${
              plan.isPopular
                ? 'border-primary-light dark:border-primary-dark shadow-lg'
                : 'border-border-light dark:border-border-dark'
            } p-8`}
          >
            {plan.isPopular && (
              <div className="absolute -top-4 left-1/2 -translate-x-1/2">
                <span className="bg-primary-light dark:bg-primary-dark text-white text-sm font-medium px-3 py-1 rounded-full">
                  Most Popular
                </span>
              </div>
            )}

            <div className="mb-6">
              <h3 className="text-xl font-bold text-text-light dark:text-text-dark">{plan.name}</h3>
              <div className="mt-4 flex items-baseline">
                <span className="text-4xl font-bold text-text-light dark:text-text-dark">
                  ${plan.price}
                </span>
                {plan.price > 0 && (
                  <span className="ml-2 text-muted-light dark:text-muted-dark">
                    /{isAnnual ? 'year' : 'month'}
                  </span>
                )}
              </div>
            </div>

            <ul className="mb-8 space-y-4">
              {plan.features.map((feature, index) => (
                <li key={index} className="flex items-start gap-3">
                  {feature.included ? (
                    <Check className="h-5 w-5 text-green-500 shrink-0" />
                  ) : (
                    <X className="h-5 w-5 text-muted-light dark:text-muted-dark shrink-0" />
                  )}
                  <span className={feature.included ? 'text-text-light dark:text-text-dark' : 'text-muted-light dark:text-muted-dark'}>
                    {feature.name}
                  </span>
                </li>
              ))}
            </ul>

            {plan.isPopular ? (
              <UpgradeButton userId={currentUser.id} />
            ) : (
              <button
                disabled
                className="w-full py-3 px-4 rounded-lg text-center font-medium transition-colors flex items-center justify-center gap-2 bg-background-light dark:bg-background-dark text-text-light dark:text-text-dark cursor-not-allowed"
              >
                <span>{plan.buttonText}</span>
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

export default Subscriptions;
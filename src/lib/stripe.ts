import { loadStripe } from '@stripe/stripe-js';
import { supabase } from './supabase';

// Initialize Stripe
export const getStripe = async () => {
  const stripe = await loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY);
  if (!stripe) {
    throw new Error('Failed to initialize Stripe');
  }
  return stripe;
};

// Create a checkout session
export const createCheckoutSession = async (
  userId: string,
  privyToken: string
) => {
  try {
    if (!privyToken) {
      throw new Error('No Supabase session found');
    }

    console.log(privyToken);

    const response = await fetch(
      `${
        import.meta.env.VITE_SUPABASE_URL
      }/functions/v1/create-checkout-session`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${privyToken}`,
        },
        body: JSON.stringify({
          userId,
          interval: 'month',
        }),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create checkout session: ${errorText}`);
    }

    const { sessionId } = await response.json();
    if (!sessionId) {
      throw new Error('No session ID returned');
    }

    return sessionId;
  } catch (error) {
    console.error('Error creating checkout session:', error);
    throw error;
  }
};

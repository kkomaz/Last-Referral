import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';
import Stripe from 'https://esm.sh/stripe@14.17.0';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Create Supabase admin client with service role key
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') || '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
    );

    // Get the request body
    const { userId, interval = 'month' } = await req.json();

    // Get the user's profile
    const { data: profile, error: profileError } = await supabaseClient
      .from('profiles')
      .select('username, email')
      .eq('id', userId)
      .single();

    if (profileError) {
      throw new Error('Error fetching user profile');
    }

    // Create or retrieve Stripe customer
    let customer;
    const { data: existingProfile } = await supabaseClient
      .from('profiles')
      .select('stripe_customer_id')
      .eq('id', userId)
      .single();

    if (existingProfile?.stripe_customer_id) {
      customer = await stripe.customers.retrieve(
        existingProfile.stripe_customer_id
      );
    } else {
      customer = await stripe.customers.create({
        email: profile.email,
        metadata: {
          supabaseUserId: userId,
          username: profile.username,
        },
      });

      // Store Stripe customer ID in profile
      await supabaseClient
        .from('profiles')
        .update({ stripe_customer_id: customer.id })
        .eq('id', userId);
    }

    // Select price ID based on interval
    const priceId =
      interval === 'year'
        ? Deno.env.get('STRIPE_PREMIUM_YEARLY_PRICE_ID')
        : Deno.env.get('STRIPE_PREMIUM_MONTHLY_PRICE_ID');

    // Create checkout session
    const session = await stripe.checkout.sessions.create({
      customer: customer.id,
      line_items: [
        {
          price: priceId,
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: `${Deno.env.get(
        'SITE_URL'
      )}/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${Deno.env.get('SITE_URL')}/cancel`,
      metadata: {
        userId,
      },
    });

    return new Response(JSON.stringify({ sessionId: session.id }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
      status: 400,
    });
  }
});

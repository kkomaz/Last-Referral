import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.7';
import Stripe from 'https://esm.sh/stripe@14.17.0';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') || '', {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
});

const endpointSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET');

serve(async (req) => {
  try {
    const signature = req.headers.get('stripe-signature');
    if (!signature) {
      return new Response('No signature', { status: 400 });
    }

    const body = await req.text();
    let event;

    try {
      // Use the async method instead of the sync one
      event = await stripe.webhooks.constructEventAsync(
        body,
        signature,
        endpointSecret!
      );
    } catch (err) {
      return new Response(`Webhook Error: ${err.message}`, { status: 400 });
    }

    // Handle the event
    if (event.type === 'checkout.session.completed') {
      const userId = event.data.object.metadata.userId;
      console.log(`Upgrading user: ${userId}`);
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') || '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || ''
      );
      console.log('Supabase client initialized');
      console.log('Updating profile directly');
      const { data, error } = await supabaseClient
        .from('profiles')
        .update({
          tier: 'premium',
          max_referrals: 100,
          max_tags: 50,
          updated_at: new Date(),
        })
        .eq('id', userId)
        .select();
      if (error) {
        console.error(`Update error: ${error.message}`);
        throw new Error(`Update failed: ${error.message}`);
      }
      console.log(`Update success: ${JSON.stringify(data)}`);
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});

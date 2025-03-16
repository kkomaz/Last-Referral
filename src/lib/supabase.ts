import { createClient } from '@supabase/supabase-js';
import { Database } from '../types';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

// Create a single supabase client for interacting with your database
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  global: {
    headers: {
      'X-Client-Info': 'referraltree',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation'  // This ensures we get the updated record back
    }
  },
  db: {
    schema: 'public'
  }
});

// Helper function to decode JWT without external libraries
const decodeJWT = (token: string) => {
  try {
    const base64Url = token.split('.')[1];
    const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    const jsonPayload = decodeURIComponent(
      atob(base64)
        .split('')
        .map(c => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(jsonPayload);
  } catch (error) {
    console.error('Error decoding JWT:', error);
    return null;
  }
};

// Helper function to set Privy authentication for Supabase
export const setPrivyAuthForSupabase = async (privyToken: string) => {
  if (!privyToken) {
    console.warn('No Privy token provided');
    return false;
  }

  try {
    // Decode the token and log the payload
    const decodedToken = decodeJWT(privyToken);
    console.log('Decoded Privy token:', decodedToken);

    // Test the authentication
    const { data: authTest, error: authError } = await supabase
      .from('profiles')
      .select(`
        id,
        privy_id,
        username,
        bio,
        avatar_url,
        primary_color,
        secondary_color,
        body_color,
        card_color,
        twitter,
        instagram,
        linkedin,
        website
      `)
      .limit(1)
      .maybeSingle();
      
    if (authError) {
      console.error('Auth test failed:', authError);
      return false;
    }
    
    console.log('Auth test successful:', authTest);
    return true;
  } catch (error) {
    console.error('Error setting Privy auth for Supabase:', error);
    return false;
  }
};
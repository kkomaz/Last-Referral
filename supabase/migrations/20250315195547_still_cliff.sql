/*
  # Add Stripe customer ID to profiles
  
  1. Changes
    - Add stripe_customer_id column to profiles table
    - Add function to update stripe customer ID
    
  2. Security
    - Maintain existing RLS policies
    - Add column for Stripe integration
*/

-- Add stripe_customer_id column to profiles
ALTER TABLE profiles
ADD COLUMN stripe_customer_id TEXT UNIQUE;

-- Function to update stripe customer ID
CREATE OR REPLACE FUNCTION update_stripe_customer_id(
  p_profile_id UUID,
  p_stripe_customer_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update the profile with the Stripe customer ID
  UPDATE profiles
  SET stripe_customer_id = p_stripe_customer_id
  WHERE id = p_profile_id
  AND privy_id = get_privy_id();

  RETURN FOUND;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_stripe_customer_id TO authenticated, anon;
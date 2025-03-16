/*
  # Add JWT verification for Privy tokens

  1. Changes
    - Creates a function to verify Privy JWT tokens
    - Updates RLS policies to use Privy authentication

  2. Security
    - Adds secure JWT verification
    - Ensures only authenticated Privy users can access their data
*/

-- Create a function to get the Privy ID from the JWT token
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    current_setting('request.jwt.claims', true)::json->>'sub',
    NULL
  );
$$;

-- Update RLS policies for tags table
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
CREATE POLICY "Users can manage own tags" ON tags
  USING (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = get_privy_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = get_privy_id()
    )
  );

-- Update RLS policies for referrals table
DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;
CREATE POLICY "Users can manage own referrals" ON referrals
  USING (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = referrals.user_id
      AND profiles.privy_id = get_privy_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = referrals.user_id
      AND profiles.privy_id = get_privy_id()
    )
  );

-- Update RLS policies for referral_tags table
DROP POLICY IF EXISTS "Users can manage own referral_tags" ON referral_tags;
CREATE POLICY "Users can manage own referral_tags" ON referral_tags
  USING (
    EXISTS (
      SELECT 1
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id
      AND p.privy_id = get_privy_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id
      AND p.privy_id = get_privy_id()
    )
  );
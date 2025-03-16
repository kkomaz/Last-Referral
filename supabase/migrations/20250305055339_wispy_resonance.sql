/*
  # Fix Referral Updates

  1. Changes
    - Drop existing referral policies
    - Create new, more permissive policies for referrals
    - Add debugging function for auth context
    - Add index for faster lookups

  2. Security
    - Maintain RLS protection while allowing legitimate updates
    - Ensure proper user authorization checks
*/

-- Drop existing referral policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Anyone can insert referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete own referrals" ON referrals;
END $$;

-- Create new policies
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can manage referrals"
  ON referrals
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

-- Add index for faster user_id lookups
CREATE INDEX IF NOT EXISTS idx_referrals_user_id ON referrals(user_id);

-- Function to verify referral ownership
CREATE OR REPLACE FUNCTION verify_referral_access(p_referral_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM referrals r
    JOIN profiles p ON p.id = r.user_id
    WHERE r.id = p_referral_id
    AND p.privy_id = auth.uid()::text
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION verify_referral_access TO authenticated, anon;
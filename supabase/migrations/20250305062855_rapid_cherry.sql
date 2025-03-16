/*
  # Fix Referral Policies

  1. Changes
    - Simplify RLS policies for referrals
    - Add more permissive select policy
    - Fix update policy to properly handle Privy authentication

  2. Security
    - Maintain proper authorization checks
    - Enable RLS protection
*/

-- Drop existing referral policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can manage referrals" ON referrals;
END $$;

-- Create new policies
CREATE POLICY "Anyone can view referrals"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update referrals"
  ON referrals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete referrals"
  ON referrals FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );
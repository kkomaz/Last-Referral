/*
  # Fix RLS policies for referrals table

  1. Changes
    - Drop existing RLS policies for referrals table
    - Create new, more permissive policies that work with Privy authentication
    - Add proper checks for user ownership using privy_id
*/

-- Drop existing referral policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can insert referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete referrals" ON referrals;
  DROP POLICY IF EXISTS "Anyone can view referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can manage referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;
END $$;

-- Create new policies
CREATE POLICY "Anyone can view referrals"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own referrals"
  ON referrals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND (
        profiles.privy_id = auth.uid()::text OR
        profiles.id::text = auth.uid()::text
      )
    )
  );

CREATE POLICY "Users can delete own referrals"
  ON referrals FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND (
        profiles.privy_id = auth.uid()::text OR
        profiles.id::text = auth.uid()::text
      )
    )
  );

-- Ensure RLS is enabled
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
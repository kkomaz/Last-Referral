-- Drop existing referrals policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can insert their own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
  DROP POLICY IF EXISTS "Anyone can insert referrals" ON referrals;
END $$;

-- Create new, more permissive policies for referrals
CREATE POLICY "Referrals are viewable by everyone"
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

CREATE POLICY "Users can update own referrals"
  ON referrals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete own referrals"
  ON referrals FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

-- Ensure RLS is enabled
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
-- Drop existing referrals policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can insert referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete own referrals" ON referrals;
END $$;

-- Create new policies with proper authentication checks
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update own referrals"
  ON referrals FOR UPDATE
  USING (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete own referrals"
  ON referrals FOR DELETE
  USING (
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

-- Create helper function to verify referral ownership
CREATE OR REPLACE FUNCTION verify_referral_ownership(referral_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM referrals r
    JOIN profiles p ON p.id = r.user_id
    WHERE r.id = referral_id
    AND p.privy_id = auth.uid()::text
    AND auth.role() = 'authenticated'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION verify_referral_ownership TO authenticated;
-- Drop existing policies
DO $$ 
BEGIN
  -- Drop referrals policies
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can insert their own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
END $$;

-- Create new policies for referrals
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own referrals"
  ON referrals FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = user_id 
      AND (
        privy_id = auth.uid()::text 
        OR 
        id::text = auth.uid()::text
      )
    )
  );

CREATE POLICY "Users can update their own referrals"
  ON referrals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = user_id 
      AND (
        privy_id = auth.uid()::text 
        OR 
        id::text = auth.uid()::text
      )
    )
  );

CREATE POLICY "Users can delete their own referrals"
  ON referrals FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE id = user_id 
      AND (
        privy_id = auth.uid()::text 
        OR 
        id::text = auth.uid()::text
      )
    )
  );

-- Create function to verify user ownership
CREATE OR REPLACE FUNCTION verify_user_owns_referral(referral_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 
    FROM referrals r
    JOIN profiles p ON p.id = r.user_id
    WHERE r.id = referral_id
    AND (
      p.privy_id = auth.uid()::text 
      OR 
      p.id::text = auth.uid()::text
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION verify_user_owns_referral TO authenticated, anon;
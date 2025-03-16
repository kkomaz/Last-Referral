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
      AND (
        profiles.privy_id = auth.uid()::text OR
        profiles.id::text = auth.uid()::text
      )
    )
  );

CREATE POLICY "Users can update own referrals"
  ON referrals FOR UPDATE
  USING (
    auth.role() = 'authenticated' AND
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
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND (
        profiles.privy_id = auth.uid()::text OR
        profiles.id::text = auth.uid()::text
      )
    )
  );

-- Create helper function to check user ownership
CREATE OR REPLACE FUNCTION check_user_owns_profile(profile_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE id = profile_id
    AND (
      privy_id = auth.uid()::text OR
      id::text = auth.uid()::text
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION check_user_owns_profile TO authenticated;
-- Drop existing referral policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Anyone can view referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can insert referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete own referrals" ON referrals;
END $$;

-- Create new, more permissive policies
CREATE POLICY "Anyone can view referrals"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update referrals"
  ON referrals FOR UPDATE
  USING (true);

CREATE POLICY "Anyone can delete referrals"
  ON referrals FOR DELETE
  USING (true);

-- Ensure RLS is enabled
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
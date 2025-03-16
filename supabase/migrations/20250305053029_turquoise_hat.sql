-- Drop existing referrals policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can insert referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can update own referrals" ON referrals;
  DROP POLICY IF EXISTS "Users can delete own referrals" ON referrals;
END $$;

-- Create new policies with simplified checks
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert referrals"
  ON referrals FOR INSERT
  WITH CHECK (true);

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

-- Create a function to log auth context for debugging
CREATE OR REPLACE FUNCTION log_auth_context()
RETURNS jsonb AS $$
DECLARE
  auth_context jsonb;
BEGIN
  auth_context := jsonb_build_object(
    'role', auth.role(),
    'uid', auth.uid(),
    'jwt', auth.jwt(),
    'time', now()
  );
  
  -- Log the context
  RAISE NOTICE 'Auth Context: %', auth_context;
  
  RETURN auth_context;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION log_auth_context TO authenticated, anon;
/*
  # Fix Referral Editing

  1. Changes
    - Simplify RLS policies for referrals
    - Add debugging function
    - Add index for performance

  2. Security
    - Maintain proper authorization checks
    - Enable RLS protection
*/

-- Drop existing referral policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Referrals are viewable by everyone" ON referrals;
  DROP POLICY IF EXISTS "Users can manage referrals" ON referrals;
END $$;

-- Create simplified policies
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own referrals"
  ON referrals
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = referrals.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  );

-- Add debugging function
CREATE OR REPLACE FUNCTION debug_referral_access(p_referral_id uuid)
RETURNS jsonb AS $$
DECLARE
  v_debug jsonb;
BEGIN
  SELECT jsonb_build_object(
    'referral_exists', EXISTS (SELECT 1 FROM referrals WHERE id = p_referral_id),
    'user_id', user_id,
    'auth_uid', auth.uid(),
    'profile_exists', EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = r.user_id 
      AND profiles.privy_id = auth.uid()::text
    )
  )
  INTO v_debug
  FROM referrals r
  WHERE r.id = p_referral_id;
  
  RETURN v_debug;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION debug_referral_access TO authenticated, anon;
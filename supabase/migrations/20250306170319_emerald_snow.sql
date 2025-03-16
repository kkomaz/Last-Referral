/*
  # Update RLS policies to use privy_id

  1. Changes
    - Update all RLS policies to use privy_id instead of auth.uid()
    - Ensure consistent access control across all tables
    
  2. Security
    - Maintain RLS on all tables
    - Update policies to check against profiles.privy_id
    - Keep existing functionality but with correct authentication check
*/

-- Enable RLS on all tables if not already enabled
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Update profiles policies
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Anyone can view public profiles"
  ON profiles
  FOR SELECT
  TO public
  USING (username IS NOT NULL);

CREATE POLICY "Users can update own profile"
  ON profiles
  FOR UPDATE
  TO public
  USING (privy_id = current_setting('request.jwt.claims')::json->>'sub')
  WITH CHECK (privy_id = current_setting('request.jwt.claims')::json->>'sub');

-- Update referrals policies
DROP POLICY IF EXISTS "Anyone can view referrals" ON referrals;
DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;

CREATE POLICY "Anyone can view referrals"
  ON referrals
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = referrals.user_id 
      AND p.username IS NOT NULL
    )
  );

CREATE POLICY "Users can manage own referrals"
  ON referrals
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = referrals.user_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = referrals.user_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  );

-- Update tags policies
DROP POLICY IF EXISTS "Anyone can read tags" ON tags;
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;

CREATE POLICY "Anyone can read tags"
  ON tags
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM referral_tags rt 
      JOIN referrals r ON r.id = rt.referral_id
      JOIN profiles p ON p.id = r.user_id
      WHERE rt.tag_id = tags.id 
      AND p.username IS NOT NULL
    )
  );

CREATE POLICY "Users can manage own tags"
  ON tags
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = tags.user_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM profiles p 
      WHERE p.id = tags.user_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  );

-- Update referral_tags policies
DROP POLICY IF EXISTS "Anyone can read referral tags" ON referral_tags;
DROP POLICY IF EXISTS "Users can manage referral tags" ON referral_tags;

CREATE POLICY "Anyone can read referral tags"
  ON referral_tags
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id 
      AND p.username IS NOT NULL
    )
  );

CREATE POLICY "Users can manage referral tags"
  ON referral_tags
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id 
      AND p.privy_id = current_setting('request.jwt.claims')::json->>'sub'
    )
  );
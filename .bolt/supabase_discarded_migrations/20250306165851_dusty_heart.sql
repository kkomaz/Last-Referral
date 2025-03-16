/*
  # Fix tag access policies

  1. Changes
    - Add policy to allow reading tags through referral_tags join
    - Update existing policies to handle tag visibility correctly
    
  2. Security
    - Enable RLS on tags table (if not already enabled)
    - Add policies to control tag access
*/

-- Enable RLS on tags table if not already enabled
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Anyone can read tags" ON tags;
DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;

-- Allow reading tags that are associated with referrals
CREATE POLICY "Anyone can read tags"
  ON tags
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 
      FROM referral_tags rt 
      JOIN referrals r ON r.id = rt.referral_id
      WHERE rt.tag_id = tags.id
    )
    OR 
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id 
      AND profiles.privy_id = auth.uid()
    )
  );

-- Allow users to manage their own tags
CREATE POLICY "Users can manage their own tags"
  ON tags
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id 
      AND profiles.privy_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id 
      AND profiles.privy_id = auth.uid()
    )
  );

-- Enable RLS on referral_tags table if not already enabled
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "Anyone can read referral tags" ON referral_tags;
DROP POLICY IF EXISTS "Users can manage their referral tags" ON referral_tags;

-- Allow reading referral_tags
CREATE POLICY "Anyone can read referral tags"
  ON referral_tags
  FOR SELECT
  TO public
  USING (true);

-- Allow users to manage their own referral_tags
CREATE POLICY "Users can manage their referral tags"
  ON referral_tags
  FOR ALL
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id 
      AND p.privy_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id 
      AND p.privy_id = auth.uid()
    )
  );
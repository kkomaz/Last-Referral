/*
  # Fix ReferralTags and Tags Deletion Policies

  1. Changes
    - Enable RLS on referral_tags table
    - Update deletion policies for referral_tags and tags tables
    - Ensure no policy conflicts by dropping existing policies first

  2. Security
    - Enable RLS on referral_tags table
    - Add policies to ensure users can only delete their own tags and referral_tags
*/

-- Enable RLS on referral_tags table if not already enabled
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can delete their referral_tags" ON referral_tags;
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;

-- Add policy for referral_tags deletion
CREATE POLICY "Users can delete their referral_tags"
  ON referral_tags
  FOR DELETE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id
      AND p.id = (
        SELECT id 
        FROM profiles 
        WHERE privy_id = auth.uid()::text
      )
    )
  );

-- Create updated tag deletion policy
CREATE POLICY "Users can delete their own tags"
  ON tags
  FOR DELETE
  TO public
  USING (
    EXISTS (
      SELECT 1
      FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = auth.uid()::text
    )
  );
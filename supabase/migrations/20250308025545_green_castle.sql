/*
  # Add ReferralTags Deletion Policy

  1. Changes
    - Add RLS policy to allow users to delete their referral_tags
    - Ensure RLS is enabled on referral_tags table

  2. Security
    - Enable RLS on referral_tags table
    - Add policy for authenticated users to delete their own referral_tags
*/

-- Enable RLS on referral_tags table
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

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
/*
  # Fix RLS policies for tags table

  1. Security Changes
    - Drop existing policies
    - Add corrected policies using privy_id instead of direct auth.uid() comparison
    - Ensure proper access control through profile relationship

  This migration ensures that:
    - Users can read their own tags by matching auth.uid() with profile.privy_id
    - Users can read tags associated with referrals they have access to
    - Users can only modify their own tags
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their own tags" ON tags;
DROP POLICY IF EXISTS "Users can read tags from accessible referrals" ON tags;
DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;

-- Policy for users to read their own tags
CREATE POLICY "Users can read their own tags"
ON tags
FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()
  )
);

-- Policy for users to read tags from referrals they can view
CREATE POLICY "Users can read tags from accessible referrals"
ON tags
FOR SELECT
TO public
USING (
  id IN (
    SELECT tag_id 
    FROM referral_tags rt
    JOIN referrals r ON r.id = rt.referral_id
    JOIN profiles p ON p.id = r.user_id
    WHERE p.privy_id = auth.uid()
  )
);

-- Policy for users to manage their own tags
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
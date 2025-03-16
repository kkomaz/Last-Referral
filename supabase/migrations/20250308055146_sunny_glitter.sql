/*
  # Fix referrals RLS policies

  1. Changes
    - Drop existing policies on referrals table
    - Create new, more secure policies for referrals
    - Add proper RLS checks using privy_id

  2. Security
    - Enable RLS on referrals table
    - Add policies for SELECT, INSERT, UPDATE, DELETE
    - All policies check user authentication via privy_id
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can update referrals" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals" ON referrals;
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;

-- Enable RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Policy for viewing referrals (public profiles only)
CREATE POLICY "Public can view referrals from public profiles"
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

-- Policy for creating referrals
CREATE POLICY "Users can create referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = (auth.jwt() ->> 'sub')
    AND p.id = referrals.user_id
  )
);

-- Policy for updating referrals
CREATE POLICY "Users can update their own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = (auth.jwt() ->> 'sub')
    AND p.id = referrals.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = (auth.jwt() ->> 'sub')
    AND p.id = referrals.user_id
  )
);

-- Policy for deleting referrals
CREATE POLICY "Users can delete their own referrals"
ON referrals
FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = (auth.jwt() ->> 'sub')
    AND p.id = referrals.user_id
  )
);
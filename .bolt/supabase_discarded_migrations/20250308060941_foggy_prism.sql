/*
  # Update referrals table RLS policies

  1. Changes
    - Remove existing policies
    - Add new policies with proper USING and WITH CHECK clauses
    - Use uid() function to get authenticated user ID

  2. Security
    - Enable RLS on referrals table
    - Add policies for:
      - Public can view referrals from public profiles
      - Users can create their own referrals
      - Users can update their own referrals
      - Users can delete their own referrals
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals" ON referrals;
DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;

-- Recreate policies with proper checks
CREATE POLICY "Public can view referrals from public profiles"
ON referrals
FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = referrals.user_id 
    AND p.username IS NOT NULL
  )
);

CREATE POLICY "Users can create referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = uid()
    AND profiles.id = user_id
  )
);

CREATE POLICY "Users can update their own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = uid()
    AND profiles.id = referrals.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = uid()
    AND profiles.id = user_id
  )
);

CREATE POLICY "Users can delete their own referrals"
ON referrals
FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = uid()
    AND profiles.id = referrals.user_id
  )
);
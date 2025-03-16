/*
  # Update RLS policies for referrals table

  1. Changes
    - Drop existing permissive policies that use 'true' conditions
    - Add new policies that check privy_id from JWT against profiles table
    - Ensure proper authorization for all CRUD operations
    
  2. Security
    - Links JWT authentication with profiles table
    - Ensures users can only manage their own referrals
    - Allows public read access only for referrals from users with public profiles
    - Prevents unauthorized modifications

  3. Policies
    - SELECT: Public can view referrals from users with usernames
    - INSERT: Users can only create referrals for themselves
    - UPDATE: Users can only update their own referrals
    - DELETE: Users can only delete their own referrals
*/

-- Drop existing overly permissive policies
DROP POLICY IF EXISTS "Anyone can delete referrals" ON referrals;
DROP POLICY IF EXISTS "Anyone can insert referrals" ON referrals;
DROP POLICY IF EXISTS "Anyone can update referrals" ON referrals;
DROP POLICY IF EXISTS "Anyone can view referrals" ON referrals;

-- Create new SELECT policy
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

-- Create new INSERT policy
CREATE POLICY "Users can create their own referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = referrals.user_id
  )
);

-- Create new UPDATE policy
CREATE POLICY "Users can update their own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = referrals.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = referrals.user_id
  )
);

-- Create new DELETE policy
CREATE POLICY "Users can delete their own referrals"
ON referrals
FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = referrals.user_id
  )
);

-- Ensure RLS is enabled
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
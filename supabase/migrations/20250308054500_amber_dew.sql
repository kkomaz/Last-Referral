/*
  # Fix RLS policies for referrals table

  1. Changes
    - Fix INSERT policy to use WITH CHECK instead of USING
    - Simplify UPDATE policy to avoid redundant checks
    - Ensure proper user_id validation for new referrals
    - Maintain public read access for referrals from users with usernames
    
  2. Security
    - Links JWT authentication with profiles table
    - Ensures users can only manage their own referrals
    - Allows public read access only for referrals from users with public profiles
    - Prevents unauthorized modifications

  3. Policies
    - SELECT: Public can view referrals from users with usernames
    - INSERT: Users can create referrals with their own user_id
    - UPDATE: Users can only update their own referrals
    - DELETE: Users can only delete their own referrals
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can create their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;

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
CREATE POLICY "Users can create referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  user_id IN (
    SELECT id 
    FROM profiles 
    WHERE privy_id = auth.jwt() ->> 'sub'
  )
);

-- Create new UPDATE policy
CREATE POLICY "Users can update their own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  user_id IN (
    SELECT id 
    FROM profiles 
    WHERE privy_id = auth.jwt() ->> 'sub'
  )
);

-- Create new DELETE policy
CREATE POLICY "Users can delete their own referrals"
ON referrals
FOR DELETE
TO public
USING (
  user_id IN (
    SELECT id 
    FROM profiles 
    WHERE privy_id = auth.jwt() ->> 'sub'
  )
);

-- Ensure RLS is enabled
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
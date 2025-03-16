/*
  # Fix authentication and RLS policies

  1. Changes
    - Update RLS policies for referrals table
    - Add public read access for referrals from public profiles
    - Fix user authentication checks using JWT claims
    - Add proper error handling for edge cases
    
  2. Security
    - Enable RLS on referrals table
    - Ensure users can only manage their own referrals
    - Allow public access to referrals from users with usernames
    - Prevent unauthorized modifications
*/

-- First, drop existing policies to start fresh
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals" ON referrals;
DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;
DROP POLICY IF EXISTS "Anyone can update referrals" ON referrals;

-- Enable RLS
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Public read access for referrals from profiles with usernames
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

-- Users can create referrals for themselves
CREATE POLICY "Users can create referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = user_id
  )
);

-- Users can update their own referrals
CREATE POLICY "Users can update their own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = user_id
  )
);

-- Users can delete their own referrals
CREATE POLICY "Users can delete their own referrals"
ON referrals
FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.privy_id = auth.jwt() ->> 'sub'
    AND p.id = user_id
  )
);
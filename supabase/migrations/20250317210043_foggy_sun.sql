/*
  # Fix public access to referrals
  
  1. Changes
    - Update RLS policies to allow public access to referrals
    - Ensure proper access control while allowing public viewing
    - Fix issue with unauthenticated users not seeing referrals
    
  2. Security
    - Maintain security for modifications (create/update/delete)
    - Allow public read access for referrals from public profiles
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can view referrals" ON referrals;
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;

-- Create new policy for public viewing
CREATE POLICY "Public can view referrals"
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

-- Keep existing policies for authenticated operations
CREATE POLICY "Users can manage own referrals"
ON referrals
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = referrals.user_id
    AND p.privy_id = get_privy_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles p
    WHERE p.id = referrals.user_id
    AND p.privy_id = get_privy_id()
  )
);
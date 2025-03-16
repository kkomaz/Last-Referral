/*
  # Update referrals table RLS policies to use Privy authentication
  
  1. Changes
    - Remove existing policies
    - Add new policies that check user ownership via Privy ID
    - Separate policies for different operations to handle new referrals properly
    
  2. Security
    - Enables row-level security based on Privy authentication
    - Users can only manage their own referrals
    - Public can view referrals from profiles with usernames
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Allow all select" ON referrals;
DROP POLICY IF EXISTS "Allow all insert" ON referrals;
DROP POLICY IF EXISTS "Allow all update" ON referrals;
DROP POLICY IF EXISTS "Allow all delete" ON referrals;
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can manage own referrals" ON referrals;

-- Create new policies using Privy authentication
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

-- For creating new referrals
CREATE POLICY "Users can create referrals"
ON referrals
FOR INSERT
TO public
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = get_privy_id()
    AND profiles.id = user_id
  )
);

-- For updating existing referrals
CREATE POLICY "Users can update own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = get_privy_id()
    AND profiles.id = referrals.user_id
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = get_privy_id()
    AND profiles.id = user_id
  )
);

-- For deleting referrals
CREATE POLICY "Users can delete own referrals"
ON referrals
FOR DELETE
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.privy_id = get_privy_id()
    AND profiles.id = referrals.user_id
  )
);
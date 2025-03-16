/*
  # Update referrals table RLS policies to use Privy authentication
  
  1. Changes
    - Remove existing policies
    - Add new policies that check user ownership via Privy ID
    - Policies cover all CRUD operations
    
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

CREATE POLICY "Users can manage own referrals"
ON referrals
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = referrals.user_id
    AND profiles.privy_id = get_privy_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = referrals.user_id
    AND profiles.privy_id = get_privy_id()
  )
);
/*
  # Update referrals table RLS policies to allow all access

  1. Changes
    - Remove existing restrictive policies
    - Add new policies that allow all operations
    
  2. Security Note
    - These policies allow unrestricted access to the referrals table
    - This is not recommended for production use
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Public can view referrals from public profiles" ON referrals;
DROP POLICY IF EXISTS "Users can create referrals" ON referrals;
DROP POLICY IF EXISTS "Users can delete their own referrals" ON referrals;
DROP POLICY IF EXISTS "Users can update their own referrals" ON referrals;

-- Create new permissive policies
CREATE POLICY "Allow all select"
ON referrals
FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow all insert"
ON referrals
FOR INSERT
TO public
WITH CHECK (true);

CREATE POLICY "Allow all update"
ON referrals
FOR UPDATE
TO public
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all delete"
ON referrals
FOR DELETE
TO public
USING (true);
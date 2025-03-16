/*
  # Integrate Privy Authentication with Supabase

  1. Changes
    - Create function to sync Privy ID with Supabase JWT claims
    - Update RLS policies to use authenticated Privy ID
    - Enable RLS on tags table

  2. Security
    - Users can only manage tags where their Privy ID matches the profile's Privy ID
    - Prevents unauthorized access even if profile ID is known
    - Uses JWT claims for secure authentication
*/

-- First, create a function to extract Privy ID from JWT claims
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS text AS $$
BEGIN
  -- Get the JWT claim containing the Privy ID
  RETURN nullif(current_setting('request.jwt.claims', true)::json->>'sub', '')::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;

-- Create new policies using Privy ID
CREATE POLICY "Users can manage own tags"
ON tags
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = get_privy_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = get_privy_id()
  )
);

-- Ensure RLS is enabled
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
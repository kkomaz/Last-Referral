/*
  # Update RLS policies for Privy ID extraction

  1. Changes
    - Update RLS policies to correctly extract Privy ID from JWT token
    - Add function to parse Privy ID from sub claim
    - Update policies on referrals table

  2. Security
    - Maintains existing security model
    - Updates authentication check to use correct Privy ID format
*/

-- Create function to extract Privy ID from JWT sub claim
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(
      -- Extract the ID part after 'did:privy:'
      REGEXP_REPLACE(
        (current_setting('request.jwt.claims', true)::jsonb ->> 'sub'),
        '^did:privy:',
        ''
      ),
      ''
    ),
    NULL
  );
$$;

-- Update policies on referrals table
DROP POLICY IF EXISTS "Users can update own referrals" ON referrals;

CREATE POLICY "Users can update own referrals"
ON referrals
FOR UPDATE
TO public
USING (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = referrals.user_id
    AND profiles.privy_id = get_privy_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM profiles
    WHERE profiles.id = referrals.user_id
    AND profiles.privy_id = get_privy_id()
  )
);
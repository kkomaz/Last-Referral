/*
  # Update get_privy_id function

  1. Changes
    - Update get_privy_id function to return the complete Privy ID including 'did:privy:' prefix
    - Remove regex stripping since we want to match the full ID format

  2. Security
    - Maintains existing security model
    - Ensures exact matching of Privy IDs
*/

-- Update function to return full Privy ID from JWT sub claim
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS text
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(
      current_setting('request.jwt.claims', true)::jsonb ->> 'sub',
      ''
    ),
    NULL
  );
$$;

-- Recreate the policies to ensure they use the updated function
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

-- Verify the policy is working by checking a sample referral
NOTIFY postgres, 'You can test the policy with this query:';
/*
SELECT get_privy_id() as current_privy_id,
       profiles.privy_id as stored_privy_id,
       referrals.*
FROM referrals
JOIN profiles ON profiles.id = referrals.user_id
WHERE profiles.privy_id = get_privy_id();
*/
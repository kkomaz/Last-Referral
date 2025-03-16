/*
  # Fix RLS policies for tags table with logging

  1. Security Changes
    - Drop existing policies
    - Add corrected policies with explicit logging
    - Add helper function for debugging RLS

  This migration ensures that:
    - Users can read their own tags through proper profile relationship
    - Adds logging to help debug RLS issues
*/

-- Create a function to log RLS checks
CREATE OR REPLACE FUNCTION log_rls_check(operation text, table_name text, user_id text)
RETURNS boolean AS $$
BEGIN
  -- Log the check
  RAISE NOTICE 'RLS Check: Operation=%, Table=%, User=%, AuthUID=%', 
    operation, 
    table_name, 
    user_id, 
    auth.uid();
  RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read their own tags" ON tags;
DROP POLICY IF EXISTS "Users can read tags from accessible referrals" ON tags;
DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;

-- Policy for users to read their own tags
CREATE POLICY "Users can read their own tags"
ON tags
FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()
    AND log_rls_check('SELECT', 'tags', user_id::text)
  )
);

-- Policy for users to read tags from referrals they can view
CREATE POLICY "Users can read tags from accessible referrals"
ON tags
FOR SELECT
TO public
USING (
  EXISTS (
    SELECT 1
    FROM referral_tags rt
    JOIN referrals r ON r.id = rt.referral_id
    JOIN profiles p ON p.id = r.user_id
    WHERE rt.tag_id = tags.id
    AND p.privy_id = auth.uid()
    AND log_rls_check('SELECT', 'referral_tags', r.user_id::text)
  )
);

-- Policy for users to manage their own tags
CREATE POLICY "Users can manage their own tags"
ON tags
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()
    AND log_rls_check('ALL', 'tags', user_id::text)
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()
    AND log_rls_check('CHECK', 'tags', user_id::text)
  )
);
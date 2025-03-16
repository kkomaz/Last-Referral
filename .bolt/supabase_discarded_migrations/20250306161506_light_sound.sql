/*
  # Add RLS policies for tags table

  1. Security Changes
    - Enable RLS on tags table
    - Add policy for users to read their own tags
    - Add policy for users to read tags from referrals they can view
    - Add policy for users to manage their own tags

  This migration ensures that:
    - Users can read their own tags
    - Users can read tags associated with referrals they have access to
    - Users can only modify their own tags
*/

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Policy for users to read their own tags
CREATE POLICY "Users can read their own tags"
ON tags
FOR SELECT
TO public
USING (
  auth.uid() IN (
    SELECT id::text 
    FROM profiles 
    WHERE id = tags.user_id
  )
);

-- Policy for users to read tags from referrals they can view
CREATE POLICY "Users can read tags from accessible referrals"
ON tags
FOR SELECT
TO public
USING (
  id IN (
    SELECT tag_id 
    FROM referral_tags rt
    JOIN referrals r ON r.id = rt.referral_id
    WHERE r.user_id = tags.user_id
  )
);

-- Policy for users to manage their own tags
CREATE POLICY "Users can manage their own tags"
ON tags
FOR ALL
TO public
USING (
  auth.uid() IN (
    SELECT id::text 
    FROM profiles 
    WHERE id = tags.user_id
  )
)
WITH CHECK (
  auth.uid() IN (
    SELECT id::text 
    FROM profiles 
    WHERE id = tags.user_id
  )
);
/*
  # Fix tag table RLS policies

  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new comprehensive policies for tag management
    - Add policies for public viewing of tags
    - Fix authentication using privy_id

  2. Security
    - Users can only manage their own tags
    - Public can view tags associated with public profiles
    - Proper authentication using privy_id from JWT claims
*/

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;
  DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
  DROP POLICY IF EXISTS "Public can view tags" ON tags;
  DROP POLICY IF EXISTS "tag_select_policy" ON tags;
  DROP POLICY IF EXISTS "tag_insert_policy" ON tags;
  DROP POLICY IF EXISTS "tag_update_policy" ON tags;
  DROP POLICY IF EXISTS "tag_delete_policy" ON tags;
END $$;

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "tag_insert_policy" ON tags
FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims'::text, true)::json)->>'sub'
  )
);

CREATE POLICY "tag_select_policy" ON tags
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND (
      -- Allow users to see their own tags
      profiles.privy_id = (current_setting('request.jwt.claims'::text, true)::json)->>'sub'
      OR
      -- Allow public to see tags of public profiles
      profiles.username IS NOT NULL
    )
  )
);

CREATE POLICY "tag_update_policy" ON tags
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims'::text, true)::json)->>'sub'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims'::text, true)::json)->>'sub'
  )
);

CREATE POLICY "tag_delete_policy" ON tags
FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims'::text, true)::json)->>'sub'
  )
);
/*
  # Fix Tag Table RLS Policies

  1. Changes
    - Drop existing policies to avoid conflicts
    - Create new policies for tag management:
      - Users can create and manage their own tags
      - Public can view tags associated with public profiles
    
  2. Security
    - Enable RLS on tags table
    - Add policies to ensure users can only manage their own tags
    - Allow public viewing of tags for public profiles
*/

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can create their own tags" ON tags;
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
DROP POLICY IF EXISTS "Public can view tags" ON tags;
DROP POLICY IF EXISTS "tag_select_policy" ON tags;
DROP POLICY IF EXISTS "tag_insert_policy" ON tags;
DROP POLICY IF EXISTS "tag_update_policy" ON tags;
DROP POLICY IF EXISTS "tag_delete_policy" ON tags;

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Create new policies
CREATE POLICY "Users can manage own tags" ON tags
FOR ALL
USING (
  user_id IN (
    SELECT profiles.id
    FROM profiles
    WHERE profiles.privy_id = auth.uid()::text
  )
)
WITH CHECK (
  user_id IN (
    SELECT profiles.id
    FROM profiles
    WHERE profiles.privy_id = auth.uid()::text
  )
);

-- Allow public to view tags of public profiles
CREATE POLICY "Public can view tags" ON tags
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.username IS NOT NULL
  )
);
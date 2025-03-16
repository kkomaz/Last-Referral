/*
  # Update tag table RLS policies

  1. Changes
    - Drop existing policies safely using IF EXISTS
    - Create new policies only if they don't exist
    - Update RLS policies to use auth.uid() for authentication

  2. Security
    - Users can only manage their own tags
    - Public can view tags associated with public profiles
*/

-- Drop existing policies safely
DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
DROP POLICY IF EXISTS "Public can view tags" ON tags;
DROP POLICY IF EXISTS "tag_select_policy" ON tags;
DROP POLICY IF EXISTS "tag_insert_policy" ON tags;
DROP POLICY IF EXISTS "tag_update_policy" ON tags;
DROP POLICY IF EXISTS "tag_delete_policy" ON tags;
DROP POLICY IF EXISTS "Users can create their own tags" ON tags;

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Create new policies using auth.uid()
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'tags' 
    AND policyname = 'Users can manage own tags'
  ) THEN
    CREATE POLICY "Users can manage own tags" ON tags
    FOR ALL
    USING (
      user_id IN (
        SELECT profiles.id
        FROM profiles
        WHERE profiles.privy_id = (auth.uid())::text
      )
    );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'tags' 
    AND policyname = 'Public can view tags'
  ) THEN
    CREATE POLICY "Public can view tags" ON tags
    FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.id = tags.user_id
        AND profiles.username IS NOT NULL
      )
    );
  END IF;
END $$;
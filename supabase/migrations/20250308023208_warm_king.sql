/*
  # Update tag table RLS policies

  1. Changes
    - Update RLS policies for tags table to use privy_id for authentication
    - Add policies for managing tags (create, read, update, delete)
    - Add policy for public access to tags associated with public profiles

  2. Security
    - Users can only manage their own tags
    - Public can view tags associated with public profiles
    - Authentication handled through privy_id
*/

-- Enable RLS if not already enabled
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE schemaname = 'public' 
    AND tablename = 'tags' 
    AND rowsecurity = true
  ) THEN
    ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  -- Drop policies if they exist
  DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
  DROP POLICY IF EXISTS "Public can view tags" ON tags;
  DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;
  DROP POLICY IF EXISTS "Anyone can read tags" ON tags;
END $$;

-- Create new policies
CREATE POLICY "Users can manage their own tags" ON tags
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims', true)::json)->>'sub'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.privy_id = (current_setting('request.jwt.claims', true)::json)->>'sub'
  )
);

-- Allow public to view tags associated with public profiles
CREATE POLICY "Public can view tags" ON tags
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = tags.user_id
    AND profiles.username IS NOT NULL
  )
);
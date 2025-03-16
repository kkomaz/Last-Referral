/*
  # Update RLS policies for tags table

  1. Security Changes
    - Safely check and create RLS policies if they don't exist
    - Policies to be created (if missing):
      - Users can manage their own tags
      - Public can view tags associated with public profiles

  2. Notes
    - Uses DO blocks to check for existing policies
    - Only creates policies if they don't already exist
    - Maintains existing security model
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

-- Create "Users can manage their own tags" policy if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'tags' 
    AND policyname = 'Users can manage their own tags'
  ) THEN
    CREATE POLICY "Users can manage their own tags" ON tags
      USING (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = tags.user_id
          AND profiles.privy_id = (SELECT COALESCE(
            (current_setting('request.jwt.claims', true)::json)->>'sub',
            (nullif(current_setting('request.jwt.claims', true), '')::json)->>'sub'
          ))
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM profiles
          WHERE profiles.id = tags.user_id
          AND profiles.privy_id = (SELECT COALESCE(
            (current_setting('request.jwt.claims', true)::json)->>'sub',
            (nullif(current_setting('request.jwt.claims', true), '')::json)->>'sub'
          ))
        )
      );
  END IF;
END $$;

-- Create "Public can view tags" policy if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'tags' 
    AND policyname = 'Public can view tags associated with public profiles'
  ) THEN
    CREATE POLICY "Public can view tags associated with public profiles" ON tags
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
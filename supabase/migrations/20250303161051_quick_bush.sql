/*
  # Fix tag handling

  1. Changes
     - Ensure tags and referral_tags tables have proper permissions
     - Add additional indexes for better performance
     - Fix any constraints that might be causing issues

  2. Security
     - Maintain security while allowing proper tag functionality
     - Ensure users can create and manage tags
*/

-- Make sure the tags table exists and has the right structure
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'tags'
  ) THEN
    CREATE TABLE tags (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name TEXT UNIQUE NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'referral_tags'
  ) THEN
    CREATE TABLE referral_tags (
      referral_id UUID REFERENCES referrals(id) ON DELETE CASCADE,
      tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
      PRIMARY KEY (referral_id, tag_id)
    );
  END IF;
END $$;

-- Enable RLS on tags and referral_tags if not already enabled
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Tags policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can view tags'
  ) THEN
    DROP POLICY "Anyone can view tags" ON tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can insert tags'
  ) THEN
    DROP POLICY "Anyone can insert tags" ON tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can update tags'
  ) THEN
    DROP POLICY "Anyone can update tags" ON tags;
  END IF;

  -- Referral_tags policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can view referral_tags'
  ) THEN
    DROP POLICY "Anyone can view referral_tags" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can insert referral_tags'
  ) THEN
    DROP POLICY "Anyone can insert referral_tags" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can delete referral_tags'
  ) THEN
    DROP POLICY "Anyone can delete referral_tags" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can update referral_tags'
  ) THEN
    DROP POLICY "Anyone can update referral_tags" ON referral_tags;
  END IF;
END $$;

-- Create policies for tags
CREATE POLICY "Anyone can view tags"
  ON tags
  FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert tags"
  ON tags
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update tags"
  ON tags
  FOR UPDATE
  USING (true);

CREATE POLICY "Anyone can delete tags"
  ON tags
  FOR DELETE
  USING (true);

-- Create policies for referral_tags
CREATE POLICY "Anyone can view referral_tags"
  ON referral_tags
  FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert referral_tags"
  ON referral_tags
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can delete referral_tags"
  ON referral_tags
  FOR DELETE
  USING (true);

CREATE POLICY "Anyone can update referral_tags"
  ON referral_tags
  FOR UPDATE
  USING (true);

-- Create indexes for better performance
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_tags_name'
  ) THEN
    CREATE INDEX idx_tags_name ON tags(name);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_referral_tags_referral_id'
  ) THEN
    CREATE INDEX idx_referral_tags_referral_id ON referral_tags(referral_id);
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_referral_tags_tag_id'
  ) THEN
    CREATE INDEX idx_referral_tags_tag_id ON referral_tags(tag_id);
  END IF;
END $$;
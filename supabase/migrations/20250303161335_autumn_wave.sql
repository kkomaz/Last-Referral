/*
  # Fix tag handling issues

  1. Changes
     - Add debugging triggers to track tag operations
     - Fix any constraints that might be causing issues with tag insertion
     - Ensure proper cascading of operations between referrals and tags

  2. Security
     - Maintain existing security policies
     - Ensure proper access to tag operations
*/

-- Create a function to log tag operations for debugging
CREATE OR REPLACE FUNCTION log_tag_operation()
RETURNS TRIGGER AS $$
BEGIN
  -- Log the operation to the Postgres logs
  RAISE NOTICE 'Tag operation: % on table % (%, %)', TG_OP, TG_TABLE_NAME, NEW, OLD;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to log tag operations
DO $$ 
BEGIN
  -- Drop existing triggers if they exist
  DROP TRIGGER IF EXISTS log_tag_insert ON tags;
  DROP TRIGGER IF EXISTS log_tag_update ON tags;
  DROP TRIGGER IF EXISTS log_tag_delete ON tags;
  
  DROP TRIGGER IF EXISTS log_referral_tag_insert ON referral_tags;
  DROP TRIGGER IF EXISTS log_referral_tag_update ON referral_tags;
  DROP TRIGGER IF EXISTS log_referral_tag_delete ON referral_tags;
END $$;

-- Create new triggers
CREATE TRIGGER log_tag_insert
  AFTER INSERT ON tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

CREATE TRIGGER log_tag_update
  AFTER UPDATE ON tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

CREATE TRIGGER log_tag_delete
  AFTER DELETE ON tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

CREATE TRIGGER log_referral_tag_insert
  AFTER INSERT ON referral_tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

CREATE TRIGGER log_referral_tag_update
  AFTER UPDATE ON referral_tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

CREATE TRIGGER log_referral_tag_delete
  AFTER DELETE ON referral_tags
  FOR EACH ROW
  EXECUTE FUNCTION log_tag_operation();

-- Create a function to handle tag creation or retrieval
CREATE OR REPLACE FUNCTION get_or_create_tag(tag_name TEXT)
RETURNS UUID AS $$
DECLARE
  tag_id UUID;
BEGIN
  -- First try to get the existing tag
  SELECT id INTO tag_id FROM tags WHERE name = tag_name;
  
  -- If tag doesn't exist, create it
  IF tag_id IS NULL THEN
    INSERT INTO tags (name) VALUES (tag_name) RETURNING id INTO tag_id;
  END IF;
  
  RETURN tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to add tags to a referral
CREATE OR REPLACE FUNCTION add_tags_to_referral(p_referral_id UUID, p_tag_names TEXT[])
RETURNS VOID AS $$
DECLARE
  tag_name TEXT;
  tag_id UUID;
BEGIN
  -- Delete existing tags for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;
  
  -- Add each tag
  FOREACH tag_name IN ARRAY p_tag_names LOOP
    -- Get or create the tag
    tag_id := get_or_create_tag(tag_name);
    
    -- Link the tag to the referral
    BEGIN
      INSERT INTO referral_tags (referral_id, tag_id) VALUES (p_referral_id, tag_id);
    EXCEPTION WHEN unique_violation THEN
      -- Tag already linked to this referral, ignore
      NULL;
    END;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_or_create_tag TO authenticated, anon;
GRANT EXECUTE ON FUNCTION add_tags_to_referral TO authenticated, anon;

-- Ensure the tags table has the correct structure
DO $$ 
BEGIN
  -- Make sure the tags table exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'tags'
  ) THEN
    CREATE TABLE tags (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name TEXT UNIQUE NOT NULL,
      created_at TIMESTAMPTZ DEFAULT now()
    );
    
    -- Enable RLS
    ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
  END IF;
  
  -- Make sure the referral_tags table exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'referral_tags'
  ) THEN
    CREATE TABLE referral_tags (
      referral_id UUID REFERENCES referrals(id) ON DELETE CASCADE,
      tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
      PRIMARY KEY (referral_id, tag_id)
    );
    
    -- Enable RLS
    ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Ensure policies exist for tags and referral_tags
DO $$ 
BEGIN
  -- Tags policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can view tags'
  ) THEN
    CREATE POLICY "Anyone can view tags"
      ON tags
      FOR SELECT
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can insert tags'
  ) THEN
    CREATE POLICY "Anyone can insert tags"
      ON tags
      FOR INSERT
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can update tags'
  ) THEN
    CREATE POLICY "Anyone can update tags"
      ON tags
      FOR UPDATE
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Anyone can delete tags'
  ) THEN
    CREATE POLICY "Anyone can delete tags"
      ON tags
      FOR DELETE
      USING (true);
  END IF;

  -- Referral_tags policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can view referral_tags'
  ) THEN
    CREATE POLICY "Anyone can view referral_tags"
      ON referral_tags
      FOR SELECT
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can insert referral_tags'
  ) THEN
    CREATE POLICY "Anyone can insert referral_tags"
      ON referral_tags
      FOR INSERT
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can delete referral_tags'
  ) THEN
    CREATE POLICY "Anyone can delete referral_tags"
      ON referral_tags
      FOR DELETE
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Anyone can update referral_tags'
  ) THEN
    CREATE POLICY "Anyone can update referral_tags"
      ON referral_tags
      FOR UPDATE
      USING (true);
  END IF;
END $$;
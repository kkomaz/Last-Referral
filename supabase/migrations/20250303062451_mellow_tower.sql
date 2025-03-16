/*
  # Add additional tag-related functionality

  This migration adds additional functionality for tags:
  
  1. Updates
    - Add update policy for tags table
    - Add update policy for referral_tags table
  
  Note: The tables and basic policies were already created in a previous migration.
*/

-- Add update policy for tags
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Authenticated users can update tags'
  ) THEN
    CREATE POLICY "Authenticated users can update tags"
      ON tags
      FOR UPDATE
      USING (auth.role() = 'authenticated');
  END IF;
END $$;

-- Add update policy for referral_tags
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Users can update tags on their own referrals'
  ) THEN
    CREATE POLICY "Users can update tags on their own referrals"
      ON referral_tags
      FOR UPDATE
      USING (
        auth.uid() IN (
          SELECT user_id FROM referrals WHERE id = referral_id
        )
      );
  END IF;
END $$;

-- Add additional indexes if needed
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_tags_name'
  ) THEN
    CREATE INDEX idx_tags_name ON tags(name);
  END IF;
END $$;
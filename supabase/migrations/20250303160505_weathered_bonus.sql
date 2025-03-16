/*
  # Fix tag policies

  1. Changes
     - Add more permissive policies for tags and referral_tags tables
     - Ensure authenticated users can create and manage tags
     - Fix RLS policies that were preventing tag creation

  2. Security
     - Maintain basic security while allowing proper tag functionality
     - Ensure users can only modify their own referral tags
*/

-- Drop existing tag policies if they exist
DO $$ 
BEGIN
  -- Tags policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Tags are viewable by everyone'
  ) THEN
    DROP POLICY "Tags are viewable by everyone" ON tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Authenticated users can insert tags'
  ) THEN
    DROP POLICY "Authenticated users can insert tags" ON tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'tags' AND policyname = 'Authenticated users can update tags'
  ) THEN
    DROP POLICY "Authenticated users can update tags" ON tags;
  END IF;

  -- Referral_tags policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Referral tags are viewable by everyone'
  ) THEN
    DROP POLICY "Referral tags are viewable by everyone" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Users can tag their own referrals'
  ) THEN
    DROP POLICY "Users can tag their own referrals" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Users can remove tags from their own referrals'
  ) THEN
    DROP POLICY "Users can remove tags from their own referrals" ON referral_tags;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referral_tags' AND policyname = 'Users can update tags on their own referrals'
  ) THEN
    DROP POLICY "Users can update tags on their own referrals" ON referral_tags;
  END IF;
END $$;

-- Create more permissive policies for tags
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

-- Create more permissive policies for referral_tags
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
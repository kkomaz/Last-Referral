/*
  # Fix tag policies and permissions

  1. Changes
    - Drop existing policies safely
    - Create new policies for tags and referral_tags
    - Add proper user validation in policies
    - Fix policy naming conflicts

  2. Security
    - Ensure proper RLS for tags
    - Scope tags to user profiles
    - Validate user ownership
*/

-- First drop all existing policies safely
DO $$ 
BEGIN
  -- Drop tag policies if they exist
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view their own tags' AND tablename = 'tags') THEN
    DROP POLICY "Users can view their own tags" ON tags;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert their own tags' AND tablename = 'tags') THEN
    DROP POLICY "Users can insert their own tags" ON tags;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can update their own tags' AND tablename = 'tags') THEN
    DROP POLICY "Users can update their own tags" ON tags;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can delete their own tags' AND tablename = 'tags') THEN
    DROP POLICY "Users can delete their own tags" ON tags;
  END IF;

  -- Drop referral_tags policies if they exist
  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can view referral tags' AND tablename = 'referral_tags') THEN
    DROP POLICY "Users can view referral tags" ON referral_tags;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Users can manage their referral tags' AND tablename = 'referral_tags') THEN
    DROP POLICY "Users can manage their referral tags" ON referral_tags;
  END IF;
END $$;

-- Create new tag policies
CREATE POLICY "tag_select_policy"
  ON tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "tag_insert_policy"
  ON tags FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "tag_update_policy"
  ON tags FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "tag_delete_policy"
  ON tags FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = tags.user_id
      AND profiles.privy_id = auth.uid()::text
    )
  );

-- Create new referral_tags policies
CREATE POLICY "referral_tags_select_policy"
  ON referral_tags FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id
      AND p.privy_id = auth.uid()::text
    )
  );

CREATE POLICY "referral_tags_all_policy"
  ON referral_tags
  USING (
    EXISTS (
      SELECT 1 FROM referrals r
      JOIN profiles p ON p.id = r.user_id
      WHERE r.id = referral_tags.referral_id
      AND p.privy_id = auth.uid()::text
    )
  );
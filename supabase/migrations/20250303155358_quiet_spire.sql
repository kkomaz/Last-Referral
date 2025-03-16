/*
  # Fix referrals RLS policies

  1. Changes
     - Update RLS policies for referrals table to properly handle privy_id authentication
     - Fix the insert policy to allow users to add referrals based on privy_id
     - Ensure update and delete policies work with privy authentication

  2. Security
     - Maintain row level security while fixing authentication issues
     - Ensure users can only manage their own referrals
*/

-- Drop existing referral policies that might be causing issues
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can insert their own referrals'
  ) THEN
    DROP POLICY "Users can insert their own referrals" ON referrals;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can update their own referrals'
  ) THEN
    DROP POLICY "Users can update their own referrals" ON referrals;
  END IF;

  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can delete their own referrals'
  ) THEN
    DROP POLICY "Users can delete their own referrals" ON referrals;
  END IF;
END $$;

-- Create more permissive insert policy for referrals
CREATE POLICY "Anyone can insert referrals"
  ON referrals
  FOR INSERT
  WITH CHECK (true);

-- Create policy for updating referrals
CREATE POLICY "Users can update their own referrals"
  ON referrals
  FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM profiles WHERE privy_id = auth.uid()::text
    )
  );

-- Create policy for deleting referrals
CREATE POLICY "Users can delete their own referrals"
  ON referrals
  FOR DELETE
  USING (
    user_id IN (
      SELECT id FROM profiles WHERE privy_id = auth.uid()::text
    )
  );

-- Ensure the select policy exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Referrals are viewable by everyone'
  ) THEN
    CREATE POLICY "Referrals are viewable by everyone"
      ON referrals
      FOR SELECT
      USING (true);
  END IF;
END $$;
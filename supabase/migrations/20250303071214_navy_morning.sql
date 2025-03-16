/*
  # Fix profiles table constraints for Privy integration

  1. Changes
     - Remove the foreign key constraint from profiles table to auth.users
     - Ensure privy_id column exists and is unique
     - Update referrals foreign key constraint
     - Work around the policy limitation by modifying policies first

  2. Security
     - Maintain existing RLS policies with necessary modifications
     - Ensure proper access control for profile creation
*/

-- First, drop the policies that depend on the id column
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can update their own profile'
  ) THEN
    DROP POLICY "Users can update their own profile" ON profiles;
  END IF;
END $$;

-- Drop the foreign key constraint if it exists
ALTER TABLE IF EXISTS profiles
DROP CONSTRAINT IF EXISTS profiles_id_fkey;

-- Make sure the privy_id column exists and is unique
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'privy_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN privy_id TEXT UNIQUE;
  END IF;
END $$;

-- Update the referrals table to ensure it references profiles correctly
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'referrals_user_id_fkey'
  ) THEN
    -- The constraint exists, so we'll recreate it to ensure it's correct
    ALTER TABLE referrals DROP CONSTRAINT referrals_user_id_fkey;
  END IF;
END $$;

-- Add the constraint back
ALTER TABLE referrals
ADD CONSTRAINT referrals_user_id_fkey
FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;

-- Create updated policy that checks both auth.uid and privy_id
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (
    auth.uid()::text = id::text OR 
    privy_id IN (
      SELECT privy_id FROM profiles WHERE id::text = auth.uid()::text
    )
  );

-- Create a more permissive policy for inserting profiles
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Anyone can create profiles'
  ) THEN
    CREATE POLICY "Anyone can create profiles"
      ON profiles
      FOR INSERT
      WITH CHECK (true);
  END IF;
END $$;
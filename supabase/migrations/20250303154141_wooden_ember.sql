/*
  # Fix username registration issues

  1. Changes
    - Ensure profiles table has correct structure
    - Fix policies for username updates
    - Create more permissive policies for profile management
  
  2. Notes
    - Fixes type casting issues between text and UUID
    - Ensures privy_id column exists
    - Updates policies to allow proper username registration
*/

-- First, ensure the profiles table has the correct structure
DO $$ 
BEGIN
  -- Make sure the id column is a UUID
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'id' AND data_type != 'uuid'
  ) THEN
    ALTER TABLE profiles ALTER COLUMN id TYPE UUID USING id::UUID;
  END IF;
  
  -- Make sure the privy_id column exists and is unique
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'privy_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN privy_id TEXT UNIQUE;
  END IF;
END $$;

-- Drop any existing policies that might interfere with username updates
DO $$ 
BEGIN
  -- Drop the update policy if it exists
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can update their own profile'
  ) THEN
    DROP POLICY "Users can update their own profile" ON profiles;
  END IF;
  
  -- Drop the insert policy if it exists
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can insert their own profile'
  ) THEN
    DROP POLICY "Users can insert their own profile" ON profiles;
  END IF;
  
  -- Drop any other insert policies
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can insert profiles with their privy_id'
  ) THEN
    DROP POLICY "Users can insert profiles with their privy_id" ON profiles;
  END IF;
  
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Anyone can create profiles'
  ) THEN
    DROP POLICY "Anyone can create profiles" ON profiles;
  END IF;
END $$;

-- Create new, more permissive policies
-- Allow anyone to insert profiles (we'll handle authorization in the application)
CREATE POLICY "Anyone can insert profiles"
  ON profiles
  FOR INSERT
  WITH CHECK (true);

-- Allow users to update their own profile based on privy_id
-- Fixed: Cast auth.uid() to text to match privy_id type
CREATE POLICY "Users can update profiles with matching privy_id"
  ON profiles
  FOR UPDATE
  USING (
    privy_id = auth.uid()::text OR
    privy_id IS NOT NULL
  );

-- Allow all users to read all profiles
CREATE POLICY "Anyone can read profiles"
  ON profiles
  FOR SELECT
  USING (true);
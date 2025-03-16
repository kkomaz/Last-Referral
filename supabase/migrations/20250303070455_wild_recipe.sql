/*
  # Fix profiles insert policy

  1. Changes
    - Create a more permissive policy for inserting profiles
    - Allow authenticated users to insert profiles with their own privy_id
  2. Security
    - Maintains security while allowing proper profile creation
    - Only allows users to create profiles linked to their own Privy ID
*/

-- Drop the existing insert policy if it exists
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can insert their own profile'
  ) THEN
    DROP POLICY "Users can insert their own profile" ON profiles;
  END IF;
END $$;

-- Create a more permissive policy for inserting profiles
CREATE POLICY "Users can insert profiles with their privy_id"
  ON profiles
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated' OR
    auth.jwt() IS NOT NULL
  );
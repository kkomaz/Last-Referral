/*
  # Fix Profile Constraints and Add Functions

  1. Changes
    - Add updated_at trigger
    - Add profile management functions
    - Update RLS policies
  
  2. Security
    - Enable RLS on profiles table
    - Add policies for profile access control
    - Functions run with SECURITY DEFINER
*/

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
DROP TRIGGER IF EXISTS set_profiles_updated_at ON profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to get profile by privy_id
CREATE OR REPLACE FUNCTION get_profile_by_privy_id(p_privy_id TEXT)
RETURNS TABLE (
  id uuid,
  privy_id text,
  username text,
  bio text,
  avatar_url text,
  twitter text,
  instagram text,
  linkedin text,
  website text,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT p.*
  FROM profiles p
  WHERE p.privy_id = p_privy_id::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can read own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Anyone can read public profiles" ON profiles;

-- Create new policies
CREATE POLICY "Users can read own profile"
ON profiles
FOR SELECT
TO public
USING (
  privy_id::text = auth.uid()::text
);

CREATE POLICY "Users can update own profile"
ON profiles
FOR UPDATE
TO public
USING (
  privy_id::text = auth.uid()::text
)
WITH CHECK (
  privy_id::text = auth.uid()::text
);

CREATE POLICY "Anyone can read public profiles"
ON profiles
FOR SELECT
TO public
USING (
  username IS NOT NULL
);

-- Function to ensure profile exists
CREATE OR REPLACE FUNCTION ensure_profile_exists(
  p_privy_id TEXT,
  p_username TEXT DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
  v_profile_id uuid;
BEGIN
  -- Check if profile exists
  SELECT id INTO v_profile_id
  FROM profiles
  WHERE privy_id = p_privy_id;

  -- If not, create it
  IF v_profile_id IS NULL THEN
    INSERT INTO profiles (privy_id, username, bio)
    VALUES (
      p_privy_id,
      p_username,
      'Tech enthusiast sharing my favorite products and services.'
    )
    RETURNING id INTO v_profile_id;
  END IF;

  RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
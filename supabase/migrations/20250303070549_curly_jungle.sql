/*
  # Create stored procedure for profile creation

  1. New Functions
    - `create_profile_for_user` - Creates a profile with proper permissions
  2. Security
    - Function runs with security definer to bypass RLS
    - Allows creating profiles through a controlled interface
*/

-- Create a function to create profiles that bypasses RLS
CREATE OR REPLACE FUNCTION create_profile_for_user(
  profile_id UUID,
  privy_user_id TEXT,
  display_name_param TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER -- This makes the function run with the privileges of the creator
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  -- Insert the profile
  INSERT INTO profiles (
    id,
    privy_id,
    username,
    display_name,
    bio,
    avatar_url,
    created_at
  ) VALUES (
    profile_id,
    privy_user_id,
    '', -- Empty username to be set later
    display_name_param,
    'Tech enthusiast sharing my favorite products and services.',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80',
    now()
  )
  RETURNING to_jsonb(profiles.*) INTO result;
  
  RETURN result;
END;
$$;

-- Grant execute permission to the anon and authenticated roles
GRANT EXECUTE ON FUNCTION create_profile_for_user TO anon, authenticated;
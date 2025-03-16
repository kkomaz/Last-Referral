/*
  # Fix update_profile function and add color scheme

  1. Changes
    - Drop existing update_profile functions
    - Create new version with all parameters
    - Add color scheme columns to profiles table
    
  2. Security
    - Maintain SECURITY DEFINER
    - Keep proper authorization checks
    - Preserve existing permissions
*/

-- First drop all existing versions of update_profile
DROP FUNCTION IF EXISTS update_profile(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_profile(UUID, TEXT, TEXT, TEXT, TEXT);

-- Add color scheme columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS primary_color TEXT DEFAULT '#7b68ee',
ADD COLUMN IF NOT EXISTS secondary_color TEXT DEFAULT '#2b2d42';

-- Create the new version of update_profile
CREATE OR REPLACE FUNCTION update_profile(
  p_profile_id UUID,
  p_bio TEXT DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL,
  p_primary_color TEXT DEFAULT NULL,
  p_secondary_color TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_privy_id TEXT;
  v_result JSONB;
BEGIN
  -- Get the Privy ID for the profile
  SELECT privy_id INTO v_privy_id
  FROM profiles
  WHERE id = p_profile_id;

  -- Check authorization
  IF v_privy_id IS NULL OR v_privy_id != get_privy_id() THEN
    RAISE EXCEPTION 'Not authorized to update this profile';
  END IF;

  -- Update the profile
  UPDATE profiles
  SET
    bio = COALESCE(p_bio, bio),
    avatar_url = COALESCE(p_avatar_url, avatar_url),
    primary_color = COALESCE(p_primary_color, primary_color),
    secondary_color = COALESCE(p_secondary_color, secondary_color),
    updated_at = now()
  WHERE id = p_profile_id
  RETURNING jsonb_build_object(
    'id', id,
    'username', username,
    'bio', bio,
    'avatar_url', avatar_url,
    'primary_color', primary_color,
    'secondary_color', secondary_color,
    'twitter', twitter,
    'instagram', instagram,
    'linkedin', linkedin,
    'website', website,
    'updated_at', updated_at
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_profile TO authenticated, anon;
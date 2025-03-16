/*
  # Fix profile update authorization

  1. Changes
    - Update RLS policies for profiles table
    - Fix update_profile RPC function to handle Privy auth correctly
    - Add better error handling and validation
    
  2. Security
    - Ensure proper authorization using Privy ID
    - Maintain existing security model
*/

-- Drop existing update policy if it exists
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

-- Create new update policy
CREATE POLICY "Users can update own profile"
ON profiles
FOR UPDATE
TO public
USING (
  privy_id = get_privy_id()
)
WITH CHECK (
  privy_id = get_privy_id()
);

-- Update the RPC function
CREATE OR REPLACE FUNCTION update_profile(
  p_profile_id UUID,
  p_bio TEXT,
  p_avatar_url TEXT
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
    updated_at = now()
  WHERE id = p_profile_id
  RETURNING jsonb_build_object(
    'id', id,
    'username', username,
    'bio', bio,
    'avatar_url', avatar_url,
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
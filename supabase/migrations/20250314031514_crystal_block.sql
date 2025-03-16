/*
  # Add RPC function for profile updates
  
  1. New Functions
    - update_profile: Updates a user's profile with new bio and avatar URL
    
  2. Security
    - Function runs with SECURITY DEFINER
    - Validates user ownership via privy_id
*/

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
  v_result JSONB;
BEGIN
  -- Verify user owns the profile
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = p_profile_id
    AND privy_id = get_privy_id()
  ) THEN
    RAISE EXCEPTION 'Not authorized to update this profile';
  END IF;

  -- Update the profile
  UPDATE profiles
  SET
    bio = p_bio,
    avatar_url = p_avatar_url,
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
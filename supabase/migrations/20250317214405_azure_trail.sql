/*
  # Fix update_profile_v2 function overloading

  1. Changes
    - Drop both versions of update_profile_v2
    - Create single version that handles all parameters
    - Keep email parameter optional
    
  2. Security
    - Maintain SECURITY DEFINER
    - Keep proper authorization checks
*/

-- Drop both versions of the function
DROP FUNCTION IF EXISTS update_profile_v2(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS update_profile_v2(UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Create single version of the function with all parameters
CREATE OR REPLACE FUNCTION update_profile_v2(
  p_profile_id UUID,
  p_bio TEXT DEFAULT NULL,
  p_avatar_url TEXT DEFAULT NULL,
  p_primary_color TEXT DEFAULT NULL,
  p_secondary_color TEXT DEFAULT NULL,
  p_body_color TEXT DEFAULT NULL,
  p_card_color TEXT DEFAULT NULL,
  p_email TEXT DEFAULT NULL
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
    body_color = COALESCE(p_body_color, body_color),
    card_color = COALESCE(p_card_color, card_color),
    email = COALESCE(p_email, email),
    updated_at = now()
  WHERE id = p_profile_id
  RETURNING jsonb_build_object(
    'id', id,
    'username', username,
    'bio', bio,
    'avatar_url', avatar_url,
    'primary_color', primary_color,
    'secondary_color', secondary_color,
    'body_color', body_color,
    'card_color', card_color,
    'email', email,
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
GRANT EXECUTE ON FUNCTION update_profile_v2 TO authenticated, anon;
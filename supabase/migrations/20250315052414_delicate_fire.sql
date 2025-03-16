/*
  # Add email field to profiles table
  
  1. Changes
    - Add email column to profiles table
    - Add unique constraint on email
    - Add email validation check constraint
    - Update profile update RPC function
    
  2. Security
    - Maintain existing RLS policies
    - Add email format validation
*/

-- Add email column to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS email TEXT;

-- Add check constraint for email format
ALTER TABLE profiles
ADD CONSTRAINT email_format CHECK (
  email IS NULL OR 
  email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
);

-- Add unique constraint for email
ALTER TABLE profiles
ADD CONSTRAINT profiles_email_key UNIQUE (email);

-- Update the RPC function to handle email updates
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
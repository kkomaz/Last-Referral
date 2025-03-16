/*
  # Fix referral RPC functions

  1. Changes
    - Update authorization checks in RPC functions
    - Fix return types and error handling
    - Add better validation
    
  2. Security
    - Maintain proper authorization using Privy ID
    - Ensure users can only manage their own referrals
*/

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS create_referral(uuid, text, text, text, text, text, text[]);
DROP FUNCTION IF EXISTS update_referral(uuid, uuid, text, text, text, text, text, text[]);
DROP FUNCTION IF EXISTS delete_referral(uuid, uuid);
DROP FUNCTION IF EXISTS get_referral_with_tags(uuid);

-- Function to create a new referral with tags
CREATE OR REPLACE FUNCTION create_referral(
  p_user_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_url TEXT,
  p_image_url TEXT,
  p_subtitle TEXT,
  p_tag_names TEXT[]
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_referral_id UUID;
  v_result JSONB;
  v_privy_id TEXT;
BEGIN
  -- Get the Privy ID for the user
  SELECT privy_id INTO v_privy_id
  FROM profiles
  WHERE id = p_user_id;

  -- Verify user exists and has permission
  IF v_privy_id IS NULL OR v_privy_id != get_privy_id() THEN
    RAISE EXCEPTION 'Not authorized to create referral for this user';
  END IF;

  -- Create the referral
  INSERT INTO referrals (
    user_id,
    title,
    description,
    url,
    image_url,
    subtitle
  ) VALUES (
    p_user_id,
    p_title,
    p_description,
    p_url,
    p_image_url,
    p_subtitle
  )
  RETURNING id INTO v_referral_id;

  -- Add tags
  IF p_tag_names IS NOT NULL AND array_length(p_tag_names, 1) > 0 THEN
    PERFORM add_tags_to_referral(v_referral_id, p_tag_names, p_user_id);
  END IF;

  -- Get the complete referral with tags
  SELECT get_referral_with_tags(v_referral_id) INTO v_result;

  RETURN v_result;
END;
$$;

-- Function to update an existing referral with tags
CREATE OR REPLACE FUNCTION update_referral(
  p_referral_id UUID,
  p_user_id UUID,
  p_title TEXT,
  p_description TEXT,
  p_url TEXT,
  p_image_url TEXT,
  p_subtitle TEXT,
  p_tag_names TEXT[]
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
  v_privy_id TEXT;
BEGIN
  -- Get the Privy ID for the user
  SELECT privy_id INTO v_privy_id
  FROM profiles
  WHERE id = p_user_id;

  -- Verify user exists and has permission
  IF v_privy_id IS NULL OR v_privy_id != get_privy_id() THEN
    RAISE EXCEPTION 'Not authorized to update this referral';
  END IF;

  -- Verify referral exists and belongs to user
  IF NOT EXISTS (
    SELECT 1 
    FROM referrals
    WHERE id = p_referral_id
    AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Referral not found or does not belong to user';
  END IF;

  -- Update the referral
  UPDATE referrals
  SET
    title = p_title,
    description = p_description,
    url = p_url,
    image_url = p_image_url,
    subtitle = p_subtitle
  WHERE id = p_referral_id
  AND user_id = p_user_id;

  -- Update tags
  IF p_tag_names IS NOT NULL THEN
    PERFORM add_tags_to_referral(p_referral_id, p_tag_names, p_user_id);
  END IF;

  -- Get the complete referral with tags
  SELECT get_referral_with_tags(p_referral_id) INTO v_result;

  RETURN v_result;
END;
$$;

-- Function to get a referral with its tags
CREATE OR REPLACE FUNCTION get_referral_with_tags(
  p_referral_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Get the referral and its tags
  SELECT jsonb_build_object(
    'id', r.id,
    'user_id', r.user_id,
    'title', r.title,
    'description', r.description,
    'url', r.url,
    'image_url', r.image_url,
    'subtitle', r.subtitle,
    'created_at', r.created_at,
    'referral_tags', COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'tag', jsonb_build_object(
              'id', t.id,
              'name', t.name
            )
          )
        )
        FROM referral_tags rt
        JOIN tags t ON t.id = rt.tag_id
        WHERE rt.referral_id = r.id
      ),
      '[]'::jsonb
    )
  )
  INTO v_result
  FROM referrals r
  WHERE r.id = p_referral_id;

  RETURN v_result;
END;
$$;

-- Function to delete a referral
CREATE OR REPLACE FUNCTION delete_referral(
  p_referral_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_privy_id TEXT;
BEGIN
  -- Get the Privy ID for the user
  SELECT privy_id INTO v_privy_id
  FROM profiles
  WHERE id = p_user_id;

  -- Verify user exists and has permission
  IF v_privy_id IS NULL OR v_privy_id != get_privy_id() THEN
    RAISE EXCEPTION 'Not authorized to delete this referral';
  END IF;

  -- Delete the referral if it belongs to the user
  DELETE FROM referrals
  WHERE id = p_referral_id
  AND user_id = p_user_id;

  -- Return true if a row was deleted
  RETURN FOUND;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_referral TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_referral TO authenticated, anon;
GRANT EXECUTE ON FUNCTION delete_referral TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_referral_with_tags TO authenticated, anon;
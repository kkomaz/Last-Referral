/*
  # Add RPC functions for referral management
  
  1. New Functions
    - create_referral: Creates a new referral with tags
    - update_referral: Updates an existing referral with tags
    - delete_referral: Deletes a referral and its associated tags
    
  2. Security
    - All functions run with SECURITY DEFINER
    - Proper authorization checks included
    - Maintains RLS policies
*/

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
BEGIN
  -- Verify user exists and has permission
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = p_user_id
    AND privy_id = get_privy_id()
  ) THEN
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
  PERFORM add_tags_to_referral(v_referral_id, p_tag_names, p_user_id);

  -- Return the created referral
  SELECT jsonb_build_object(
    'id', r.id,
    'user_id', r.user_id,
    'title', r.title,
    'description', r.description,
    'url', r.url,
    'image_url', r.image_url,
    'subtitle', r.subtitle,
    'created_at', r.created_at
  )
  INTO v_result
  FROM referrals r
  WHERE r.id = v_referral_id;

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
BEGIN
  -- Verify user owns the referral
  IF NOT EXISTS (
    SELECT 1 
    FROM referrals r
    JOIN profiles p ON p.id = r.user_id
    WHERE r.id = p_referral_id
    AND p.id = p_user_id
    AND p.privy_id = get_privy_id()
  ) THEN
    RAISE EXCEPTION 'Not authorized to update this referral';
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
  PERFORM add_tags_to_referral(p_referral_id, p_tag_names, p_user_id);

  -- Return the updated referral
  SELECT jsonb_build_object(
    'id', r.id,
    'user_id', r.user_id,
    'title', r.title,
    'description', r.description,
    'url', r.url,
    'image_url', r.image_url,
    'subtitle', r.subtitle,
    'created_at', r.created_at
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
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify user owns the referral
  IF NOT EXISTS (
    SELECT 1 
    FROM referrals r
    JOIN profiles p ON p.id = r.user_id
    WHERE r.id = p_referral_id
    AND p.id = p_user_id
    AND p.privy_id = get_privy_id()
  ) THEN
    RAISE EXCEPTION 'Not authorized to delete this referral';
  END IF;

  -- Delete the referral (this will cascade to referral_tags)
  DELETE FROM referrals
  WHERE id = p_referral_id
  AND user_id = p_user_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_referral TO authenticated, anon;
GRANT EXECUTE ON FUNCTION update_referral TO authenticated, anon;
GRANT EXECUTE ON FUNCTION delete_referral TO authenticated, anon;
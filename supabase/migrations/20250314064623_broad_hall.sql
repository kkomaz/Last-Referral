/*
  # Add RPC function for tag deletion

  1. Changes
    - Add RPC function for deleting tags
    - Ensure proper authorization checks
    - Handle referral_tags cleanup
    
  2. Security
    - Function runs with SECURITY DEFINER
    - Validates user ownership before deletion
*/

-- Create RPC function for tag deletion
CREATE OR REPLACE FUNCTION delete_tag(
  p_tag_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag_owner_id UUID;
BEGIN
  -- Get the tag's owner
  SELECT user_id INTO v_tag_owner_id
  FROM tags
  WHERE id = p_tag_id;

  -- Check authorization
  IF v_tag_owner_id IS NULL OR v_tag_owner_id != p_user_id THEN
    RETURN false;
  END IF;

  -- Delete the tag (this will cascade to referral_tags due to FK constraint)
  DELETE FROM tags
  WHERE id = p_tag_id
  AND user_id = p_user_id;

  RETURN FOUND;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION delete_tag TO authenticated, anon;
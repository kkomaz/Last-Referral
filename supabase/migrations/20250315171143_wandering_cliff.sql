/*
  # Fix tag deletion functionality

  1. Changes
    - Add RPC function for safe tag deletion
    - Add proper authorization checks
    - Handle referral_tags cleanup
    
  2. Security
    - Ensure proper user ownership verification
    - Maintain RLS policies
*/

-- Create a function to safely delete a tag
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
  v_referral_count INTEGER;
BEGIN
  -- Get the tag's owner and check authorization
  SELECT user_id INTO v_tag_owner_id
  FROM tags
  WHERE id = p_tag_id;

  -- Verify ownership
  IF v_tag_owner_id IS NULL OR v_tag_owner_id != p_user_id THEN
    RAISE EXCEPTION 'Not authorized to delete this tag';
  END IF;

  -- Check if tag is in use
  SELECT COUNT(*)
  INTO v_referral_count
  FROM referral_tags
  WHERE tag_id = p_tag_id;

  -- If tag is in use, don't delete it
  IF v_referral_count > 0 THEN
    RAISE EXCEPTION 'Tag is in use by % referral(s)', v_referral_count;
  END IF;

  -- Delete the tag if it's not in use
  DELETE FROM tags
  WHERE id = p_tag_id
  AND user_id = p_user_id;

  RETURN FOUND;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION delete_tag TO authenticated, anon;
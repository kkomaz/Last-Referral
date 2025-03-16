/*
  # Fix Tag System RPC Function

  1. Changes
    - Fix the add_tags_to_referral RPC function to properly handle tag creation and association
    - Add proper error handling and transaction management
    - Ensure proper user ownership checks

  2. Security
    - Function runs with SECURITY DEFINER to ensure proper access control
    - Validates user ownership before allowing operations
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS add_tags_to_referral(UUID, TEXT[], UUID);

-- Create the improved function
CREATE OR REPLACE FUNCTION add_tags_to_referral(
  p_referral_id UUID,
  p_tag_names TEXT[],
  p_user_id UUID
) RETURNS VOID AS $$
DECLARE
  v_tag_id UUID;
  v_tag_name TEXT;
  v_referral_owner_id UUID;
BEGIN
  -- First verify that the user owns the referral
  SELECT user_id INTO v_referral_owner_id
  FROM referrals
  WHERE id = p_referral_id;

  IF v_referral_owner_id IS NULL THEN
    RAISE EXCEPTION 'Referral not found';
  END IF;

  IF v_referral_owner_id != p_user_id THEN
    RAISE EXCEPTION 'Not authorized to modify this referral''s tags';
  END IF;

  -- Delete existing tag associations for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;
  
  -- Process each tag name
  FOREACH v_tag_name IN ARRAY p_tag_names
  LOOP
    -- Try to find existing tag for this user
    SELECT id INTO v_tag_id
    FROM tags
    WHERE user_id = p_user_id AND LOWER(name) = LOWER(v_tag_name);
    
    -- If tag doesn't exist, create it
    IF v_tag_id IS NULL THEN
      INSERT INTO tags (user_id, name)
      VALUES (p_user_id, v_tag_name)
      RETURNING id INTO v_tag_id;
    END IF;
    
    -- Create the association
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, v_tag_id)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
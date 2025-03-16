/*
  # Fix tags function and policies

  1. Changes
    - Drop existing add_tags_to_referral function
    - Create new version with proper user_id handling
    - Update RLS policies for tags table
*/

-- First drop all existing versions of the function
DROP FUNCTION IF EXISTS add_tags_to_referral(uuid, text[]);
DROP FUNCTION IF EXISTS add_tags_to_referral(uuid, text[], uuid);

-- Create the new function
CREATE OR REPLACE FUNCTION add_tags_to_referral(
  p_referral_id uuid,
  p_tag_names text[],
  p_user_id uuid
)
RETURNS void AS $$
DECLARE
  tag_id uuid;
  tag_name text;
  referral_user_id uuid;
BEGIN
  -- Validate inputs
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id cannot be NULL';
  END IF;

  -- Get the user_id of the referral owner to ensure proper authorization
  SELECT user_id INTO referral_user_id
  FROM referrals
  WHERE id = p_referral_id;

  IF referral_user_id IS NULL THEN
    RAISE EXCEPTION 'Referral not found';
  END IF;

  IF referral_user_id != p_user_id THEN
    RAISE EXCEPTION 'User does not own this referral';
  END IF;

  -- Remove existing tags for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;

  -- Process each tag
  FOREACH tag_name IN ARRAY p_tag_names
  LOOP
    -- Skip empty tags
    IF tag_name IS NULL OR tag_name = '' THEN
      CONTINUE;
    END IF;

    -- Try to find existing tag for this user
    SELECT id INTO tag_id
    FROM tags
    WHERE name = tag_name AND user_id = p_user_id;

    -- Create new tag if it doesn't exist
    IF tag_id IS NULL THEN
      INSERT INTO tags (name, user_id)
      VALUES (tag_name, p_user_id)
      RETURNING id INTO tag_id;
    END IF;

    -- Link tag to referral
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, tag_id)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies for tags
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own tags" ON tags;
DROP POLICY IF EXISTS "Users can create their own tags" ON tags;
DROP POLICY IF EXISTS "Users can update their own tags" ON tags;
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;

-- Create new policies
CREATE POLICY "Users can view their own tags"
  ON tags FOR SELECT
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can create their own tags"
  ON tags FOR INSERT
  WITH CHECK (user_id = auth.uid()::uuid);

CREATE POLICY "Users can update their own tags"
  ON tags FOR UPDATE
  USING (user_id = auth.uid()::uuid);

CREATE POLICY "Users can delete their own tags"
  ON tags FOR DELETE
  USING (user_id = auth.uid()::uuid);

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION add_tags_to_referral(uuid, text[], uuid) TO authenticated, anon;
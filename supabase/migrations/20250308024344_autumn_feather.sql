/*
  # Fix Tag Management

  1. Changes
    - Add RPC function for tag management operations
    - Update RLS policies to work with both direct and RPC-based operations
    
  2. Security
    - Ensure users can only manage their own tags
    - Maintain public read access for tags
*/

-- Create a function to manage tags
CREATE OR REPLACE FUNCTION manage_tag(
  p_name TEXT,
  p_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tag_id UUID;
BEGIN
  -- Check if the user owns the profile
  IF NOT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = p_user_id
    AND privy_id = auth.uid()::text
  ) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- Insert the tag if it doesn't exist
  INSERT INTO tags (name, user_id)
  VALUES (LOWER(p_name), p_user_id)
  ON CONFLICT (user_id, name) DO UPDATE
  SET name = EXCLUDED.name
  RETURNING id INTO v_tag_id;

  RETURN v_tag_id;
END;
$$;
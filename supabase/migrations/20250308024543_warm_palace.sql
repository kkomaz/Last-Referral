/*
  # Fix Tag Management Authorization

  1. Changes
    - Update manage_tag function to properly check authorization using auth.uid()
    - Ensure proper error handling and validation
    
  2. Security
    - Verify user owns the profile before allowing tag management
    - Maintain existing RLS policies
*/

-- Drop the existing function if it exists
DROP FUNCTION IF EXISTS manage_tag(p_name TEXT, p_user_id UUID);

-- Create the updated function with proper auth checks
CREATE OR REPLACE FUNCTION manage_tag(
  p_name TEXT,
  p_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tag_id UUID;
  v_user_privy_id TEXT;
BEGIN
  -- Get the user's privy_id from profiles
  SELECT privy_id INTO v_user_privy_id
  FROM profiles
  WHERE id = p_user_id;

  -- Check if the user exists and owns the profile
  IF v_user_privy_id IS NULL OR v_user_privy_id != auth.uid()::text THEN
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
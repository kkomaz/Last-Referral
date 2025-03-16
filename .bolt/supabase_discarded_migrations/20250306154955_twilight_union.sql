/*
  # Add enforce_tag_limits function

  1. New Functions
    - `enforce_tag_limits`: Enforces maximum tag limits per user
      - Checks user's max_tags limit from profiles table
      - Counts existing tags
      - Prevents creation if limit would be exceeded

  2. Changes
    - Creates a new trigger function
    - Adds error handling and validation
*/

CREATE OR REPLACE FUNCTION enforce_tag_limits()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  tag_count integer;
  max_allowed integer;
BEGIN
  -- Get the user's max_tags limit from profiles
  SELECT max_tags INTO max_allowed
  FROM profiles
  WHERE id = NEW.user_id;

  -- If max_tags is null, use default of 50
  IF max_allowed IS NULL THEN
    max_allowed := 50;
  END IF;

  -- Count existing tags for this user
  SELECT COUNT(*) INTO tag_count
  FROM tags
  WHERE user_id = NEW.user_id;

  -- Check if adding a new tag would exceed the limit
  IF tag_count >= max_allowed THEN
    RAISE EXCEPTION 'Tag limit of % exceeded for user', max_allowed;
  END IF;

  RETURN NEW;
END;
$$;
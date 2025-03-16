/*
  # Remove max tags functionality

  1. Changes
    - Remove max_tags column from profiles table
    - Drop enforce_tag_limits trigger from tags table
    - Drop enforce_tag_limits function
*/

-- Remove max_tags column from profiles
ALTER TABLE profiles DROP COLUMN IF EXISTS max_tags;

-- Drop the trigger from tags table
DROP TRIGGER IF EXISTS enforce_tag_limits_trigger ON tags;

-- Drop the function
DROP FUNCTION IF EXISTS enforce_tag_limits;
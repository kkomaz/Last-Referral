/*
  # Remove display_name column from profiles table

  1. Changes
    - Remove the display_name column from the profiles table
    - Update any references to display_name in the application code
  
  2. Notes
    - This migration completes the transition to using username consistently throughout the application
    - The application code has already been updated to use username instead of displayName
*/

-- Check if the display_name column exists before attempting to drop it
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'display_name'
  ) THEN
    -- Drop the display_name column
    ALTER TABLE profiles DROP COLUMN display_name;
  END IF;
END $$;
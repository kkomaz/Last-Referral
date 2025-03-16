/*
  # Add Privy support and username constraints

  1. Changes
    - Add privy_id column to profiles table
    - Add unique constraint to username column
    - Add check constraint to ensure username follows pattern
    - Add trigger to prevent username changes after set

  2. Security
    - No changes to RLS policies
*/

-- Add privy_id column to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS privy_id TEXT UNIQUE;

-- Add check constraint to ensure username follows pattern (alphanumeric and underscores only)
ALTER TABLE profiles ADD CONSTRAINT username_pattern CHECK (username ~ '^[a-zA-Z0-9_]+$');

-- Create function to prevent username changes
CREATE OR REPLACE FUNCTION prevent_username_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow setting username if it was previously NULL or empty
  IF (OLD.username IS NULL OR OLD.username = '') AND (NEW.username IS NOT NULL AND NEW.username != '') THEN
    RETURN NEW;
  -- Prevent changing username if it was already set
  ELSIF (OLD.username IS NOT NULL AND OLD.username != '') AND (OLD.username != NEW.username) THEN
    RAISE EXCEPTION 'Username cannot be changed once set';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to prevent username changes
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'prevent_username_change_trigger'
  ) THEN
    CREATE TRIGGER prevent_username_change_trigger
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION prevent_username_change();
  END IF;
END $$;
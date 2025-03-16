/*
  # Update tag limits for basic and premium users
  
  1. Changes
    - Set basic users to 5 tags maximum
    - Set premium users to 20 tags maximum
    - Update existing users' limits
    
  2. Security
    - Maintain existing RLS policies
    - Keep existing constraints
*/

-- Add max_tags column if it doesn't exist
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS max_tags INTEGER NOT NULL DEFAULT 5;

-- Update existing users' tag limits based on their tier
UPDATE profiles 
SET max_tags = CASE
  WHEN tier = 'basic' THEN 5
  WHEN tier = 'premium' THEN 20
  ELSE 5
END;

-- Update the upgrade_to_premium function to include the new tag limit
CREATE OR REPLACE FUNCTION upgrade_to_premium(user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Update user tier and limits
  UPDATE profiles
  SET 
    tier = 'premium',
    max_referrals = 100,
    max_tags = 20
  WHERE id = user_id
  RETURNING jsonb_build_object(
    'id', id,
    'tier', tier,
    'max_referrals', max_referrals,
    'max_tags', max_tags
  ) INTO v_result;

  RETURN v_result;
END;
$$;

-- Create function to check tag limits
CREATE OR REPLACE FUNCTION check_tag_limit()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
  max_allowed INTEGER;
BEGIN
  -- Get current tag count and max allowed for user
  SELECT COUNT(*), p.max_tags
  INTO current_count, max_allowed
  FROM tags t
  JOIN profiles p ON p.id = t.user_id
  WHERE t.user_id = NEW.user_id
  GROUP BY p.max_tags;

  -- Check if adding this tag would exceed the limit
  IF current_count >= max_allowed THEN
    RAISE EXCEPTION 'Tag limit reached. Upgrade to premium for more tags.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce tag limits
DROP TRIGGER IF EXISTS enforce_tag_limit ON tags;
CREATE TRIGGER enforce_tag_limit
  BEFORE INSERT ON tags
  FOR EACH ROW
  EXECUTE FUNCTION check_tag_limit();
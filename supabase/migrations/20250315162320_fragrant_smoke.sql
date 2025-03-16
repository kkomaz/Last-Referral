/*
  # Add user tiers and restrictions
  
  1. Changes
    - Add tier column to profiles table
    - Add max_referrals column for tier limits
    - Add check constraint for valid tiers
    
  2. Security
    - Maintain existing RLS policies
    - Add constraints for tier-based limits
*/

-- Add tier and max_referrals columns to profiles
ALTER TABLE profiles
ADD COLUMN tier TEXT NOT NULL DEFAULT 'basic',
ADD COLUMN max_referrals INTEGER NOT NULL DEFAULT 10;

-- Add check constraint for valid tiers
ALTER TABLE profiles
ADD CONSTRAINT valid_tier CHECK (tier IN ('basic', 'premium'));

-- Set tier-specific max_referrals values
UPDATE profiles SET max_referrals = CASE
  WHEN tier = 'basic' THEN 10
  WHEN tier = 'premium' THEN 100
  ELSE 10
END;

-- Create function to check referral limits
CREATE OR REPLACE FUNCTION check_referral_limit()
RETURNS TRIGGER AS $$
DECLARE
  current_count INTEGER;
  max_allowed INTEGER;
BEGIN
  -- Get current referral count and max allowed for user
  SELECT COUNT(*), p.max_referrals
  INTO current_count, max_allowed
  FROM referrals r
  JOIN profiles p ON p.id = r.user_id
  WHERE r.user_id = NEW.user_id
  GROUP BY p.max_referrals;

  -- Check if adding this referral would exceed the limit
  IF current_count >= max_allowed THEN
    RAISE EXCEPTION 'Referral limit reached. Upgrade to premium for more referrals.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce referral limits
DROP TRIGGER IF EXISTS enforce_referral_limit ON referrals;
CREATE TRIGGER enforce_referral_limit
  BEFORE INSERT ON referrals
  FOR EACH ROW
  EXECUTE FUNCTION check_referral_limit();

-- Function to upgrade user to premium
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
    max_referrals = 100
  WHERE id = user_id
  RETURNING jsonb_build_object(
    'id', id,
    'tier', tier,
    'max_referrals', max_referrals
  ) INTO v_result;

  RETURN v_result;
END;
$$;
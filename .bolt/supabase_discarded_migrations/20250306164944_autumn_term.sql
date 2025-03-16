/*
  # Fix tags system

  1. Changes
    - Drop and recreate add_tags_to_referral function with proper error handling
    - Ensure RLS policies are correctly set up
    - Add proper indexes for performance

  2. Security
    - Enable RLS on tags and referral_tags tables
    - Add policies for proper access control
*/

-- Enable RLS
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Create or replace the function to add tags to a referral
CREATE OR REPLACE FUNCTION add_tags_to_referral(
  p_referral_id UUID,
  p_tag_names TEXT[],
  p_user_id UUID
) RETURNS VOID AS $$
DECLARE
  v_tag_id UUID;
  v_tag_name TEXT;
  v_owns_referral BOOLEAN;
BEGIN
  -- Check if the user owns the referral
  SELECT EXISTS (
    SELECT 1 FROM referrals 
    WHERE id = p_referral_id AND user_id = p_user_id
  ) INTO v_owns_referral;

  IF NOT v_owns_referral THEN
    RAISE EXCEPTION 'User does not own this referral';
  END IF;

  -- First, delete existing tag associations for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;
  
  -- Then process each tag name
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

-- Add policies for tags table
DROP POLICY IF EXISTS "Users can manage their own tags" ON tags;
CREATE POLICY "Users can manage their own tags"
ON tags
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()::text
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE profiles.id = tags.user_id 
    AND profiles.privy_id = auth.uid()::text
  )
);

-- Add policies for referral_tags table
DROP POLICY IF EXISTS "Users can manage their referral tags" ON referral_tags;
CREATE POLICY "Users can manage their referral tags"
ON referral_tags
FOR ALL
TO public
USING (
  EXISTS (
    SELECT 1 
    FROM referrals 
    JOIN profiles ON profiles.id = referrals.user_id 
    WHERE referrals.id = referral_tags.referral_id 
    AND profiles.privy_id = auth.uid()::text
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 
    FROM referrals 
    JOIN profiles ON profiles.id = referrals.user_id 
    WHERE referrals.id = referral_tags.referral_id 
    AND profiles.privy_id = auth.uid()::text
  )
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tags_user_id_name ON tags(user_id, name);
CREATE INDEX IF NOT EXISTS idx_referral_tags_referral_id ON referral_tags(referral_id);
CREATE INDEX IF NOT EXISTS idx_referral_tags_tag_id ON referral_tags(tag_id);

-- Function to search user's tags
DROP FUNCTION IF EXISTS search_user_tags(UUID, TEXT, INTEGER);
CREATE FUNCTION search_user_tags(
  p_user_id UUID,
  p_prefix TEXT,
  p_limit INTEGER DEFAULT 10
) RETURNS TABLE (
  id UUID,
  name TEXT,
  usage_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.id,
    t.name,
    COUNT(rt.referral_id)::BIGINT as usage_count
  FROM tags t
  LEFT JOIN referral_tags rt ON rt.tag_id = t.id
  WHERE 
    t.user_id = p_user_id AND
    t.name ILIKE p_prefix || '%'
  GROUP BY t.id, t.name
  ORDER BY usage_count DESC, name
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
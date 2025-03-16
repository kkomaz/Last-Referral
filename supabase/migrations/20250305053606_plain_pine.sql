-- Add tag count limit per user
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS max_tags INTEGER DEFAULT 50;

-- Add function to count user's tags
CREATE OR REPLACE FUNCTION get_user_tag_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT name)
    FROM tags
    WHERE user_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to enforce tag limits when adding new tags
CREATE OR REPLACE FUNCTION enforce_tag_limits()
RETURNS TRIGGER AS $$
DECLARE
  v_max_tags INTEGER;
  v_current_count INTEGER;
BEGIN
  -- Get user's max tag limit
  SELECT max_tags INTO v_max_tags
  FROM profiles
  WHERE id = NEW.user_id;

  -- Get current tag count
  SELECT get_user_tag_count(NEW.user_id) INTO v_current_count;

  -- Check if adding this tag would exceed the limit
  IF v_current_count >= v_max_tags THEN
    RAISE EXCEPTION 'Tag limit of % reached for this user', v_max_tags;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce tag limits
DROP TRIGGER IF EXISTS enforce_tag_limits_trigger ON tags;
CREATE TRIGGER enforce_tag_limits_trigger
  BEFORE INSERT ON tags
  FOR EACH ROW
  EXECUTE FUNCTION enforce_tag_limits();

-- Function to clean up unused tags
CREATE OR REPLACE FUNCTION cleanup_unused_tags(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  -- Delete tags that aren't associated with any referrals
  WITH deleted AS (
    DELETE FROM tags t
    WHERE t.user_id = p_user_id
    AND NOT EXISTS (
      SELECT 1 
      FROM referral_tags rt 
      WHERE rt.tag_id = t.id
    )
    RETURNING *
  )
  SELECT COUNT(*) INTO v_deleted_count FROM deleted;

  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to merge tags
CREATE OR REPLACE FUNCTION merge_tags(
  p_user_id UUID,
  p_source_tag TEXT,
  p_target_tag TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_source_tag_id UUID;
  v_target_tag_id UUID;
BEGIN
  -- Get source and target tag IDs
  SELECT id INTO v_source_tag_id
  FROM tags
  WHERE user_id = p_user_id AND name = p_source_tag;

  SELECT id INTO v_target_tag_id
  FROM tags
  WHERE user_id = p_user_id AND name = p_target_tag;

  -- If either tag doesn't exist, return false
  IF v_source_tag_id IS NULL OR v_target_tag_id IS NULL THEN
    RETURN false;
  END IF;

  -- Update referral_tags to point to target tag
  UPDATE referral_tags
  SET tag_id = v_target_tag_id
  WHERE tag_id = v_source_tag_id;

  -- Delete source tag
  DELETE FROM tags WHERE id = v_source_tag_id;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_user_tag_count TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_unused_tags TO authenticated;
GRANT EXECUTE ON FUNCTION merge_tags TO authenticated;

-- Add index for tag name search
CREATE INDEX IF NOT EXISTS idx_tags_name_user_id ON tags(name, user_id);

-- Add function to search tags by prefix
CREATE OR REPLACE FUNCTION search_user_tags(
  p_user_id UUID,
  p_prefix TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  name TEXT,
  usage_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    t.name,
    COUNT(rt.referral_id) as usage_count
  FROM tags t
  LEFT JOIN referral_tags rt ON rt.tag_id = t.id
  WHERE t.user_id = p_user_id
  AND t.name ILIKE p_prefix || '%'
  GROUP BY t.name
  ORDER BY usage_count DESC, t.name
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION search_user_tags TO authenticated;
/*
  # Add tag deletion policies

  1. Changes
    - Add RLS policy to allow users to delete their own tags
    - Add trigger to clean up orphaned tags after deletion

  2. Security
    - Enable RLS on tags table (if not already enabled)
    - Add policy for authenticated users to delete their own tags
*/

-- Enable RLS on tags table if not already enabled
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;

-- Add policy for tag deletion
CREATE POLICY "Users can delete their own tags"
  ON tags
  FOR DELETE
  TO public
  USING (
    auth.uid() IN (
      SELECT profiles.privy_id::uuid
      FROM profiles
      WHERE profiles.id = user_id
    )
  );

-- Create function to clean up orphaned tags
CREATE OR REPLACE FUNCTION cleanup_orphaned_tags()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete tags that have no referrals
  DELETE FROM tags
  WHERE id = OLD.tag_id
  AND NOT EXISTS (
    SELECT 1 FROM referral_tags
    WHERE tag_id = OLD.tag_id
  );
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to clean up orphaned tags after referral_tag deletion
DROP TRIGGER IF EXISTS cleanup_orphaned_tags_trigger ON referral_tags;
CREATE TRIGGER cleanup_orphaned_tags_trigger
  AFTER DELETE ON referral_tags
  FOR EACH ROW
  EXECUTE FUNCTION cleanup_orphaned_tags();
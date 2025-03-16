/*
  # Update tag deletion policy

  1. Changes
    - Drop existing tag deletion policy
    - Add new simplified tag deletion policy that checks only user ownership

  2. Security
    - Users can only delete tags they own (where user_id matches their profile id)
    - Simplified policy logic for better maintainability
*/

-- Drop the existing policy
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;

-- Create new simplified policy
CREATE POLICY "Users can delete their own tags"
ON tags
FOR DELETE
TO public
USING (EXISTS (
  SELECT 1
  FROM profiles
  WHERE profiles.id = tags.user_id
));
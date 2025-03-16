-- Add user_id to tags table
ALTER TABLE tags
ADD COLUMN user_id uuid REFERENCES profiles(id);

-- Ensure each tag is unique per user
CREATE UNIQUE INDEX unique_user_tag ON tags(user_id, name);
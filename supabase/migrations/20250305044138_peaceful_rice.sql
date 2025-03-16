-- Update the username pattern constraint to be more permissive
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS username_pattern;
ALTER TABLE profiles ADD CONSTRAINT username_pattern 
  CHECK (username = '' OR username ~ '^[a-zA-Z0-9_]+$');
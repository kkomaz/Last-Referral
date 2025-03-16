/*
  # Complete Database Schema Recreation
  
  1. Tables
    - profiles: User profiles with Privy integration
    - referrals: User referral links
    - tags: User-specific tags
    - referral_tags: Junction table for referral-tag relationships
  
  2. Security
    - Enable RLS on all tables
    - Add policies for proper access control
    
  3. Functions
    - Add helper functions for tag management
*/

-- First, drop existing tables in correct order
DROP TABLE IF EXISTS referral_tags CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS referrals CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;

-- Create profiles table
CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  privy_id text UNIQUE,
  username text UNIQUE,
  bio text DEFAULT 'Tech enthusiast sharing my favorite products and services.',
  avatar_url text,
  twitter text,
  instagram text,
  linkedin text,
  website text,
  CONSTRAINT username_pattern CHECK (username IS NULL OR username = '' OR username ~ '^[a-zA-Z0-9_]+$')
);

-- Create referrals table
CREATE TABLE referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title text NOT NULL,
  description text,
  url text NOT NULL,
  image_url text,
  subtitle text,
  tags text -- Comma-separated list for easy querying
);

-- Create tags table
CREATE TABLE tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  user_id uuid REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name text NOT NULL,
  UNIQUE (user_id, name)
);

-- Create referral_tags junction table
CREATE TABLE referral_tags (
  referral_id uuid REFERENCES referrals(id) ON DELETE CASCADE,
  tag_id uuid REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (referral_id, tag_id)
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX idx_profiles_privy_id ON profiles(privy_id);
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_referrals_user_id ON referrals(user_id);
CREATE INDEX idx_tags_user_id_name ON tags(user_id, name);
CREATE INDEX idx_referral_tags_referral_id ON referral_tags(referral_id);
CREATE INDEX idx_referral_tags_tag_id ON referral_tags(tag_id);

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (
    auth.uid()::text = id::text OR 
    privy_id = auth.uid()::text
  );

CREATE POLICY "Anyone can create profiles"
  ON profiles FOR INSERT
  WITH CHECK (true);

-- Referrals policies
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals FOR SELECT
  USING (true);

CREATE POLICY "Users can insert their own referrals"
  ON referrals FOR INSERT
  WITH CHECK (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update their own referrals"
  ON referrals FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete their own referrals"
  ON referrals FOR DELETE
  USING (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

-- Tags policies
CREATE POLICY "Users can view their own tags"
  ON tags FOR SELECT
  USING (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can create their own tags"
  ON tags FOR INSERT
  WITH CHECK (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can update their own tags"
  ON tags FOR UPDATE
  USING (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

CREATE POLICY "Users can delete their own tags"
  ON tags FOR DELETE
  USING (
    user_id IN (
      SELECT id FROM profiles 
      WHERE privy_id = auth.uid()::text
    )
  );

-- Referral tags policies
CREATE POLICY "Anyone can view referral tags"
  ON referral_tags FOR SELECT
  USING (true);

CREATE POLICY "Users can manage referral tags they own"
  ON referral_tags 
  USING (
    referral_id IN (
      SELECT id FROM referrals
      WHERE user_id IN (
        SELECT id FROM profiles 
        WHERE privy_id = auth.uid()::text
      )
    )
  );

-- Create function to add tags to a referral
CREATE OR REPLACE FUNCTION add_tags_to_referral(
  p_referral_id uuid,
  p_tag_names text[],
  p_user_id uuid
)
RETURNS void AS $$
DECLARE
  tag_id uuid;
  tag_name text;
  referral_user_id uuid;
BEGIN
  -- Validate inputs
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id cannot be NULL';
  END IF;

  -- Get the user_id of the referral owner
  SELECT user_id INTO referral_user_id
  FROM referrals
  WHERE id = p_referral_id;

  IF referral_user_id IS NULL THEN
    RAISE EXCEPTION 'Referral not found';
  END IF;

  IF referral_user_id != p_user_id THEN
    RAISE EXCEPTION 'User does not own this referral';
  END IF;

  -- Remove existing tags for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;

  -- Process each tag
  FOREACH tag_name IN ARRAY p_tag_names
  LOOP
    -- Skip empty tags
    IF tag_name IS NULL OR tag_name = '' THEN
      CONTINUE;
    END IF;

    -- Try to find existing tag for this user
    SELECT id INTO tag_id
    FROM tags
    WHERE name = tag_name AND user_id = p_user_id;

    -- Create new tag if it doesn't exist
    IF tag_id IS NULL THEN
      INSERT INTO tags (name, user_id)
      VALUES (tag_name, p_user_id)
      RETURNING id INTO tag_id;
    END IF;

    -- Link tag to referral
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, tag_id)
    ON CONFLICT DO NOTHING;

    -- Update the tags column in referrals table
    UPDATE referrals 
    SET tags = (
      SELECT string_agg(t.name, ', ' ORDER BY t.name)
      FROM referral_tags rt
      JOIN tags t ON t.id = rt.tag_id
      WHERE rt.referral_id = p_referral_id
    )
    WHERE id = p_referral_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION add_tags_to_referral TO authenticated, anon;
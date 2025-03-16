/*
  # Create tags tables for ReferralTree

  1. New Tables
    - `tags`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `created_at` (timestamp)
    - `referral_tags`
      - `referral_id` (uuid, foreign key to referrals.id)
      - `tag_id` (uuid, foreign key to tags.id)
      - Primary key (referral_id, tag_id)
  
  2. Security
    - Enable RLS on both tables
    - Add policies for tag management
*/

-- Create tags table
CREATE TABLE IF NOT EXISTS tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create referral_tags junction table
CREATE TABLE IF NOT EXISTS referral_tags (
  referral_id UUID REFERENCES referrals(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (referral_id, tag_id)
);

-- Enable Row Level Security
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_tags ENABLE ROW LEVEL SECURITY;

-- Tags policies
-- Allow users to read all tags
CREATE POLICY "Tags are viewable by everyone"
  ON tags
  FOR SELECT
  USING (true);

-- Allow authenticated users to insert tags
CREATE POLICY "Authenticated users can insert tags"
  ON tags
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

-- Referral_tags policies
-- Allow users to read all referral_tags
CREATE POLICY "Referral tags are viewable by everyone"
  ON referral_tags
  FOR SELECT
  USING (true);

-- Allow users to insert tags for their own referrals
CREATE POLICY "Users can tag their own referrals"
  ON referral_tags
  FOR INSERT
  WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM referrals WHERE id = referral_id
    )
  );

-- Allow users to delete tags from their own referrals
CREATE POLICY "Users can remove tags from their own referrals"
  ON referral_tags
  FOR DELETE
  USING (
    auth.uid() IN (
      SELECT user_id FROM referrals WHERE id = referral_id
    )
  );

-- Create index for faster tag lookups
CREATE INDEX IF NOT EXISTS idx_referral_tags_referral_id ON referral_tags(referral_id);
CREATE INDEX IF NOT EXISTS idx_referral_tags_tag_id ON referral_tags(tag_id);
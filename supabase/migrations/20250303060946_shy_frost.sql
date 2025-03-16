/*
  # Initial schema setup for ReferralTree

  1. New Tables
    - `profiles`
      - `id` (uuid, primary key, linked to auth.users)
      - `created_at` (timestamp)
      - `username` (text, unique)
      - `display_name` (text)
      - `bio` (text)
      - `avatar_url` (text)
      - `twitter` (text)
      - `instagram` (text)
      - `linkedin` (text)
      - `website` (text)
    - `referrals`
      - `id` (uuid, primary key)
      - `created_at` (timestamp)
      - `title` (text)
      - `description` (text)
      - `url` (text)
      - `image_url` (text)
      - `tags` (text)
      - `subtitle` (text)
      - `user_id` (uuid, foreign key to profiles.id)
  2. Security
    - Enable RLS on both tables
    - Add policies for authenticated users to manage their own data
    - Add policies for public access to read profiles and referrals
*/

-- Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  twitter TEXT,
  instagram TEXT,
  linkedin TEXT,
  website TEXT
);

-- Create referrals table
CREATE TABLE IF NOT EXISTS referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  title TEXT NOT NULL,
  description TEXT,
  url TEXT NOT NULL,
  image_url TEXT,
  tags TEXT,
  subtitle TEXT,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;

-- Profiles policies
-- Allow users to read all profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles
  FOR SELECT
  USING (true);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (auth.uid() = id);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile"
  ON profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Referrals policies
-- Allow users to read all referrals
CREATE POLICY "Referrals are viewable by everyone"
  ON referrals
  FOR SELECT
  USING (true);

-- Allow users to insert their own referrals
CREATE POLICY "Users can insert their own referrals"
  ON referrals
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Allow users to update their own referrals
CREATE POLICY "Users can update their own referrals"
  ON referrals
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow users to delete their own referrals
CREATE POLICY "Users can delete their own referrals"
  ON referrals
  FOR DELETE
  USING (auth.uid() = user_id);
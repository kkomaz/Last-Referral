-- Add privy_id column to profiles table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'privy_id'
  ) THEN
    ALTER TABLE profiles ADD COLUMN privy_id TEXT UNIQUE;
  END IF;
END $$;

-- Create index on privy_id for faster lookups
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_profiles_privy_id'
  ) THEN
    CREATE INDEX idx_profiles_privy_id ON profiles(privy_id);
  END IF;
END $$;

-- Update RLS policies to allow access based on privy_id
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'profiles' AND policyname = 'Users can update their own profile'
  ) THEN
    DROP POLICY "Users can update their own profile" ON profiles;
  END IF;
END $$;

-- Create updated policy that checks both auth.uid and privy_id
CREATE POLICY "Users can update their own profile"
  ON profiles
  FOR UPDATE
  USING (
    auth.uid() = id OR 
    privy_id IN (
      SELECT privy_id FROM profiles WHERE id = auth.uid()
    )
  );

-- Similar updates for referrals policies
DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can insert their own referrals'
  ) THEN
    DROP POLICY "Users can insert their own referrals" ON referrals;
  END IF;
END $$;

CREATE POLICY "Users can insert their own referrals"
  ON referrals
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id OR
    user_id IN (
      SELECT id FROM profiles WHERE privy_id IN (
        SELECT privy_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can update their own referrals'
  ) THEN
    DROP POLICY "Users can update their own referrals" ON referrals;
  END IF;
END $$;

CREATE POLICY "Users can update their own referrals"
  ON referrals
  FOR UPDATE
  USING (
    auth.uid() = user_id OR
    user_id IN (
      SELECT id FROM profiles WHERE privy_id IN (
        SELECT privy_id FROM profiles WHERE id = auth.uid()
      )
    )
  );

DO $$ 
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'referrals' AND policyname = 'Users can delete their own referrals'
  ) THEN
    DROP POLICY "Users can delete their own referrals" ON referrals;
  END IF;
END $$;

CREATE POLICY "Users can delete their own referrals"
  ON referrals
  FOR DELETE
  USING (
    auth.uid() = user_id OR
    user_id IN (
      SELECT id FROM profiles WHERE privy_id IN (
        SELECT privy_id FROM profiles WHERE id = auth.uid()
      )
    )
  );
/*
  # Update RLS policies for tags table

  1. Changes
    - Drop existing policy for tag deletion
    - Add new policy that checks privy_id from JWT against profiles table
    
  2. Security
    - Ensures users can only delete their own tags by verifying privy_id
    - Links JWT authentication with profiles table
*/

-- Drop existing policy
DROP POLICY IF EXISTS "Users can delete their own tags" ON tags;

-- Create new policy using privy_id from JWT
CREATE POLICY "Users can delete their own tags" 
ON tags 
FOR DELETE 
TO public 
USING (
  EXISTS (
    SELECT 1 
    FROM profiles 
    WHERE profiles.privy_id = auth.jwt() ->> 'sub'
    AND profiles.id = tags.user_id
  )
);
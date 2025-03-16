/*
  # Add debug function and policy for Privy authentication

  1. Changes
    - Create a function to log Privy ID and JWT claims
    - Add a trigger to log authentication details during updates
    
  2. Purpose
    - Debug authentication issues with Privy ID during updates
    - Log JWT claims and Privy ID for troubleshooting
*/

-- Create a table to store debug logs
CREATE TABLE IF NOT EXISTS auth_debug_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  operation text,
  privy_id text,
  jwt_claims jsonb,
  table_name text,
  record_id text
);

-- Enable RLS
ALTER TABLE auth_debug_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own debug logs
CREATE POLICY "Users can view their own debug logs"
ON auth_debug_logs
FOR SELECT
TO public
USING (
  privy_id = get_privy_id()
);

-- Create a function to log auth details
CREATE OR REPLACE FUNCTION log_auth_debug()
RETURNS trigger AS $$
BEGIN
  INSERT INTO auth_debug_logs (
    operation,
    privy_id,
    jwt_claims,
    table_name,
    record_id
  ) VALUES (
    TG_OP,
    get_privy_id(),
    current_setting('request.jwt.claims', true)::jsonb,
    TG_TABLE_NAME,
    NEW.id::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add trigger to referrals table
DROP TRIGGER IF EXISTS referrals_auth_debug_trigger ON referrals;
CREATE TRIGGER referrals_auth_debug_trigger
  BEFORE UPDATE ON referrals
  FOR EACH ROW
  EXECUTE FUNCTION log_auth_debug();
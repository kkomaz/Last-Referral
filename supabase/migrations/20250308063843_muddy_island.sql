/*
  # Create get_privy_id function
  
  1. New Functions
    - get_privy_id(): Returns the Privy user ID from the JWT token
    
  2. Details
    - Extracts the 'sub' claim from the JWT token
    - Returns NULL if no token is present or invalid
    - Used by RLS policies to verify user ownership
*/

CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Get the JWT claims from the current request context
  -- The 'sub' claim contains the Privy user ID
  RETURN (current_setting('request.jwt.claims', true)::json->>'sub');
EXCEPTION
  WHEN OTHERS THEN
    -- Return NULL if there's any error (no token, invalid token, etc.)
    RETURN NULL;
END;
$$;
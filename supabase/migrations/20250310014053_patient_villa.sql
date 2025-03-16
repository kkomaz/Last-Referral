/*
  # Update get_privy_id function
  
  1. Changes
    - Updates the get_privy_id() function to properly handle Privy JWT tokens
    - Adds proper error handling and logging
    - Preserves existing function dependencies
  
  2. Function Details
    - Extracts the 'sub' claim from the JWT
    - Handles the 'did:privy:' prefix in the token
    - Maintains backward compatibility with existing policies
*/

-- Update the function without dropping it
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _jwt_sub TEXT;
  _privy_id TEXT;
BEGIN
  -- Get the sub claim from the JWT
  _jwt_sub := current_setting('request.jwt.claims', true)::json->>'sub';
  
  -- Log the raw JWT sub for debugging
  RAISE NOTICE 'Raw JWT sub: %', _jwt_sub;
  
  -- Check if we got a JWT sub
  IF _jwt_sub IS NULL THEN
    RAISE NOTICE 'No JWT sub found in token';
    RETURN NULL;
  END IF;
  
  -- Handle the did:privy: prefix
  IF _jwt_sub LIKE 'did:privy:%' THEN
    _privy_id := _jwt_sub;
  ELSE
    _privy_id := 'did:privy:' || _jwt_sub;
  END IF;
  
  -- Log the final Privy ID for debugging
  RAISE NOTICE 'Final Privy ID: %', _privy_id;
  
  RETURN _privy_id;
END;
$$;
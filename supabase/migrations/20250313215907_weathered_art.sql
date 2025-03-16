/*
  # Fix get_privy_id function to handle Privy JWT format
  
  1. Changes
    - Update get_privy_id function to properly handle 'did:privy:' format
    - Add better error handling and logging
    - Fix JWT claims extraction
*/

-- Update the function to handle the full Privy ID format
CREATE OR REPLACE FUNCTION get_privy_id()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  _claims json;
  _sub text;
BEGIN
  -- Get the JWT claims
  BEGIN
    _claims := current_setting('request.jwt.claims', true)::json;
    _sub := _claims->>'sub';
    
    -- Log the values for debugging
    RAISE NOTICE 'JWT Claims: %, Sub: %', _claims, _sub;
    
    -- Return the sub claim as-is (should already be in did:privy:xyz format)
    RETURN _sub;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE 'Error getting Privy ID: %', SQLERRM;
      RETURN NULL;
  END;
END;
$$;
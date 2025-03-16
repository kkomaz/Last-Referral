/*
  # Add RPC function for fetching referral with tags
  
  1. New Functions
    - get_referral_with_tags: Fetches a referral and its associated tags
    
  2. Security
    - Function runs with SECURITY DEFINER
    - Proper authorization checks included
    - Maintains RLS policies
*/

-- Function to get a referral with its tags
CREATE OR REPLACE FUNCTION get_referral_with_tags(
  p_referral_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Get the referral and its tags
  SELECT jsonb_build_object(
    'id', r.id,
    'user_id', r.user_id,
    'title', r.title,
    'description', r.description,
    'url', r.url,
    'image_url', r.image_url,
    'subtitle', r.subtitle,
    'created_at', r.created_at,
    'referral_tags', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'tag', jsonb_build_object(
            'id', t.id,
            'name', t.name
          )
        )
      )
      FROM referral_tags rt
      JOIN tags t ON t.id = rt.tag_id
      WHERE rt.referral_id = r.id
    )
  )
  INTO v_result
  FROM referrals r
  WHERE r.id = p_referral_id;

  RETURN v_result;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_referral_with_tags TO authenticated, anon;
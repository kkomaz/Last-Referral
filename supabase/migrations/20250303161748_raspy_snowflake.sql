/*
  # Fix tag handling issues

  1. Changes
     - Create a more robust function to handle tag creation and association
     - Add debugging triggers to track tag operations
     - Ensure proper permissions for tag operations

  2. Security
     - Maintain existing security policies
     - Ensure proper access to tag operations
*/

-- Create a more robust function to handle tag creation and association
CREATE OR REPLACE FUNCTION create_tag_and_associate(
  p_referral_id UUID,
  p_tag_name TEXT
) RETURNS UUID AS $$
DECLARE
  v_tag_id UUID;
BEGIN
  -- First try to find the tag
  SELECT id INTO v_tag_id FROM tags WHERE name = p_tag_name;
  
  -- If tag doesn't exist, create it
  IF v_tag_id IS NULL THEN
    INSERT INTO tags (name) VALUES (p_tag_name) RETURNING id INTO v_tag_id;
    RAISE NOTICE 'Created new tag: % with ID: %', p_tag_name, v_tag_id;
  ELSE
    RAISE NOTICE 'Found existing tag: % with ID: %', p_tag_name, v_tag_id;
  END IF;
  
  -- Associate tag with referral if not already associated
  BEGIN
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, v_tag_id)
    ON CONFLICT (referral_id, tag_id) DO NOTHING;
    
    RAISE NOTICE 'Associated tag % with referral %', v_tag_id, p_referral_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error associating tag: %', SQLERRM;
  END;
  
  RETURN v_tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to process multiple tags for a referral
CREATE OR REPLACE FUNCTION process_referral_tags(
  p_referral_id UUID,
  p_tag_names TEXT[]
) RETURNS VOID AS $$
DECLARE
  v_tag_name TEXT;
BEGIN
  -- Clear existing tags for this referral
  DELETE FROM referral_tags WHERE referral_id = p_referral_id;
  RAISE NOTICE 'Cleared existing tags for referral %', p_referral_id;
  
  -- Process each tag
  FOREACH v_tag_name IN ARRAY p_tag_names LOOP
    IF v_tag_name IS NOT NULL AND v_tag_name != '' THEN
      PERFORM create_tag_and_associate(p_referral_id, v_tag_name);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a trigger function to automatically process tags when a referral is created or updated
CREATE OR REPLACE FUNCTION process_referral_tags_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_tag_names TEXT[];
BEGIN
  -- Skip if tags is NULL or empty
  IF NEW.tags IS NULL OR NEW.tags = '' THEN
    RETURN NEW;
  END IF;
  
  -- Split the tags string into an array
  v_tag_names := string_to_array(NEW.tags, ',');
  
  -- Trim whitespace from each tag
  FOR i IN 1..array_length(v_tag_names, 1) LOOP
    v_tag_names[i] := trim(v_tag_names[i]);
  END LOOP;
  
  -- Process the tags
  PERFORM process_referral_tags(NEW.id, v_tag_names);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create or replace the trigger on referrals
DROP TRIGGER IF EXISTS process_referral_tags_trigger ON referrals;

CREATE TRIGGER process_referral_tags_trigger
AFTER INSERT OR UPDATE OF tags ON referrals
FOR EACH ROW
EXECUTE FUNCTION process_referral_tags_trigger();

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION create_tag_and_associate TO authenticated, anon;
GRANT EXECUTE ON FUNCTION process_referral_tags TO authenticated, anon;

-- Create a function to directly add tags to a referral (for API use)
CREATE OR REPLACE FUNCTION add_tags_to_referral(
  p_referral_id UUID,
  p_tag_names TEXT[]
) RETURNS VOID AS $$
BEGIN
  PERFORM process_referral_tags(p_referral_id, p_tag_names);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION add_tags_to_referral TO authenticated, anon;
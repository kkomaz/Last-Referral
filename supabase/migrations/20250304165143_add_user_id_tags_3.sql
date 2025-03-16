CREATE OR REPLACE FUNCTION add_tags_to_referral(p_referral_id uuid, p_tag_names text[], p_user_id uuid)
RETURNS void AS $$
DECLARE
  tag_id uuid;
  tag_name text;
BEGIN
  -- Loop through each tag name
  FOREACH tag_name IN ARRAY p_tag_names
  LOOP
    -- Insert tag if it does not exist, otherwise ignore
    INSERT INTO tags (name, user_id)
    VALUES (tag_name, p_user_id)
    ON CONFLICT (name, user_id) DO NOTHING;

    -- Retrieve tag_id (guaranteed to exist now)
    SELECT id INTO tag_id FROM tags WHERE name = tag_name AND user_id = p_user_id;

    -- Insert into referral_tags (ensure no duplicate entries)
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, tag_id)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
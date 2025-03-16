CREATE OR REPLACE FUNCTION add_tags_to_referral(p_referral_id uuid, p_tag_names text[], p_user_id uuid)
RETURNS void AS $$
DECLARE
  tag_id uuid;
  tag_name text;
BEGIN
  -- Validate that p_user_id is not NULL
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'user_id cannot be NULL';
  END IF;

  -- Loop through each tag name
  FOREACH tag_name IN ARRAY p_tag_names
  LOOP
    -- Try to find a tag with the given name and user_id
    SELECT id INTO tag_id
    FROM tags
    WHERE name = tag_name AND user_id = p_user_id
    LIMIT 1;

    IF tag_id IS NULL THEN
      -- Tag doesn't exist for this user, check if it exists with a NULL user_id
      SELECT id INTO tag_id
      FROM tags
      WHERE name = tag_name AND user_id IS NULL
      LIMIT 1;

      IF tag_id IS NOT NULL THEN
        -- Update the tag's user_id if it was NULL
        UPDATE tags
        SET user_id = p_user_id
        WHERE id = tag_id;
      ELSE
        -- Tag doesn't exist at all, create it
        INSERT INTO tags (name, user_id)
        VALUES (tag_name, p_user_id)
        RETURNING id INTO tag_id;
      END IF;
    END IF;

    -- Insert into referral_tags (ensure no duplicate entries)
    INSERT INTO referral_tags (referral_id, tag_id)
    VALUES (p_referral_id, tag_id)
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
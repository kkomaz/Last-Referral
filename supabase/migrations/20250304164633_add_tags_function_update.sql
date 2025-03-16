   CREATE OR REPLACE FUNCTION add_tags_to_referral(p_referral_id uuid, p_tag_names text[], p_user_id uuid)
   RETURNS void AS $$
   DECLARE
     tag_id uuid;
     tag_name text; -- Declare the loop variable
   BEGIN
     -- Loop through each tag name
     FOREACH tag_name IN ARRAY p_tag_names
     LOOP
       -- Check if the tag already exists for the user
       SELECT id INTO tag_id FROM tags WHERE name = tag_name AND user_id = p_user_id;

       -- If the tag does not exist, insert it
       IF NOT FOUND THEN
         INSERT INTO tags (name, user_id) VALUES (tag_name, p_user_id) RETURNING id INTO tag_id;
       END IF;

       -- Insert into referral_tags
       INSERT INTO referral_tags (referral_id, tag_id) VALUES (p_referral_id, tag_id);
     END LOOP;
   END;
   $$ LANGUAGE plpgsql;
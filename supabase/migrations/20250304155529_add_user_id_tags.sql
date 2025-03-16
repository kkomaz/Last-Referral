   CREATE OR REPLACE FUNCTION add_tags_to_referral(p_referral_id uuid, p_tag_names text[], p_user_id uuid)
   RETURNS void AS $$
   BEGIN
     -- Your logic to add tags to a referral
   END;
   $$ LANGUAGE plpgsql;
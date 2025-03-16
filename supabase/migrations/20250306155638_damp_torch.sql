/*
  # Fix tag management system

  1. Changes
    - Remove tags column from referrals table
    - Add indexes for better performance
    - Ensure proper cascading deletes
  
  2. Notes
    - This is a breaking change that requires code updates
    - Existing tag text data will be migrated to proper tag relationships
*/

-- First, ensure we preserve existing tag data
DO $$
DECLARE
    r RECORD;
    v_tag_name TEXT;
    v_tag_id UUID;
BEGIN
    -- For each referral with tags
    FOR r IN SELECT id, user_id, tags FROM referrals WHERE tags IS NOT NULL AND tags != '' LOOP
        -- Split the tags string and process each tag
        FOR v_tag_name IN SELECT unnest(string_to_array(r.tags, ',')) LOOP
            -- Clean the tag name
            v_tag_name := trim(v_tag_name);
            
            -- Skip empty tags
            IF v_tag_name = '' THEN
                CONTINUE;
            END IF;
            
            -- Insert the tag if it doesn't exist
            INSERT INTO tags (user_id, name)
            VALUES (r.user_id, v_tag_name)
            ON CONFLICT (user_id, name) DO UPDATE SET name = EXCLUDED.name
            RETURNING id INTO v_tag_id;
            
            -- Create the relationship
            INSERT INTO referral_tags (referral_id, tag_id)
            VALUES (r.id, v_tag_id)
            ON CONFLICT DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Now we can safely remove the tags column
ALTER TABLE referrals DROP COLUMN tags;

-- Add some helpful indexes
CREATE INDEX IF NOT EXISTS idx_referral_tags_tag_id ON referral_tags(tag_id);
CREATE INDEX IF NOT EXISTS idx_referral_tags_referral_id ON referral_tags(referral_id);

-- Ensure we have the correct cascade behavior
ALTER TABLE referral_tags
    DROP CONSTRAINT IF EXISTS referral_tags_referral_id_fkey,
    ADD CONSTRAINT referral_tags_referral_id_fkey
        FOREIGN KEY (referral_id)
        REFERENCES referrals(id)
        ON DELETE CASCADE;

ALTER TABLE referral_tags
    DROP CONSTRAINT IF EXISTS referral_tags_tag_id_fkey,
    ADD CONSTRAINT referral_tags_tag_id_fkey
        FOREIGN KEY (tag_id)
        REFERENCES tags(id)
        ON DELETE CASCADE;
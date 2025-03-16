-- Step 1: Delete tags with NULL user_id (Option 2)
DELETE FROM tags
WHERE user_id IS NULL;

-- Step 2: Make user_id NOT NULL
ALTER TABLE tags
ALTER COLUMN user_id SET NOT NULL;

-- Step 3: Ensure the foreign key constraint exists and add ON DELETE CASCADE
-- (Skip if you don't want to modify the existing constraint)
ALTER TABLE tags
DROP CONSTRAINT tags_user_id_fkey; -- Only if it exists and you want to add CASCADE

ALTER TABLE tags
ADD CONSTRAINT tags_user_id_fkey
FOREIGN KEY (user_id) REFERENCES profiles(id)
ON DELETE CASCADE;

-- Step 4: Clean up orphaned records in referral_tags
DELETE FROM referral_tags
WHERE tag_id NOT IN (SELECT id FROM tags);
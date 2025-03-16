/*
  # Fix default colors in profiles table

  1. Changes
    - Update default values for color columns
    - Set default colors for existing NULL values
    - Make color columns NOT NULL
    
  2. Notes
    - Primary: #7b68ee (Purple)
    - Secondary: #2b2d42 (Dark Blue)
    - Body: #f7f9fb (Light Gray)
    - Card: #ffffff (White)
*/

-- First, update existing NULL values to use defaults
UPDATE profiles 
SET 
  primary_color = '#7b68ee' WHERE primary_color IS NULL;

UPDATE profiles 
SET 
  secondary_color = '#2b2d42' WHERE secondary_color IS NULL;

UPDATE profiles 
SET 
  body_color = '#f7f9fb' WHERE body_color IS NULL;

UPDATE profiles 
SET 
  card_color = '#ffffff' WHERE card_color IS NULL;

-- Then, alter the columns to set defaults and make them NOT NULL
ALTER TABLE profiles 
  ALTER COLUMN primary_color SET DEFAULT '#7b68ee',
  ALTER COLUMN primary_color SET NOT NULL;

ALTER TABLE profiles 
  ALTER COLUMN secondary_color SET DEFAULT '#2b2d42',
  ALTER COLUMN secondary_color SET NOT NULL;

ALTER TABLE profiles 
  ALTER COLUMN body_color SET DEFAULT '#f7f9fb',
  ALTER COLUMN body_color SET NOT NULL;

ALTER TABLE profiles 
  ALTER COLUMN card_color SET DEFAULT '#ffffff',
  ALTER COLUMN card_color SET NOT NULL;
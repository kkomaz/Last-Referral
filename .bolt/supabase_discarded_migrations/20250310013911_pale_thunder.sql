/*
  # Debug Privy Authentication

  This file contains queries to help debug Privy authentication issues by:
  1. Showing the current Privy ID from JWT
  2. Displaying matching profiles and referrals
  3. Comparing stored vs current Privy IDs
*/

-- Show the current Privy ID from JWT
SELECT get_privy_id() as current_privy_id;

-- Show all profiles with their Privy IDs
SELECT id, privy_id, username 
FROM profiles 
WHERE privy_id IS NOT NULL;

-- Show matching profiles for current user
SELECT p.id as profile_id,
       p.privy_id as stored_privy_id,
       get_privy_id() as current_privy_id,
       p.username,
       r.id as referral_id,
       r.title as referral_title
FROM profiles p
LEFT JOIN referrals r ON r.user_id = p.id
WHERE p.privy_id = get_privy_id();

-- Check if the policy would allow access
SELECT EXISTS (
  SELECT 1
  FROM profiles
  WHERE privy_id = get_privy_id()
) as has_access;
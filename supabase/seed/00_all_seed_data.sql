-- Complete Seed Data for MealDeal
-- Run this file to seed the entire database with working data
-- Execute in order: 01 -> 02 -> 03 -> 04 -> 05 -> 06

-- This file imports all seed data in the correct order
\i 01_lookups.sql
\i 02_chains_regions.sql
\i 03_ingredients_sample.sql
\i 04_dishes_sample.sql
\i 05_dish_ingredients_sample.sql
\i 06_offers_current.sql

-- Verify data
SELECT 'Lookups' as table_name, COUNT(*) as count FROM lookups_categories
UNION ALL
SELECT 'Units', COUNT(*) FROM lookups_units
UNION ALL
SELECT 'Chains', COUNT(*) FROM chains
UNION ALL
SELECT 'Regions', COUNT(*) FROM ad_regions
UNION ALL
SELECT 'Stores', COUNT(*) FROM stores
UNION ALL
SELECT 'Postal Codes', COUNT(*) FROM postal_codes
UNION ALL
SELECT 'Ingredients', COUNT(*) FROM ingredients
UNION ALL
SELECT 'Dishes', COUNT(*) FROM dishes
UNION ALL
SELECT 'Dish Ingredients', COUNT(*) FROM dish_ingredients
UNION ALL
SELECT 'Offers', COUNT(*) FROM offers;


-- Add CASCADE UPDATE and DELETE to all foreign key relationships
-- This allows updates and deletes to propagate through related tables

-- ============================================================================
-- Step 0: Query to check current constraint names (run this first if needed)
-- ============================================================================
-- Uncomment and run this to see actual constraint names:
/*
SELECT
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule,
  rc.update_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
*/

-- ============================================================================
-- Step 1: Drop and recreate foreign keys with CASCADE UPDATE and DELETE
-- ============================================================================

-- Ad Regions: chain_id
ALTER TABLE ad_regions
  DROP CONSTRAINT IF EXISTS ad_regions_chain_id_fkey;

ALTER TABLE ad_regions
  ADD CONSTRAINT ad_regions_chain_id_fkey
  FOREIGN KEY (chain_id)
  REFERENCES chains(chain_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Stores: chain_id
ALTER TABLE stores
  DROP CONSTRAINT IF EXISTS stores_chain_id_fkey;

ALTER TABLE stores
  ADD CONSTRAINT stores_chain_id_fkey
  FOREIGN KEY (chain_id)
  REFERENCES chains(chain_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Store Region Map: store_id
ALTER TABLE store_region_map
  DROP CONSTRAINT IF EXISTS store_region_map_store_id_fkey;

ALTER TABLE store_region_map
  ADD CONSTRAINT store_region_map_store_id_fkey
  FOREIGN KEY (store_id)
  REFERENCES stores(store_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Store Region Map: region_id
ALTER TABLE store_region_map
  DROP CONSTRAINT IF EXISTS store_region_map_region_id_fkey;

ALTER TABLE store_region_map
  ADD CONSTRAINT store_region_map_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Postal Codes: region_id
ALTER TABLE postal_codes
  DROP CONSTRAINT IF EXISTS postal_codes_region_id_fkey;

ALTER TABLE postal_codes
  ADD CONSTRAINT postal_codes_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Ingredients: unit_default
ALTER TABLE ingredients
  DROP CONSTRAINT IF EXISTS ingredients_unit_default_fkey;

ALTER TABLE ingredients
  ADD CONSTRAINT ingredients_unit_default_fkey
  FOREIGN KEY (unit_default)
  REFERENCES lookups_units(unit)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Dishes: category
ALTER TABLE dishes
  DROP CONSTRAINT IF EXISTS dishes_category_fkey;

ALTER TABLE dishes
  ADD CONSTRAINT dishes_category_fkey
  FOREIGN KEY (category)
  REFERENCES lookups_categories(category)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Dish Ingredients: dish_id
ALTER TABLE dish_ingredients
  DROP CONSTRAINT IF EXISTS dish_ingredients_dish_id_fkey;

ALTER TABLE dish_ingredients
  ADD CONSTRAINT dish_ingredients_dish_id_fkey
  FOREIGN KEY (dish_id)
  REFERENCES dishes(dish_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Dish Ingredients: ingredient_id
ALTER TABLE dish_ingredients
  DROP CONSTRAINT IF EXISTS dish_ingredients_ingredient_id_fkey;

ALTER TABLE dish_ingredients
  ADD CONSTRAINT dish_ingredients_ingredient_id_fkey
  FOREIGN KEY (ingredient_id)
  REFERENCES ingredients(ingredient_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Dish Ingredients: unit
ALTER TABLE dish_ingredients
  DROP CONSTRAINT IF EXISTS dish_ingredients_unit_fkey;

ALTER TABLE dish_ingredients
  ADD CONSTRAINT dish_ingredients_unit_fkey
  FOREIGN KEY (unit)
  REFERENCES lookups_units(unit)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Product Map: ingredient_id
ALTER TABLE product_map
  DROP CONSTRAINT IF EXISTS product_map_ingredient_id_fkey;

ALTER TABLE product_map
  ADD CONSTRAINT product_map_ingredient_id_fkey
  FOREIGN KEY (ingredient_id)
  REFERENCES ingredients(ingredient_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Offers: region_id
ALTER TABLE offers
  DROP CONSTRAINT IF EXISTS offers_region_id_fkey;

ALTER TABLE offers
  ADD CONSTRAINT offers_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Offers: ingredient_id
ALTER TABLE offers
  DROP CONSTRAINT IF EXISTS offers_ingredient_id_fkey;

ALTER TABLE offers
  ADD CONSTRAINT offers_ingredient_id_fkey
  FOREIGN KEY (ingredient_id)
  REFERENCES ingredients(ingredient_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Offers: unit_base
ALTER TABLE offers
  DROP CONSTRAINT IF EXISTS offers_unit_base_fkey;

ALTER TABLE offers
  ADD CONSTRAINT offers_unit_base_fkey
  FOREIGN KEY (unit_base)
  REFERENCES lookups_units(unit)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- User Roles: user_id
ALTER TABLE user_roles
  DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;

ALTER TABLE user_roles
  ADD CONSTRAINT user_roles_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES user_profiles(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Favorites: user_id
ALTER TABLE favorites
  DROP CONSTRAINT IF EXISTS favorites_user_id_fkey;

ALTER TABLE favorites
  ADD CONSTRAINT favorites_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES user_profiles(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Favorites: dish_id
ALTER TABLE favorites
  DROP CONSTRAINT IF EXISTS favorites_dish_id_fkey;

ALTER TABLE favorites
  ADD CONSTRAINT favorites_dish_id_fkey
  FOREIGN KEY (dish_id)
  REFERENCES dishes(dish_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plans: user_id
ALTER TABLE plans
  DROP CONSTRAINT IF EXISTS plans_user_id_fkey;

ALTER TABLE plans
  ADD CONSTRAINT plans_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES user_profiles(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Items: plan_id
ALTER TABLE plan_items
  DROP CONSTRAINT IF EXISTS plan_items_plan_id_fkey;

ALTER TABLE plan_items
  ADD CONSTRAINT plan_items_plan_id_fkey
  FOREIGN KEY (plan_id)
  REFERENCES plans(plan_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Items: dish_id
ALTER TABLE plan_items
  DROP CONSTRAINT IF EXISTS plan_items_dish_id_fkey;

ALTER TABLE plan_items
  ADD CONSTRAINT plan_items_dish_id_fkey
  FOREIGN KEY (dish_id)
  REFERENCES dishes(dish_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Item Prices: plan_item_id
ALTER TABLE plan_item_prices
  DROP CONSTRAINT IF EXISTS plan_item_prices_plan_item_id_fkey;

ALTER TABLE plan_item_prices
  ADD CONSTRAINT plan_item_prices_plan_item_id_fkey
  FOREIGN KEY (plan_item_id)
  REFERENCES plan_items(plan_item_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Item Prices: ingredient_id
ALTER TABLE plan_item_prices
  DROP CONSTRAINT IF EXISTS plan_item_prices_ingredient_id_fkey;

ALTER TABLE plan_item_prices
  ADD CONSTRAINT plan_item_prices_ingredient_id_fkey
  FOREIGN KEY (ingredient_id)
  REFERENCES ingredients(ingredient_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Item Prices: unit
ALTER TABLE plan_item_prices
  DROP CONSTRAINT IF EXISTS plan_item_prices_unit_fkey;

ALTER TABLE plan_item_prices
  ADD CONSTRAINT plan_item_prices_unit_fkey
  FOREIGN KEY (unit)
  REFERENCES lookups_units(unit)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Plan Totals: plan_id
ALTER TABLE plan_totals
  DROP CONSTRAINT IF EXISTS plan_totals_plan_id_fkey;

ALTER TABLE plan_totals
  ADD CONSTRAINT plan_totals_plan_id_fkey
  FOREIGN KEY (plan_id)
  REFERENCES plans(plan_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Events: user_id (keeping SET NULL for analytics data preservation)
-- Note: We keep ON DELETE SET NULL for events to preserve analytics data
-- even when users are deleted. If you want CASCADE, uncomment the following:
/*
ALTER TABLE events
  DROP CONSTRAINT IF EXISTS events_user_id_fkey;

ALTER TABLE events
  ADD CONSTRAINT events_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES user_profiles(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
*/

-- ============================================================================
-- Step 2: Verify all constraints are properly set
-- ============================================================================

-- Query to check all foreign key constraints and their CASCADE settings
-- Run this to verify:
/*
SELECT
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name,
  rc.delete_rule,
  rc.update_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
*/

-- ============================================================================
-- Step 3: Comments for documentation
-- ============================================================================

COMMENT ON CONSTRAINT ad_regions_chain_id_fkey ON ad_regions IS 
  'CASCADE: Deleting/updating a chain will delete/update all its regions';

COMMENT ON CONSTRAINT stores_chain_id_fkey ON stores IS 
  'CASCADE: Deleting/updating a chain will delete/update all its stores';

COMMENT ON CONSTRAINT ingredients_unit_default_fkey ON ingredients IS 
  'CASCADE: Deleting/updating a unit will delete/update all ingredients using it';

COMMENT ON CONSTRAINT dishes_category_fkey ON dishes IS 
  'CASCADE: Deleting/updating a category will delete/update all dishes in that category';

COMMENT ON CONSTRAINT dish_ingredients_dish_id_fkey ON dish_ingredients IS 
  'CASCADE: Deleting/updating a dish will delete/update all its ingredient relationships';

COMMENT ON CONSTRAINT dish_ingredients_ingredient_id_fkey ON dish_ingredients IS 
  'CASCADE: Deleting/updating an ingredient will delete/update all dish relationships';

COMMENT ON CONSTRAINT offers_ingredient_id_fkey ON offers IS 
  'CASCADE: Deleting/updating an ingredient will delete/update all its offers';

COMMENT ON CONSTRAINT offers_region_id_fkey ON offers IS 
  'CASCADE: Deleting/updating a region will delete/update all its offers';

COMMENT ON CONSTRAINT user_roles_user_id_fkey ON user_roles IS 
  'CASCADE: Deleting/updating a user will delete/update all their roles';

COMMENT ON CONSTRAINT favorites_user_id_fkey ON favorites IS 
  'CASCADE: Deleting/updating a user will delete/update all their favorites';

COMMENT ON CONSTRAINT favorites_dish_id_fkey ON favorites IS 
  'CASCADE: Deleting/updating a dish will delete/update all favorites for that dish';

COMMENT ON CONSTRAINT plans_user_id_fkey ON plans IS 
  'CASCADE: Deleting/updating a user will delete/update all their meal plans';

COMMENT ON CONSTRAINT plan_items_plan_id_fkey ON plan_items IS 
  'CASCADE: Deleting/updating a plan will delete/update all its items';

COMMENT ON CONSTRAINT plan_items_dish_id_fkey ON plan_items IS 
  'CASCADE: Deleting/updating a dish will delete/update all plan items using it';

COMMENT ON CONSTRAINT plan_item_prices_plan_item_id_fkey ON plan_item_prices IS 
  'CASCADE: Deleting/updating a plan item will delete/update all its price details';

COMMENT ON CONSTRAINT plan_item_prices_ingredient_id_fkey ON plan_item_prices IS 
  'CASCADE: Deleting/updating an ingredient will delete/update all plan item prices using it';


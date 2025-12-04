# CASCADE UPDATE and DELETE Implementation Guide

## Overview

This migration adds `ON UPDATE CASCADE` and ensures `ON DELETE CASCADE` is set on all foreign key relationships in the database. This allows you to update and delete data with automatic propagation to related tables.

## What This Means

### CASCADE DELETE
When you delete a record, all related records in dependent tables are automatically deleted.

**Examples:**
- Delete a `chain` → All its `ad_regions`, `stores`, and related data are deleted
- Delete an `ingredient` → All `dish_ingredients`, `offers`, and `plan_item_prices` using it are deleted
- Delete a `dish` → All `dish_ingredients`, `favorites`, and `plan_items` using it are deleted
- Delete a `user_profile` → All their `user_roles`, `favorites`, `plans`, and related data are deleted

### CASCADE UPDATE
When you update a primary key, all foreign keys referencing it are automatically updated.

**Examples:**
- Update `chain_id` in `chains` → All `ad_regions.chain_id` and `stores.chain_id` are updated
- Update `ingredient_id` in `ingredients` → All `dish_ingredients.ingredient_id` and `offers.ingredient_id` are updated
- Update `dish_id` in `dishes` → All `dish_ingredients.dish_id` and `favorites.dish_id` are updated
- Update `user_profile.id` (UUID) → All `user_roles.user_id`, `favorites.user_id`, `plans.user_id` are updated

## Tables Affected

### Chains & Stores Hierarchy
```
chains (chain_id)
  ├── ad_regions (chain_id) → CASCADE
  ├── stores (chain_id) → CASCADE
  └── store_region_map (via stores) → CASCADE
```

### Regions Hierarchy
```
ad_regions (region_id)
  ├── postal_codes (region_id) → CASCADE
  ├── offers (region_id) → CASCADE
  └── store_region_map (region_id) → CASCADE
```

### Ingredients Hierarchy
```
ingredients (ingredient_id)
  ├── dish_ingredients (ingredient_id) → CASCADE
  ├── offers (ingredient_id) → CASCADE
  ├── product_map (ingredient_id) → CASCADE
  └── plan_item_prices (ingredient_id) → CASCADE
```

### Dishes Hierarchy
```
dishes (dish_id)
  ├── dish_ingredients (dish_id) → CASCADE
  ├── favorites (dish_id) → CASCADE
  └── plan_items (dish_id) → CASCADE
```

### Users Hierarchy
```
user_profiles (id)
  ├── user_roles (user_id) → CASCADE
  ├── favorites (user_id) → CASCADE
  ├── plans (user_id) → CASCADE
  └── events (user_id) → SET NULL (preserves analytics)
```

### Meal Plans Hierarchy
```
plans (plan_id)
  ├── plan_items (plan_id) → CASCADE
  └── plan_totals (plan_id) → CASCADE
    └── plan_item_prices (via plan_items) → CASCADE
```

### Lookup Tables
```
lookups_units (unit)
  ├── ingredients (unit_default) → CASCADE
  ├── dish_ingredients (unit) → CASCADE
  ├── offers (unit_base) → CASCADE
  └── plan_item_prices (unit) → CASCADE

lookups_categories (category)
  └── dishes (category) → CASCADE
```

## Usage Examples

### Deleting a Chain
```sql
-- This will automatically delete:
-- - All ad_regions for this chain
-- - All stores for this chain
-- - All store_region_map entries
-- - All postal_codes for those regions
-- - All offers for those regions
DELETE FROM chains WHERE chain_id = 10;
```

### Updating an Ingredient ID
```sql
-- This will automatically update:
-- - All dish_ingredients.ingredient_id
-- - All offers.ingredient_id
-- - All product_map.ingredient_id
-- - All plan_item_prices.ingredient_id
UPDATE ingredients 
SET ingredient_id = 'I999' 
WHERE ingredient_id = 'I001';
```

### Deleting a User
```sql
-- This will automatically delete:
-- - All user_roles
-- - All favorites
-- - All plans (and their plan_items, plan_item_prices, plan_totals)
-- Note: events.user_id will be set to NULL (not deleted)
DELETE FROM user_profiles WHERE id = 'user-uuid';
```

### Updating a Category
```sql
-- This will automatically update:
-- - All dishes.category
UPDATE lookups_categories 
SET category = 'Main Course' 
WHERE category = 'Hauptgericht';
```

### Deleting a Dish
```sql
-- This will automatically delete:
-- - All dish_ingredients for this dish
-- - All favorites for this dish
-- - All plan_items using this dish
DELETE FROM dishes WHERE dish_id = 'D115';
```

## Important Notes

### 1. SERIAL/INTEGER Primary Keys
- **CASCADE UPDATE** works but is rarely used
- Updating a SERIAL primary key is generally not recommended
- If you need to change a chain_id or store_id, consider creating a new record instead

### 2. TEXT Primary Keys
- **CASCADE UPDATE** is very useful
- You can safely update ingredient_id, dish_id, category, unit, etc.
- All foreign keys will automatically update

### 3. UUID Primary Keys
- **CASCADE UPDATE** works perfectly
- Useful for updating user IDs if needed

### 4. Events Table Exception
- `events.user_id` uses `ON DELETE SET NULL` instead of CASCADE
- This preserves analytics data even when users are deleted
- If you want CASCADE for events, uncomment the section in the migration

## Safety Considerations

### ⚠️ Warning: Cascading Deletes
CASCADE DELETE can delete large amounts of data unintentionally:

```sql
-- This will delete EVERYTHING related to chain_id = 10:
-- - All regions, stores, offers, postal codes, etc.
DELETE FROM chains WHERE chain_id = 10;
```

**Best Practice:** Always check what will be deleted first:
```sql
-- Check what will be affected
SELECT COUNT(*) FROM ad_regions WHERE chain_id = 10;
SELECT COUNT(*) FROM stores WHERE chain_id = 10;
SELECT COUNT(*) FROM offers o
JOIN ad_regions ar ON o.region_id = ar.region_id
WHERE ar.chain_id = 10;
```

### ✅ Safe Operations
- Updating TEXT primary keys (ingredient_id, dish_id, etc.)
- Updating UUID primary keys (user IDs)
- Deleting individual records with known impact

## Verification

After running the migration, verify all constraints:

```sql
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
```

All `delete_rule` and `update_rule` should be `CASCADE` (except `events.user_id` which should be `SET NULL`).

## Migration File

The migration is in: `supabase/migrations/011_add_cascade_update_delete.sql`

To apply:
```bash
supabase db push
```

Or via Supabase Dashboard → SQL Editor → Run the migration file.

## Rollback

If you need to rollback, you would need to recreate the foreign keys without CASCADE. However, this is generally not recommended as CASCADE is a best practice for referential integrity.




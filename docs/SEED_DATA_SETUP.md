# Seed Data Setup Guide

This guide explains how to populate the database with seed data to demonstrate the MealDeal workflow.

## Quick Start

### Option 1: Use SQL Seed Files (Recommended)

1. **Go to Supabase SQL Editor:**
   https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr/sql/new

2. **Run seed files in this order:**
   - Copy and run `supabase/seed/01_lookups.sql`
   - Copy and run `supabase/seed/02_chains_regions.sql`
   - Copy and run `supabase/seed/03_ingredients_sample.sql`
   - Copy and run `supabase/seed/04_dishes_sample.sql`
   - Copy and run `supabase/seed/05_dish_ingredients_sample.sql`
   - Copy and run `supabase/seed/06_offers_current.sql`

3. **Verify data:**
   ```sql
   SELECT 'Ingredients' as table, COUNT(*) as count FROM ingredients
   UNION ALL SELECT 'Dishes', COUNT(*) FROM dishes
   UNION ALL SELECT 'Offers', COUNT(*) FROM offers;
   ```

### Option 2: Use CSV Import (Full Data)

1. **Import in this order via Admin Dashboard:**
   - `lookups_categories.csv`
   - `lookups_units.csv` (updated with kg, l, st)
   - `chains_csv.csv`
   - `ad_regions_csv.csv`
   - `stores_csv.csv`
   - `store_region_map_csv.csv`
   - Create and import `postal_codes.csv` (see below)
   - `ingredients.csv`
   - `dishes.csv`
   - `dish_ingredients.csv`
   - `offers_csv.csv`

2. **Create postal_codes.csv:**
   ```csv
   plz,region_id,city
   30165,500,Hannover
   30171,501,Hannover
   30449,510,Hannover
   10115,502,Berlin
   10437,511,Berlin
   ```

## What the Seed Data Includes

### Lookup Tables
- **Categories**: All dish categories (Hauptgericht, Dessert, Snack, etc.)
- **Units**: All measurement units (kg, l, st, g, ml, Bund, EL, TL, etc.)

### Chains & Regions
- **Chains**: REWE, Lidl, ALDI, Edeka
- **Regions**: Multiple advertising regions for each chain
- **Stores**: Sample stores in Hannover and Berlin
- **Postal Codes**: PLZ mappings for Hannover (301xx, 304xx) and Berlin (101xx, 104xx)

### Core Data
- **Ingredients**: 100+ ingredients with baseline prices
- **Dishes**: 60+ dishes including quick meals
- **Dish Ingredients**: Relationships between dishes and ingredients

### Offers
- **Current Offers**: Valid offers for the current week
- Multiple chains (REWE, Lidl, ALDI)
- Popular ingredients (Spaghetti, Hackfleisch, Kartoffeln, Eier, Milch, etc.)
- Prices set to show savings vs baseline

## Testing the Workflow

After seeding:

1. **Sign up/Login** as a user
2. **Enter PLZ** (e.g., 30165 for Hannover)
3. **Browse dishes** - you should see dishes with pricing
4. **Filter by:**
   - Category (Hauptgericht, Dessert, etc.)
   - Chain (REWE, Lidl, ALDI)
   - Price (max price filter)
   - Quick meals (is_quick = TRUE)
5. **View savings** - dishes with offers show savings vs baseline price

## Expected Results

- **Dishes visible**: ~60 dishes
- **Offers active**: ~20 offers for current week
- **Pricing calculated**: Dishes show current offer prices when PLZ matches region
- **Savings displayed**: Dishes with offers show savings amount and percentage

## Troubleshooting

### No dishes showing?
- Check that `dishes` table has data
- Verify `dish_ingredients` relationships exist
- Check browser console for errors

### No pricing/savings?
- Verify `offers` table has data with current dates
- Check that user's PLZ maps to a region (see `postal_codes` table)
- Verify `ingredients` have `price_baseline_per_unit` set

### Foreign key errors?
- Make sure you imported in the correct order
- Check that all referenced IDs exist (ingredient_id, dish_id, region_id, etc.)

## Next Steps

After seeding:
1. Test the main workflow (browse, filter, view pricing)
2. Test favorites (paywall placeholder)
3. Test admin features (CSV import, data viewing)
4. Add more offers for different weeks
5. Add more postal codes for your target regions


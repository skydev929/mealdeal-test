# Seed Data Files

This directory contains SQL seed files to populate the database with working data.

## Quick Start

**Run this single file in Supabase SQL Editor:**
- `complete_seed.sql` - Contains ALL seed data in one file

Or run individual files in order:
1. `01_lookups.sql` - Categories and units
2. `02_chains_regions.sql` - Chains, regions, stores, postal codes
3. `03_ingredients_sample.sql` - Sample ingredients (100 items)
4. `04_dishes_sample.sql` - Sample dishes (60 items)
5. `05_dish_ingredients_sample.sql` - Dish-ingredient relationships
6. `06_offers_current.sql` - Current week offers

## File Descriptions

### `complete_seed.sql` ⭐ RECOMMENDED
- **One file with everything**
- Includes all essential data for demo
- ~30 ingredients, ~25 dishes, ~20 offers
- Ready to run immediately
- Best for quick testing

### Individual Files
- Use these if you want to customize or import incrementally
- `03_ingredients_sample.sql` - First 100 ingredients from CSV
- `04_dishes_sample.sql` - First 50 dishes + quick meals
- `05_dish_ingredients_sample.sql` - Relationships for those dishes
- `06_offers_current.sql` - Offers valid for current week

## What Gets Seeded

✅ **Lookup Tables**
- 14 categories (Hauptgericht, Dessert, etc.)
- 13 units (kg, l, st, g, ml, etc.)

✅ **Chains & Regions**
- 4 chains (REWE, Lidl, ALDI, Edeka)
- 7 advertising regions
- 7 stores (Hannover & Berlin)
- 20+ postal codes mapped to regions

✅ **Core Data**
- 30+ ingredients with baseline prices
- 25+ dishes (including 10 quick meals)
- Dish-ingredient relationships

✅ **Offers**
- 20+ current offers for this week
- Multiple chains (REWE, Lidl, ALDI)
- Popular ingredients (Spaghetti, Hackfleisch, etc.)

## After Seeding

1. **Test the app:**
   - Enter PLZ: `30165` (Hannover Nord)
   - Browse dishes - should see pricing
   - Filter by category, chain, price
   - View quick meals

2. **Verify data:**
   ```sql
   SELECT COUNT(*) FROM dishes; -- Should be ~25
   SELECT COUNT(*) FROM offers WHERE valid_to >= CURRENT_DATE; -- Should be ~20
   ```

3. **Test pricing:**
   ```sql
   SELECT * FROM calculate_dish_price('D115', '30165');
   ```

## Notes

- Offers are set for the **current week** (Monday to Sunday)
- Postal codes are for **Hannover** (301xx, 304xx) and **Berlin** (101xx, 104xx)
- For full dataset, use CSV import via Admin Dashboard
- See `docs/SEED_DATA_SETUP.md` for detailed instructions


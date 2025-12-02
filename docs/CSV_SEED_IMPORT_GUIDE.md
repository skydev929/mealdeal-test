# CSV Seed Data Import Guide

This guide explains how to import seed data via the Admin Dashboard CSV import feature.

## Import Order

Import files in this exact order to avoid foreign key constraint errors:

### 1. Lookup Tables (No dependencies)
- ✅ `seed_lookups_categories.csv` → Type: `lookups_categories`
- ✅ `seed_lookups_units.csv` → Type: `lookups_units`

### 2. Chains & Regions
- ✅ `seed_chains.csv` → Type: `chains`
- ✅ `seed_ad_regions.csv` → Type: `ad_regions`
- ✅ `seed_stores.csv` → Type: `stores`
- ✅ `seed_store_region_map.csv` → Type: `store_region_map`
- ✅ `seed_postal_codes.csv` → Type: `postal_codes` (if supported)

### 3. Core Data
- ✅ `seed_ingredients.csv` → Type: `ingredients`
- ✅ `seed_dishes.csv` → Type: `dishes`
- ✅ `seed_dish_ingredients.csv` → Type: `dish_ingredients`

### 4. Offers
- ✅ `seed_offers.csv` → Type: `offers`

## Step-by-Step Instructions

1. **Navigate to Admin Dashboard**
   - Go to the admin section in your app
   - Click on "CSV Import" or "Data Import"

2. **Import in Order**
   - Start with lookup tables
   - Then chains and regions
   - Then core data
   - Finally offers

3. **For Each File:**
   - Click "Choose File" or "Upload"
   - Select the CSV file from `data/` folder
   - Select the correct data type from dropdown
   - Check "Dry Run" first to validate
   - Review validation results
   - Uncheck "Dry Run" and click "Import"

4. **Verify Import**
   - Check the success message
   - Verify row counts match expected values
   - Test pricing by entering PLZ `30165` in the app

## File Locations

All seed CSV files are in the `data/` folder:

- `data/seed_lookups_categories.csv`
- `data/seed_lookups_units.csv`
- `data/seed_chains.csv`
- `data/seed_ad_regions.csv`
- `data/seed_stores.csv`
- `data/seed_store_region_map.csv`
- `data/seed_postal_codes.csv`
- `data/seed_ingredients.csv`
- `data/seed_dishes.csv`
- `data/seed_dish_ingredients.csv`
- `data/seed_offers.csv`

## Expected Results

After importing all files, you should have:

- ✅ 14 categories
- ✅ 13 units
- ✅ 4 chains
- ✅ 7 ad regions
- ✅ 7 stores
- ✅ 7 store-region mappings
- ✅ 20 postal codes
- ✅ 34 ingredients
- ✅ 25 dishes
- ✅ 45 dish-ingredient relationships
- ✅ 22 offers (valid for current week)

## Notes

### Offers Date Range
The `seed_offers.csv` file uses dates `2025-01-13` to `2025-01-19` (current week).
- If these dates are in the past, offers won't show up
- Update the dates in the CSV to match the current week
- Or use the SQL seed file which calculates dates dynamically

### Postal Codes
If `postal_codes` table is not supported by CSV import:
- Import via SQL Editor using `supabase/seed/02_chains_regions.sql`
- Or manually insert via Supabase dashboard

### Boolean Values
- `is_quick`, `is_meal_prep`, `optional`: Use `TRUE` or `FALSE` (uppercase)
- The CSV import should handle these correctly

## Troubleshooting

### Foreign Key Errors
- Make sure you imported in the correct order
- Check that referenced IDs exist (e.g., ingredient_id in dish_ingredients must exist in ingredients)

### Date Format Errors
- Offers dates must be in `YYYY-MM-DD` format
- Ensure dates are valid (valid_from <= valid_to)

### Unit Mismatch
- Units in `dish_ingredients` must exist in `lookups_units`
- Units in `ingredients.unit_default` must exist in `lookups_units`

### Zero Prices
- After importing, run migration `010_fix_offer_calculation.sql` if not already run
- Verify ingredients have `price_baseline_per_unit > 0`
- Check that offers are valid for current date

## Quick Test

After importing, test with:

1. Enter PLZ: `30165` (Hannover Nord)
2. You should see dishes with pricing
3. D115 (Chili con Carne) should show:
   - Base price: ~€9.53
   - Offer price: ~€7.20 (with REWE offers)
   - Savings: ~€2.33


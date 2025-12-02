# Diagnose CSV Import Errors

## Step 1: Check Browser Console

Open browser DevTools (F12) and check the Console tab. Look for:
- "CSV Import Result:" - shows the full result object
- "Edge function response:" - shows what the function returned
- Any error messages

## Step 2: Check Function Logs

1. Go to: https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr/functions/import-csv/logs
2. Look for error messages, especially:
   - Foreign key constraint violations
   - RLS policy violations
   - Data type mismatches

## Step 3: Verify Prerequisites

Before importing, make sure these are imported first:

### For `ingredients.csv`:
- ✅ `lookups_units.csv` must be imported first
- Check that all `unit_default` values in ingredients exist in lookups_units
- Common units: kg, l, st, g, ml, Bund, EL, TL, etc.

### For `dishes.csv`:
- ✅ `lookups_categories.csv` must be imported first
- Check that all `category` values in dishes exist in lookups_categories
- Common categories: Hauptgericht, Dessert, Snack, Süßspeise, Aufstrich

### For `dish_ingredients.csv`:
- ✅ `dishes.csv` must be imported first
- ✅ `ingredients.csv` must be imported first
- ✅ `lookups_units.csv` must be imported first
- Check that all `dish_id` values exist in dishes table
- Check that all `ingredient_id` values exist in ingredients table
- Check that all `unit` values exist in lookups_units table

### For `offers_csv.csv`:
- ✅ `ad_regions_csv.csv` must be imported first
- ✅ `ingredients.csv` must be imported first
- ✅ `lookups_units.csv` must be imported first
- Check that all `region_id` values exist in ad_regions table
- Check that all `ingredient_id` values exist in ingredients table (will auto-convert 1→I001, 2→I002, etc.)
- Check that all `unit_base` values exist in lookups_units table

## Step 4: Common Issues

### Issue: "Foreign key constraint violation"
**Solution**: Import prerequisite tables first (see order above)

### Issue: "Row-level security policy violation"
**Solution**: 
1. Set the service role key: `supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_key`
2. Redeploy function: `supabase functions deploy import-csv`

### Issue: "Invalid number" or "Invalid qty"
**Solution**: Check CSV for malformed numbers. Use comma (,) as decimal separator, not period (.)

### Issue: Unit mismatch
**Solution**: 
- Units are case-sensitive
- "kg" ≠ "Kg" ≠ "KG"
- Make sure units in ingredients match exactly with lookups_units

## Step 5: Test with Dry Run

Always use "Dry run" mode first to validate data before importing.

## Step 6: Check Database

Query the database to verify data exists:

```sql
-- Check if units exist
SELECT unit FROM lookups_units;

-- Check if categories exist
SELECT category FROM lookups_categories;

-- Check if ingredients exist
SELECT ingredient_id FROM ingredients LIMIT 10;

-- Check if dishes exist
SELECT dish_id FROM dishes LIMIT 10;
```


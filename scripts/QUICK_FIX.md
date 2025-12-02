# Quick Fix for Import Errors

## The Problem

The `ingredients.csv` file uses units (`kg`, `l`, `st`) that don't exist in `lookups_units.csv`. This causes foreign key constraint violations.

## Solution

I've updated the `lookups_units.csv` file to include the missing units. Now you need to:

1. **Re-import `lookups_units.csv`** with the updated file (it now includes kg, l, st)

2. **Then import in this order:**
   - ✅ lookups_categories
   - ✅ lookups_units (RE-IMPORT with updated file)
   - ✅ chains
   - ✅ ad_regions
   - ✅ stores
   - ✅ ingredients (should work now)
   - ✅ dishes
   - ✅ dish_ingredients
   - ✅ offers

## Alternative: Add Units via SQL

If you prefer, run this SQL in Supabase Dashboard:

```sql
INSERT INTO lookups_units (unit, description)
VALUES 
  ('kg', 'Kilogram'),
  ('l', 'Liter'),
  ('st', 'Stück')
ON CONFLICT (unit) DO NOTHING;
```

Then try importing ingredients again.

## Check Current Units

To see what units are currently in the database:

```sql
SELECT * FROM lookups_units ORDER BY unit;
```

## Verify Ingredients Can Import

After adding the units, test with dry run first, then import.


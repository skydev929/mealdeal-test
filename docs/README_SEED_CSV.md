# Seed CSV Files for Admin Dashboard Import

## Import Order

Import in this exact order:

1. `seed_lookups_categories.csv` → Type: `lookups_categories`
2. `seed_lookups_units.csv` → Type: `lookups_units`
3. `seed_chains.csv` → Type: `chains`
4. `seed_ad_regions.csv` → Type: `ad_regions`
5. `seed_stores.csv` → Type: `stores`
6. `seed_store_region_map.csv` → Type: `store_region_map`
7. `seed_ingredients.csv` → Type: `ingredients`
8. `seed_dishes.csv` → Type: `dishes`
9. `seed_dish_ingredients.csv` → Type: `dish_ingredients`
10. `seed_offers.csv` → Type: `offers`

## Important Notes

### Offers Dates
The `seed_offers.csv` uses dates `2025-01-13` to `2025-01-19`. 
- **Update these dates** to match the current week when importing
- Or use the SQL seed file which calculates dates automatically

### Boolean Values
- Use `TRUE` or `FALSE` (uppercase) for boolean fields
- Fields: `is_quick`, `is_meal_prep`, `optional`

### Allergen Tags
- Format: comma-separated values (e.g., `tk` or `tk,gluten`)
- Empty values should be left blank

## Quick Start

1. Go to Admin Dashboard → CSV Import
2. Import files in the order listed above
3. Use "Dry Run" first to validate
4. After import, test with PLZ `30165`

See `docs/CSV_SEED_IMPORT_GUIDE.md` for detailed instructions.


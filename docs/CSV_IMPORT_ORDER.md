# CSV Import Order

Import CSV files in this exact order to satisfy foreign key constraints:

## 1. Lookup Tables (No Dependencies)
- `lookups_categories.csv` - Categories lookup
- `lookups_units.csv` - Units lookup

## 2. Chains and Regions
- `chains_csv.csv` - Supermarket chains
- `ad_regions_csv.csv` - Advertising regions (depends on chains)
- `stores_csv.csv` - Store locations (depends on chains)
- `store_region_map_csv.csv` - Store-region mapping (depends on stores and regions)
- `postal_codes.csv` - PLZ to region mapping (depends on ad_regions) - **Create this file if missing**

## 3. Core Data
- `ingredients.csv` - Ingredients (depends on lookups_units)
- `dishes.csv` - Dishes (depends on lookups_categories)

## 4. Relationships
- `dish_ingredients.csv` - Dish-Ingredient relationships (depends on dishes and ingredients)

## 5. Offers and Mapping
- `offers_csv.csv` - Current offers (depends on ad_regions, ingredients, lookups_units)
- `product_map_csv.csv` - Product mapping (depends on ingredients)

## Important Notes

1. **Offers CSV**: The `ingredient_id` column should use text format (I001, I002, etc.) or numeric format (1, 2, 3) - the function will auto-convert numeric to text format.

2. **Foreign Key Errors**: If you get foreign key constraint errors:
   - Make sure you imported all prerequisite tables first
   - Check that referenced IDs exist (e.g., ingredient_id in offers must exist in ingredients table)
   - Verify unit values match exactly (case-sensitive)

3. **Dry Run First**: Always use "Dry run" mode first to validate data before importing.

4. **Error Messages**: Check the error messages in the console - they will tell you which foreign key constraint failed.


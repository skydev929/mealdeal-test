# Pricing Fix Documentation

## Problem
All dish card prices were showing as €0.00 in the UI.

## Root Cause
The `calculate_dish_price` function was not handling unit conversions properly:

1. **Unit Mismatch**: Ingredients have `price_baseline_per_unit` in their `unit_default` (e.g., `kg`, `l`, `st`), but dish ingredients use different units (e.g., `g`, `ml`, `Stück`).

2. **Example Issue**:
   - Ingredient I004 (Zucker) has `price_baseline_per_unit = 0.89` per `kg` (unit_default)
   - Dish D001 uses `2 EL` (tablespoons) of I004
   - Old calculation: `2 * 0.89 = 1.78` ❌ (wrong - mixing units)
   - New calculation: Converts units properly ✅

3. **Zero Prices**: Some ingredients have `price_baseline_per_unit = 0`, which is valid but means those ingredients don't contribute to pricing.

## Solution

### Migration: `005_fix_pricing_unit_conversion.sql`

1. **Created `convert_unit()` function**:
   - Converts between compatible units (g ↔ kg, ml ↔ l, st ↔ Stück)
   - Handles common unit aliases
   - Returns original qty if conversion not possible

2. **Updated `calculate_dish_price()` function**:
   - Converts dish ingredient quantities to ingredient's default unit before calculating price
   - Handles offer pricing with unit conversion
   - Only includes ingredients with valid prices (> 0)
   - Better error handling and rounding

### Key Changes

**Before:**
```sql
di.qty * i.price_baseline_per_unit  -- Wrong if units don't match!
```

**After:**
```sql
convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit  -- Correct!
```

## How to Apply

1. **Run the migration in Supabase SQL Editor:**
   ```sql
   -- Copy and paste contents of:
   supabase/migrations/005_fix_pricing_unit_conversion.sql
   ```

2. **Verify the fix:**
   ```sql
   -- Test pricing for a specific dish
   SELECT * FROM calculate_dish_price('D115', '30165');
   
   -- Should return non-zero prices if:
   -- - Dish has ingredients with price_baseline_per_unit > 0
   -- - Ingredients are properly linked in dish_ingredients
   ```

3. **Check browser console:**
   - Added logging to help debug pricing issues
   - Look for warnings about zero pricing
   - Check pricing calculations in console logs

## Expected Results

After applying the fix:
- ✅ Dishes with valid ingredient prices show correct pricing
- ✅ Unit conversions handled automatically (g → kg, ml → l)
- ✅ Offers properly applied when PLZ is set
- ✅ Savings calculated correctly
- ⚠️ Dishes with only zero-price ingredients will still show €0.00 (this is expected)

## Troubleshooting

### Still seeing €0.00?

1. **Check ingredient prices:**
   ```sql
   SELECT ingredient_id, name_canonical, unit_default, price_baseline_per_unit 
   FROM ingredients 
   WHERE price_baseline_per_unit IS NULL OR price_baseline_per_unit = 0
   LIMIT 10;
   ```

2. **Check dish ingredients:**
   ```sql
   SELECT di.*, i.price_baseline_per_unit, i.unit_default
   FROM dish_ingredients di
   JOIN ingredients i ON di.ingredient_id = i.ingredient_id
   WHERE di.dish_id = 'D115'
   AND di.optional = FALSE;
   ```

3. **Test pricing function directly:**
   ```sql
   SELECT * FROM calculate_dish_price('D115', '30165');
   ```

4. **Check browser console** for error messages or warnings

### Common Issues

- **No PLZ set**: Prices will use baseline prices (no offers applied)
- **No offers for region**: Prices will use baseline prices
- **All ingredients have price = 0**: Dish will show €0.00 (data issue)
- **Missing dish_ingredients**: Dish will show €0.00 (data issue)

## Unit Conversion Reference

| From | To | Conversion |
|------|-----|------------|
| g | kg | ÷ 1000 |
| kg | g | × 1000 |
| ml | l | ÷ 1000 |
| l | ml | × 1000 |
| Stück | st | × 1 (same) |
| st | Stück | × 1 (same) |

Other units (EL, TL, Bund, etc.) cannot be automatically converted and may need manual handling.


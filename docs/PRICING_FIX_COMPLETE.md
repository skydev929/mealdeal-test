# Complete Pricing Fix - Based on Seed Data

## Problem
All dish prices showing as €0.00 even after unit conversion fix.

## Root Cause Analysis

After analyzing the seed data, the issue is:

1. **Non-convertible units**: Some ingredients use units that can't be automatically converted:
   - `EL` (Esslöffel/Tablespoon) - e.g., I156 (Ketchup) in D117
   - `TL` (Teelöffel/Teaspoon) - e.g., I199 (Currypulver) in D117, D125
   - `Bund` (Bundle) - e.g., herbs
   - `Zehen` (Cloves) - e.g., I050 (Knoblauch) in D011

2. **Unit matching**: The function needs to handle case-insensitive unit matching (Stück vs st)

3. **Data validation**: Need to ensure only ingredients with valid prices are included

## Solution

### Migration: `007_complete_pricing_fix.sql`

This migration:

1. **Improved `convert_unit()` function**:
   - Case-insensitive unit matching
   - Returns `NULL` for non-convertible units (EL, TL, Bund, Zehen)
   - Only converts: g ↔ kg, ml ↔ l, Stück ↔ st

2. **Updated `calculate_dish_price()` function**:
   - Skips ingredients with non-convertible units (returns 0 for those)
   - Only calculates prices for ingredients with convertible units
   - Handles case-insensitive unit matching
   - Better NULL handling

## Expected Results

### Example: D115 (Chili con Carne)
- I020 (Rinderhackfleisch): 400g @ 15.73/kg = 0.4 × 15.73 = **6.29€**
- I022 (Tomaten): 400g @ 1.48/kg = 0.4 × 1.48 = **0.59€**
- I023 (Zwiebel): 1 Stück @ 2.65/st = 1 × 2.65 = **2.65€**
- **Total: ~9.53€** (excluding optional ingredients)

### Example: D117 (Currywurst)
- I153 (Bratwürste): 4 Stück @ 7.02/st = 4 × 7.02 = **28.08€**
- I156 (Ketchup): 2 EL - **SKIPPED** (can't convert EL to kg)
- I089 (Kartoffeln): 500g @ 0.8/kg = 0.5 × 0.8 = **0.40€**
- I199 (Currypulver): 1 TL - **SKIPPED** (can't convert TL to kg)
- **Total: ~28.48€**

### Example: D116 (Carbonara)
- I051 (Spaghetti): 250g @ 1.58/kg = 0.25 × 1.58 = **0.40€**
- I056 (Guanciale): 120g @ 29.9/kg = 0.12 × 29.9 = **3.59€**
- I003 (Eier): 3 Stück @ 1.99/st = 3 × 1.99 = **5.97€**
- I057 (Pecorino): 40g @ 23.95/kg = 0.04 × 23.95 = **0.96€**
- **Total: ~10.92€**

## How to Apply

1. **Run the migration in Supabase SQL Editor:**
   ```sql
   -- Copy and paste contents of:
   supabase/migrations/007_complete_pricing_fix.sql
   ```

2. **Verify the fix:**
   ```sql
   -- Test specific dishes from seed data
   SELECT * FROM calculate_dish_price('D115', '30165');
   SELECT * FROM calculate_dish_price('D116', '30165');
   SELECT * FROM calculate_dish_price('D117', '30165');
   SELECT * FROM calculate_dish_price('D124', '30165');
   SELECT * FROM calculate_dish_price('D126', '30165');
   ```

3. **Check browser console** for pricing logs

## Notes

- **Non-convertible units are skipped**: Ingredients using EL, TL, Bund, Zehen won't contribute to pricing
- **This is expected**: These units require manual conversion or lookup tables
- **Prices may be slightly lower**: Since some ingredients are skipped, total prices reflect only convertible ingredients
- **Optional ingredients**: Already excluded from calculations

## Future Improvements

To include non-convertible units, we could:
1. Create a lookup table for unit conversions (e.g., 1 EL = 15ml, 1 TL = 5ml)
2. Add conversion factors to the `lookups_units` table
3. Use estimates for common conversions

For now, skipping these units ensures accurate pricing for the majority of ingredients.


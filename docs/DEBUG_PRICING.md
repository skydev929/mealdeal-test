# Debugging Pricing Issues

## Quick Diagnostic Steps

### 1. Check if Migration Was Run

Run this in Supabase SQL Editor:

```sql
-- Check if function exists
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'calculate_dish_price';
```

If it doesn't return a row, the migration wasn't run.

### 2. Test the Function Directly

```sql
-- Test without PLZ (should use baseline prices)
SELECT * FROM calculate_dish_price('D115', NULL);

-- Test with PLZ (should use offers if available)
SELECT * FROM calculate_dish_price('D115', '30165');
```

### 3. Check Data Integrity

```sql
-- Check if ingredients have prices
SELECT ingredient_id, name_canonical, unit_default, price_baseline_per_unit
FROM ingredients
WHERE ingredient_id IN ('I020', 'I022', 'I023', 'I195')
ORDER BY ingredient_id;

-- Check dish_ingredients for D115
SELECT di.*, i.price_baseline_per_unit, i.unit_default
FROM dish_ingredients di
JOIN ingredients i ON di.ingredient_id = i.ingredient_id
WHERE di.dish_id = 'D115'
  AND di.optional = FALSE
ORDER BY di.ingredient_id;

-- Check if qty and unit are populated
SELECT 
  dish_id,
  ingredient_id,
  qty,
  unit,
  CASE 
    WHEN qty IS NULL OR qty = 0 THEN 'MISSING QTY'
    WHEN unit IS NULL OR unit = '' THEN 'MISSING UNIT'
    ELSE 'OK'
  END as status
FROM dish_ingredients
WHERE dish_id = 'D115'
  AND optional = FALSE;
```

### 4. Test Unit Conversion

```sql
-- Test convert_unit function
SELECT 
  convert_unit(400, 'g', 'kg') as g_to_kg,
  convert_unit(1, 'Stück', 'st') as stueck_to_st,
  convert_unit(250, 'ml', 'l') as ml_to_l,
  convert_unit(2, 'EL', 'kg') as el_to_kg;  -- Should return NULL
```

### 5. Check Browser Console

Open browser DevTools (F12) and check:
- Console tab for pricing logs
- Network tab for RPC calls
- Look for errors or warnings

### 6. Manual Calculation Check

For D115 (Chili con Carne), manually calculate:

```sql
-- Expected calculation:
-- I020: 400g @ 15.73/kg = 0.4 * 15.73 = 6.29
-- I022: 400g @ 1.48/kg = 0.4 * 1.48 = 0.59
-- I023: 1 Stück @ 2.65/st = 1 * 2.65 = 2.65
-- Total: ~9.53

SELECT 
  di.ingredient_id,
  i.name_canonical,
  di.qty,
  di.unit,
  i.unit_default,
  i.price_baseline_per_unit,
  convert_unit(di.qty, di.unit, i.unit_default) as qty_converted,
  CASE 
    WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
      di.qty * i.price_baseline_per_unit
    WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
      convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
    ELSE
      0
  END as calculated_price
FROM dish_ingredients di
JOIN ingredients i ON di.ingredient_id = i.ingredient_id
WHERE di.dish_id = 'D115'
  AND di.optional = FALSE
  AND i.price_baseline_per_unit IS NOT NULL
  AND i.price_baseline_per_unit > 0
ORDER BY calculated_price DESC;
```

## Common Issues

### Issue 1: All Prices are 0

**Possible causes:**
- Migration not run
- Ingredients missing prices (price_baseline_per_unit = 0 or NULL)
- dish_ingredients missing qty or unit values
- Unit conversion failing

**Solution:**
1. Run migration `008_simplified_pricing_fix.sql`
2. Check data integrity (see step 3 above)
3. Verify seed data was imported correctly

### Issue 2: Prices are Wrong

**Possible causes:**
- Unit conversion not working
- Wrong unit_default in ingredients
- Missing offers

**Solution:**
1. Test unit conversion (see step 4)
2. Check ingredient unit_default values
3. Verify offers are valid for current date

### Issue 3: Function Returns NULL

**Possible causes:**
- Function doesn't exist
- RPC call failing
- Database connection issue

**Solution:**
1. Check if function exists (see step 1)
2. Check browser console for RPC errors
3. Verify Supabase connection

## Next Steps

1. Run `scripts/test_pricing.sql` to get comprehensive diagnostics
2. Check browser console for detailed error messages
3. Verify seed data was imported correctly
4. Run migration `008_simplified_pricing_fix.sql` if not already run


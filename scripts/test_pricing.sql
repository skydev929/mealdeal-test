-- Test pricing function to debug issues
-- Run this in Supabase SQL Editor to see what's happening

-- First, check if we have the data
SELECT 'Ingredients with prices' as check_type, COUNT(*) as count
FROM ingredients 
WHERE price_baseline_per_unit IS NOT NULL AND price_baseline_per_unit > 0;

SELECT 'Dish ingredients for D115' as check_type, COUNT(*) as count
FROM dish_ingredients 
WHERE dish_id = 'D115' AND optional = FALSE;

-- Check ingredient prices for D115
SELECT 
  di.dish_id,
  di.ingredient_id,
  i.name_canonical,
  di.qty,
  di.unit as dish_unit,
  i.unit_default as ingredient_unit,
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
  AND i.price_baseline_per_unit > 0;

-- Test the pricing function
SELECT * FROM calculate_dish_price('D115', NULL);
SELECT * FROM calculate_dish_price('D115', '30165');

-- Check if postal codes are set up
SELECT 'Postal codes' as check_type, COUNT(*) as count FROM postal_codes WHERE plz = '30165';

-- Check if offers exist
SELECT 'Current offers' as check_type, COUNT(*) as count 
FROM offers 
WHERE valid_from <= CURRENT_DATE AND valid_to >= CURRENT_DATE;


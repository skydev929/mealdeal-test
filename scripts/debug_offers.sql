-- Debug script to check why offers aren't being applied
-- Run this in Supabase SQL Editor

-- 1. Check if offers exist and are valid
SELECT 
  'Current offers' as check_type,
  COUNT(*) as count,
  MIN(valid_from) as earliest_offer,
  MAX(valid_to) as latest_offer
FROM offers
WHERE valid_from <= CURRENT_DATE 
  AND valid_to >= CURRENT_DATE;

-- 2. Check offers for region 500 (Hannover Nord)
SELECT 
  'Offers for region 500' as check_type,
  ingredient_id,
  price_total,
  pack_size,
  unit_base,
  valid_from,
  valid_to,
  CASE 
    WHEN valid_from <= CURRENT_DATE AND valid_to >= CURRENT_DATE THEN 'VALID'
    ELSE 'EXPIRED'
  END as status
FROM offers
WHERE region_id = 500
ORDER BY ingredient_id;

-- 3. Check if PLZ 30165 maps to region 500
SELECT 
  'PLZ mapping' as check_type,
  plz,
  region_id,
  city
FROM postal_codes
WHERE plz = '30165';

-- 4. Check D115 ingredients and their offers
SELECT 
  di.dish_id,
  di.ingredient_id,
  i.name_canonical,
  di.qty,
  di.unit as dish_unit,
  i.unit_default as ingredient_unit,
  i.price_baseline_per_unit,
  -- Baseline price calculation
  CASE 
    WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
      di.qty * i.price_baseline_per_unit
    WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
      convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
    ELSE
      0
  END as baseline_price,
  -- Offer info
  o.offer_id,
  o.price_total as offer_price_total,
  o.pack_size as offer_pack_size,
  o.unit_base as offer_unit,
  o.valid_from,
  o.valid_to,
  -- Offer price calculation
  CASE 
    WHEN o.offer_id IS NOT NULL THEN
      CASE
        WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
          (di.qty / NULLIF(o.pack_size, 0)) * o.price_total
        WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
          (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
        ELSE
          NULL
      END
    ELSE
      NULL
  END as offer_price,
  CASE 
    WHEN o.offer_id IS NOT NULL AND o.valid_from <= CURRENT_DATE AND o.valid_to >= CURRENT_DATE THEN 'VALID OFFER'
    WHEN o.offer_id IS NOT NULL THEN 'EXPIRED OFFER'
    ELSE 'NO OFFER'
  END as offer_status
FROM dish_ingredients di
JOIN ingredients i ON di.ingredient_id = i.ingredient_id
LEFT JOIN offers o ON 
  o.ingredient_id = di.ingredient_id
  AND o.region_id = 500
WHERE di.dish_id = 'D115'
  AND di.optional = FALSE
  AND i.price_baseline_per_unit IS NOT NULL
  AND i.price_baseline_per_unit > 0
ORDER BY di.ingredient_id;

-- 5. Test the pricing function
SELECT * FROM calculate_dish_price('D115', '30165');
SELECT * FROM calculate_dish_price('D115', NULL);

-- 6. Compare baseline vs offer prices
SELECT 
  di.ingredient_id,
  i.name_canonical,
  di.qty,
  di.unit,
  -- Baseline
  CASE 
    WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
      di.qty * i.price_baseline_per_unit
    WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
      convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
    ELSE
      0
  END as baseline_price,
  -- Offer
  CASE 
    WHEN o.offer_id IS NOT NULL THEN
      CASE
        WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
          (di.qty / NULLIF(o.pack_size, 0)) * o.price_total
        WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
          (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
        ELSE
          NULL
      END
    ELSE
      NULL
  END as offer_price,
  -- Savings
  CASE 
    WHEN o.offer_id IS NOT NULL THEN
      CASE
        WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
          (di.qty * i.price_baseline_per_unit) - 
          CASE
            WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
              (di.qty / NULLIF(o.pack_size, 0)) * o.price_total
            WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
              (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
            ELSE
              di.qty * i.price_baseline_per_unit
          END
        WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
          (convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit) -
          CASE
            WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
              (di.qty / NULLIF(o.pack_size, 0)) * o.price_total
            WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
              (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
            ELSE
              convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
          END
        ELSE
          0
      END
    ELSE
      0
  END as savings
FROM dish_ingredients di
JOIN ingredients i ON di.ingredient_id = i.ingredient_id
LEFT JOIN offers o ON 
  o.ingredient_id = di.ingredient_id
  AND o.region_id = 500
  AND o.valid_from <= CURRENT_DATE
  AND o.valid_to >= CURRENT_DATE
WHERE di.dish_id = 'D115'
  AND di.optional = FALSE
  AND i.price_baseline_per_unit IS NOT NULL
  AND i.price_baseline_per_unit > 0
ORDER BY savings DESC NULLS LAST;


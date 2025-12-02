-- Complete pricing fix based on seed data
-- This version properly handles unit conversions and skips non-convertible units

-- Drop and recreate convert_unit function
DROP FUNCTION IF EXISTS convert_unit(DECIMAL, TEXT, TEXT);

CREATE OR REPLACE FUNCTION convert_unit(
  qty DECIMAL,
  from_unit TEXT,
  to_unit TEXT
) RETURNS DECIMAL AS $$
BEGIN
  -- If units are the same, return as-is
  IF LOWER(TRIM(from_unit)) = LOWER(TRIM(to_unit)) THEN
    RETURN qty;
  END IF;

  -- Convert weight units (g <-> kg)
  IF LOWER(TRIM(from_unit)) = 'g' AND LOWER(TRIM(to_unit)) = 'kg' THEN
    RETURN qty / 1000.0;
  END IF;
  IF LOWER(TRIM(from_unit)) = 'kg' AND LOWER(TRIM(to_unit)) = 'g' THEN
    RETURN qty * 1000.0;
  END IF;

  -- Convert volume units (ml <-> l)
  IF LOWER(TRIM(from_unit)) = 'ml' AND LOWER(TRIM(to_unit)) = 'l' THEN
    RETURN qty / 1000.0;
  END IF;
  IF LOWER(TRIM(from_unit)) = 'l' AND LOWER(TRIM(to_unit)) = 'ml' THEN
    RETURN qty * 1000.0;
  END IF;

  -- Handle piece units (Stück, st are the same)
  IF LOWER(TRIM(from_unit)) IN ('stück', 'st') AND LOWER(TRIM(to_unit)) IN ('stück', 'st') THEN
    RETURN qty;
  END IF;

  -- For non-standard units (EL, TL, Bund, Zehen, etc.), return NULL
  -- These cannot be automatically converted
  RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Complete calculate_dish_price function
CREATE OR REPLACE FUNCTION calculate_dish_price(
  _dish_id TEXT,
  _user_plz TEXT DEFAULT NULL
)
RETURNS TABLE (
  dish_id TEXT,
  base_price DECIMAL(10, 2),
  offer_price DECIMAL(10, 2),
  savings DECIMAL(10, 2),
  savings_percent DECIMAL(5, 2),
  available_offers_count INTEGER
) AS $$
DECLARE
  _region_id INTEGER;
  _base_total DECIMAL(10, 2) := 0;
  _offer_total DECIMAL(10, 2) := 0;
  _offers_count INTEGER := 0;
  _qty_converted DECIMAL(10, 3);
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL AND _user_plz != '' THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- Calculate base price (using baseline prices with unit conversion)
  -- Only include ingredients where units can be converted or already match
  SELECT COALESCE(SUM(
    CASE 
      -- Units already match
      WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
        di.qty * i.price_baseline_per_unit
      -- Units can be converted
      WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
        convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
      -- Can't convert (EL, TL, Bund, etc.) - skip this ingredient
      ELSE
        0
    END
  ), 0) INTO _base_total
  FROM dish_ingredients di
  JOIN ingredients i ON di.ingredient_id = i.ingredient_id
  WHERE di.dish_id = _dish_id
    AND di.optional = FALSE
    AND i.price_baseline_per_unit IS NOT NULL
    AND i.price_baseline_per_unit > 0;

  -- Calculate offer price (using current offers if region available)
  IF _region_id IS NOT NULL THEN
    SELECT COALESCE(SUM(
      CASE 
        WHEN o.offer_id IS NOT NULL THEN
          -- Has offer: try to use offer price
          CASE
            -- Units match offer unit
            WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
              (di.qty / NULLIF(o.pack_size, 0)) * o.price_total
            -- Can convert to offer unit
            WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
              (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
            -- Can't convert to offer unit, use baseline price
            ELSE
              CASE 
                WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
                  di.qty * i.price_baseline_per_unit
                WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
                  convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
                ELSE
                  0
              END
          END
        ELSE
          -- No offer: use baseline price with unit conversion
          CASE 
            WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
              di.qty * i.price_baseline_per_unit
            WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
              convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
            ELSE
              0
          END
      END
    ), 0) INTO _offer_total
    FROM dish_ingredients di
    JOIN ingredients i ON di.ingredient_id = i.ingredient_id
    LEFT JOIN offers o ON 
      o.ingredient_id = di.ingredient_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
    WHERE di.dish_id = _dish_id
      AND di.optional = FALSE
      AND i.price_baseline_per_unit IS NOT NULL
      AND i.price_baseline_per_unit > 0;
  ELSE
    -- No PLZ: use base price
    _offer_total := _base_total;
  END IF;

  -- Count available offers
  IF _region_id IS NOT NULL THEN
    SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
    FROM dish_ingredients di
    JOIN offers o ON o.ingredient_id = di.ingredient_id
    WHERE di.dish_id = _dish_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
      AND di.optional = FALSE;
  END IF;

  RETURN QUERY SELECT
    _dish_id,
    ROUND(COALESCE(_base_total, 0), 2),
    ROUND(COALESCE(_offer_total, 0), 2),
    ROUND(COALESCE(_base_total - _offer_total, 0), 2),
    CASE WHEN _base_total > 0 THEN
      ROUND(((_base_total - _offer_total) / _base_total * 100), 2)
    ELSE 0 END,
    COALESCE(_offers_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Test queries (should return non-zero prices)
-- SELECT * FROM calculate_dish_price('D115', '30165');  -- Chili con Carne
-- SELECT * FROM calculate_dish_price('D116', '30165');  -- Carbonara
-- SELECT * FROM calculate_dish_price('D117', '30165');  -- Currywurst
-- SELECT * FROM calculate_dish_price('D124', '30165');  -- Cremige Tomaten-Pasta
-- SELECT * FROM calculate_dish_price('D126', '30165');  -- Crêpes


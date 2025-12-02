-- Simplified and robust pricing fix
-- This version is more defensive and handles edge cases better

-- Drop and recreate convert_unit function
DROP FUNCTION IF EXISTS convert_unit(DECIMAL, TEXT, TEXT);

CREATE OR REPLACE FUNCTION convert_unit(
  qty DECIMAL,
  from_unit TEXT,
  to_unit TEXT
) RETURNS DECIMAL AS $$
BEGIN
  -- Handle NULL inputs
  IF qty IS NULL OR from_unit IS NULL OR to_unit IS NULL THEN
    RETURN NULL;
  END IF;

  -- Normalize units (trim and lowercase)
  from_unit := LOWER(TRIM(from_unit));
  to_unit := LOWER(TRIM(to_unit));

  -- If units are the same, return as-is
  IF from_unit = to_unit THEN
    RETURN qty;
  END IF;

  -- Convert weight units (g <-> kg)
  IF from_unit = 'g' AND to_unit = 'kg' THEN
    RETURN qty / 1000.0;
  END IF;
  IF from_unit = 'kg' AND to_unit = 'g' THEN
    RETURN qty * 1000.0;
  END IF;

  -- Convert volume units (ml <-> l)
  IF from_unit = 'ml' AND to_unit = 'l' THEN
    RETURN qty / 1000.0;
  END IF;
  IF from_unit = 'l' AND to_unit = 'ml' THEN
    RETURN qty * 1000.0;
  END IF;

  -- Handle piece units (Stück, st are the same)
  IF from_unit IN ('stück', 'st') AND to_unit IN ('stück', 'st') THEN
    RETURN qty;
  END IF;

  -- For non-standard units (EL, TL, Bund, Zehen, etc.), return NULL
  RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Simplified and robust calculate_dish_price function
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
  _ingredient_price DECIMAL(10, 2);
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL AND _user_plz != '' THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- Calculate base price: sum of all convertible ingredient prices
  FOR _ingredient_price IN
    SELECT 
      CASE 
        -- Units match exactly
        WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
          di.qty * i.price_baseline_per_unit
        -- Can convert units
        WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
          convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
        -- Can't convert - skip (return 0)
        ELSE
          0
      END
    FROM dish_ingredients di
    JOIN ingredients i ON di.ingredient_id = i.ingredient_id
    WHERE di.dish_id = _dish_id
      AND di.optional = FALSE
      AND di.qty IS NOT NULL
      AND di.qty > 0
      AND di.unit IS NOT NULL
      AND di.unit != ''
      AND i.price_baseline_per_unit IS NOT NULL
      AND i.price_baseline_per_unit > 0
  LOOP
    _base_total := _base_total + COALESCE(_ingredient_price, 0);
  END LOOP;

  -- Calculate offer price (using current offers if region available)
  IF _region_id IS NOT NULL THEN
    FOR _ingredient_price IN
      SELECT 
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
              -- Can't convert to offer unit, use baseline
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
            -- No offer: use baseline price
            CASE 
              WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
                di.qty * i.price_baseline_per_unit
              WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
                convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
              ELSE
                0
            END
        END
      FROM dish_ingredients di
      JOIN ingredients i ON di.ingredient_id = i.ingredient_id
      LEFT JOIN offers o ON 
        o.ingredient_id = di.ingredient_id
        AND o.region_id = _region_id
        AND o.valid_from <= CURRENT_DATE
        AND o.valid_to >= CURRENT_DATE
      WHERE di.dish_id = _dish_id
        AND di.optional = FALSE
        AND di.qty IS NOT NULL
        AND di.qty > 0
        AND di.unit IS NOT NULL
        AND di.unit != ''
        AND i.price_baseline_per_unit IS NOT NULL
        AND i.price_baseline_per_unit > 0
    LOOP
      _offer_total := _offer_total + COALESCE(_ingredient_price, 0);
    END LOOP;

    -- Count available offers
    SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
    FROM dish_ingredients di
    JOIN offers o ON o.ingredient_id = di.ingredient_id
    WHERE di.dish_id = _dish_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
      AND di.optional = FALSE
      AND di.qty IS NOT NULL
      AND di.qty > 0;
  ELSE
    -- No PLZ: use base price
    _offer_total := _base_total;
  END IF;

  -- Return results (ensure no NULL values)
  RETURN QUERY SELECT
    _dish_id,
    ROUND(COALESCE(_base_total, 0), 2)::DECIMAL(10, 2),
    ROUND(COALESCE(_offer_total, 0), 2)::DECIMAL(10, 2),
    ROUND(COALESCE(_base_total - _offer_total, 0), 2)::DECIMAL(10, 2),
    CASE WHEN COALESCE(_base_total, 0) > 0 THEN
      ROUND(((COALESCE(_base_total, 0) - COALESCE(_offer_total, 0)) / COALESCE(_base_total, 0) * 100), 2)::DECIMAL(5, 2)
    ELSE 0::DECIMAL(5, 2) END,
    COALESCE(_offers_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Test the function
-- SELECT * FROM calculate_dish_price('D115', NULL);
-- SELECT * FROM calculate_dish_price('D115', '30165');
-- SELECT * FROM calculate_dish_price('D116', '30165');
-- SELECT * FROM calculate_dish_price('D117', '30165');


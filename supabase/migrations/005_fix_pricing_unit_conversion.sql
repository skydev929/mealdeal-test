-- Fix calculate_dish_price function to handle unit conversions
-- The issue: ingredients have prices per unit_default (kg, l, st) but dish_ingredients use different units (g, ml, Stück)
-- We need to convert units properly

CREATE OR REPLACE FUNCTION convert_unit(
  qty DECIMAL,
  from_unit TEXT,
  to_unit TEXT
) RETURNS DECIMAL AS $$
BEGIN
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

  -- Handle piece units (Stück, st, Stück are the same)
  IF (from_unit IN ('Stück', 'st') AND to_unit IN ('Stück', 'st')) THEN
    RETURN qty;
  END IF;

  -- Handle common unit aliases
  IF from_unit = 'Stück' AND to_unit = 'st' THEN
    RETURN qty;
  END IF;
  IF from_unit = 'st' AND to_unit = 'Stück' THEN
    RETURN qty;
  END IF;

  -- For other units (EL, TL, Bund, etc.), we can't convert automatically
  -- Return qty as-is and let the pricing handle it (might need manual conversion)
  RETURN qty;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Updated calculate_dish_price function with unit conversion
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
  IF _user_plz IS NOT NULL THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- Calculate base price (using baseline prices with unit conversion)
  -- Only include ingredients with valid prices
  SELECT COALESCE(SUM(
    convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
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
          -- Convert dish ingredient qty to offer pack_size unit, then calculate price
          CASE
            -- If units match or can be converted
            WHEN di.unit = o.unit_base OR 
                 (di.unit = 'g' AND o.unit_base = 'kg') OR
                 (di.unit = 'ml' AND o.unit_base = 'l') OR
                 (di.unit = 'Stück' AND o.unit_base = 'st') OR
                 (di.unit = 'st' AND o.unit_base = 'Stück') THEN
              -- Convert qty to match offer unit
              (convert_unit(di.qty, di.unit, o.unit_base) / NULLIF(o.pack_size, 0)) * o.price_total
            ELSE
              -- Fallback: use baseline price if units don't match
              convert_unit(di.qty, di.unit, i.unit_default) * COALESCE(i.price_baseline_per_unit, 0)
          END
        ELSE
          -- No offer: use baseline price with unit conversion
          convert_unit(di.qty, di.unit, i.unit_default) * COALESCE(i.price_baseline_per_unit, 0)
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
    ROUND(_base_total, 2),
    ROUND(_offer_total, 2),
    ROUND(_base_total - _offer_total, 2),
    CASE WHEN _base_total > 0 THEN
      ROUND(((_base_total - _offer_total) / _base_total * 100), 2)
    ELSE 0 END,
    _offers_count;
END;
$$ LANGUAGE plpgsql;


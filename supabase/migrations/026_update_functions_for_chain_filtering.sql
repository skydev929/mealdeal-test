-- Update database functions to support chain_id filtering in offers
-- This migration adds chain_id parameter support to existing functions

-- ============================================================================
-- Step 1: Update should_display_dish to support chain_id filtering
-- ============================================================================

CREATE OR REPLACE FUNCTION should_display_dish(
  _dish_id TEXT,
  _region_id TEXT,
  _chain_id TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  _main_ingredients_with_offers INTEGER := 0;
  _secondary_ingredients_with_offers INTEGER := 0;
  _today DATE := CURRENT_DATE;
BEGIN
  -- If no region provided, don't display
  IF _region_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Count main ingredients with active offers (optionally filtered by chain_id)
  SELECT COUNT(DISTINCT di.ingredient_id) INTO _main_ingredients_with_offers
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
    AND (_chain_id IS NULL OR o.chain_id = _chain_id)
    AND (
      LOWER(TRIM(COALESCE(di.role, ''))) = 'main' 
      OR LOWER(TRIM(COALESCE(di.role, ''))) = 'hauptzutat'
    );

  -- If at least 1 main ingredient has an offer, display the dish
  IF _main_ingredients_with_offers >= 1 THEN
    RETURN TRUE;
  END IF;

  -- Count secondary ingredients with active offers (optionally filtered by chain_id)
  SELECT COUNT(DISTINCT di.ingredient_id) INTO _secondary_ingredients_with_offers
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
    AND (_chain_id IS NULL OR o.chain_id = _chain_id)
    AND (
      di.role IS NULL
      OR LOWER(TRIM(di.role)) = 'side'
      OR LOWER(TRIM(di.role)) = 'nebenzutat'
      OR LOWER(TRIM(di.role)) NOT IN ('main', 'hauptzutat')
    );

  -- If at least 2 secondary ingredients have offers, display the dish
  IF _secondary_ingredients_with_offers >= 2 THEN
    RETURN TRUE;
  END IF;

  -- Otherwise, don't display
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Step 2: Update calculate_ingredient_savings_per_unit to support chain_id
-- ============================================================================

-- Drop the existing function first to allow signature change
DROP FUNCTION IF EXISTS calculate_ingredient_savings_per_unit(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS calculate_ingredient_savings_per_unit(TEXT, TEXT);

CREATE OR REPLACE FUNCTION calculate_ingredient_savings_per_unit(
  _ingredient_id TEXT,
  _region_id TEXT,
  _chain_id TEXT DEFAULT NULL,
  _unit TEXT DEFAULT NULL  -- Optional: if provided, ensures unit matches
)
RETURNS TABLE (
  ingredient_id TEXT,
  base_price_per_unit DECIMAL(10, 4),
  offer_price_per_unit DECIMAL(10, 4),
  savings_per_unit DECIMAL(10, 4),
  unit TEXT,
  has_offer BOOLEAN
) AS $$
DECLARE
  _ingredient_unit TEXT;
  _base_price DECIMAL(10, 4);
  _lowest_offer_price_per_unit DECIMAL(10, 4);
  _today DATE := CURRENT_DATE;
BEGIN
  -- Get ingredient's default unit and base price
  SELECT i.unit_default, i.price_baseline_per_unit
  INTO _ingredient_unit, _base_price
  FROM ingredients i
  WHERE i.ingredient_id = _ingredient_id;

  -- If ingredient not found, return empty
  IF _ingredient_unit IS NULL OR _base_price IS NULL THEN
    RETURN;
  END IF;

  -- If unit parameter provided, check if it matches ingredient's default unit
  -- (or can be converted)
  IF _unit IS NOT NULL AND _unit != '' THEN
    -- Normalize units for comparison
    IF LOWER(TRIM(_unit)) != LOWER(TRIM(_ingredient_unit)) THEN
      -- Try to convert - if conversion not possible, return empty
      IF convert_unit(1.0, _unit, _ingredient_unit) IS NULL THEN
        RETURN;
      END IF;
    END IF;
  END IF;

  -- Get lowest offer price per unit for this ingredient in this region (optionally filtered by chain_id)
  SELECT MIN(o.price_total / NULLIF(o.pack_size, 0))
  INTO _lowest_offer_price_per_unit
  FROM offers o
  WHERE o.ingredient_id = _ingredient_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
    AND (_chain_id IS NULL OR o.chain_id = _chain_id)
    AND o.pack_size > 0;

  -- Return results
  RETURN QUERY SELECT
    _ingredient_id::TEXT,
    COALESCE(_base_price, 0)::DECIMAL(10, 4),
    COALESCE(_lowest_offer_price_per_unit, _base_price)::DECIMAL(10, 4),
    CASE 
      WHEN _lowest_offer_price_per_unit IS NOT NULL AND _lowest_offer_price_per_unit < _base_price THEN
        (_base_price - _lowest_offer_price_per_unit)::DECIMAL(10, 4)
      ELSE
        0::DECIMAL(10, 4)
    END,
    _ingredient_unit::TEXT,
    (_lowest_offer_price_per_unit IS NOT NULL)::BOOLEAN;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Step 3: Update calculate_dish_aggregated_savings to support chain_id
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_dish_aggregated_savings(
  _dish_id TEXT,
  _user_plz TEXT DEFAULT NULL,
  _chain_id TEXT DEFAULT NULL
)
RETURNS TABLE (
  dish_id TEXT,
  total_aggregated_savings DECIMAL(10, 2),
  ingredients_with_offers_count INTEGER,
  available_offers_count INTEGER
) AS $$
DECLARE
  _region_id TEXT;
  _total_savings DECIMAL(10, 2) := 0;
  _ingredients_with_offers INTEGER := 0;
  _offers_count INTEGER := 0;
  _ingredient_savings RECORD;
  _today DATE := CURRENT_DATE;
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL AND _user_plz != '' THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- If no region provided, return zeros
  IF _region_id IS NULL THEN
    RETURN QUERY SELECT
      _dish_id,
      0::DECIMAL(10, 2),
      0,
      0;
    RETURN;
  END IF;

  -- Calculate per-unit savings for each ingredient and aggregate
  FOR _ingredient_savings IN
    SELECT 
      di.ingredient_id,
      COALESCE(i.price_baseline_per_unit, 0) as baseline_price,
      COALESCE(MIN(o.price_total / NULLIF(o.pack_size, 0)), i.price_baseline_per_unit) as offer_price
    FROM dish_ingredients di
    JOIN ingredients i ON di.ingredient_id = i.ingredient_id
    LEFT JOIN offers o ON 
      o.ingredient_id = di.ingredient_id
      AND o.region_id = _region_id
      AND o.valid_from <= _today
      AND o.valid_to >= _today
      AND (_chain_id IS NULL OR o.chain_id = _chain_id)
      AND o.pack_size > 0
    WHERE di.dish_id = _dish_id
      AND di.optional = FALSE
      AND i.price_baseline_per_unit IS NOT NULL
      AND i.price_baseline_per_unit > 0
    GROUP BY di.ingredient_id, i.price_baseline_per_unit
  LOOP
    -- Calculate savings per unit
    IF _ingredient_savings.baseline_price > 0 AND _ingredient_savings.offer_price < _ingredient_savings.baseline_price THEN
      _total_savings := _total_savings + (_ingredient_savings.baseline_price - _ingredient_savings.offer_price);
      _ingredients_with_offers := _ingredients_with_offers + 1;
    END IF;
  END LOOP;

  -- Count total available offers for this dish (optionally filtered by chain_id)
  SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
    AND (_chain_id IS NULL OR o.chain_id = _chain_id);

  -- Return results
  RETURN QUERY SELECT
    _dish_id,
    ROUND(COALESCE(_total_savings, 0), 2)::DECIMAL(10, 2),
    COALESCE(_ingredients_with_offers, 0),
    COALESCE(_offers_count, 0);
END;
$$ LANGUAGE plpgsql;


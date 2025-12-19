-- Update calculate_dish_aggregated_savings to include side ingredients (optional = true)
-- Previously, only main ingredients (optional = false) were included in savings calculations
-- Now both main and side ingredients are included for consistency with the UI labels

-- Drop and recreate the function to remove the optional = FALSE filter
DROP FUNCTION IF EXISTS calculate_dish_aggregated_savings(TEXT, TEXT, TEXT);

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
  -- REMOVED: di.optional = FALSE filter to include both main and side ingredients
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
  -- This already includes all ingredients (main and side) - no change needed
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


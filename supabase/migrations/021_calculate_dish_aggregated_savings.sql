-- Calculate aggregated savings for a dish
-- This function sums up per-unit savings from all ingredients with active offers
-- It does NOT use dish_ingredients.qty or dish_ingredients.unit for calculations
-- dish_ingredients is only used to determine which ingredients belong to the dish

CREATE OR REPLACE FUNCTION calculate_dish_aggregated_savings(
  _dish_id TEXT,
  _user_plz TEXT DEFAULT NULL
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
  _today DATE := CURRENT_DATE;
  _ingredient_savings RECORD;
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL AND _user_plz != '' THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- If no region found, return zero savings
  IF _region_id IS NULL THEN
    RETURN QUERY SELECT
      _dish_id::TEXT,
      0::DECIMAL(10, 2),
      0::INTEGER,
      0::INTEGER;
    RETURN;
  END IF;

  -- Get all ingredients for this dish (from dish_ingredients - assignment only)
  -- Calculate per-unit savings for each ingredient that has an active offer
  FOR _ingredient_savings IN
    SELECT 
      di.ingredient_id,
      i.unit_default,
      i.price_baseline_per_unit,
      -- Get lowest offer price per unit
      MIN(o.price_total / NULLIF(o.pack_size, 0)) as lowest_offer_price_per_unit
    FROM dish_ingredients di
    JOIN ingredients i ON di.ingredient_id = i.ingredient_id
    LEFT JOIN offers o ON 
      o.ingredient_id = di.ingredient_id
      AND o.region_id = _region_id
      AND o.valid_from <= _today
      AND o.valid_to >= _today
      AND o.pack_size > 0
    WHERE di.dish_id = _dish_id
      AND i.price_baseline_per_unit IS NOT NULL
      AND i.price_baseline_per_unit > 0
    GROUP BY di.ingredient_id, i.unit_default, i.price_baseline_per_unit
    HAVING MIN(o.price_total / NULLIF(o.pack_size, 0)) IS NOT NULL
  LOOP
    -- Calculate savings per unit for this ingredient
    IF _ingredient_savings.lowest_offer_price_per_unit < _ingredient_savings.price_baseline_per_unit THEN
      _total_savings := _total_savings + 
        (_ingredient_savings.price_baseline_per_unit - _ingredient_savings.lowest_offer_price_per_unit);
      _ingredients_with_offers := _ingredients_with_offers + 1;
    END IF;
  END LOOP;

  -- Count total number of offers for this dish
  SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today;

  -- Return results
  RETURN QUERY SELECT
    _dish_id::TEXT,
    ROUND(COALESCE(_total_savings, 0), 2)::DECIMAL(10, 2),
    COALESCE(_ingredients_with_offers, 0)::INTEGER,
    COALESCE(_offers_count, 0)::INTEGER;
END;
$$ LANGUAGE plpgsql;


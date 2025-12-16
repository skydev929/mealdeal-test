-- Calculate per-unit savings for an ingredient
-- This function calculates savings per unit (kg/liter/piece) based on base price and lowest offer price
-- Formula: Savings per unit = Base Price per unit - Offer Price per unit

CREATE OR REPLACE FUNCTION calculate_ingredient_savings_per_unit(
  _ingredient_id TEXT,
  _region_id TEXT,
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

  -- Get lowest offer price per unit for this ingredient in this region
  SELECT MIN(o.price_total / NULLIF(o.pack_size, 0))
  INTO _lowest_offer_price_per_unit
  FROM offers o
  WHERE o.ingredient_id = _ingredient_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
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


-- Determine if a dish should be displayed based on offer availability
-- A dish is displayed if:
--   - At least 1 main ingredient has an active offer, OR
--   - At least 2 secondary ingredients have active offers
-- Main ingredients: role = 'main' or role = 'Hauptzutat'
-- Secondary ingredients: role = 'side', role = 'Nebenzutat', role IS NULL, or role != 'main'

CREATE OR REPLACE FUNCTION should_display_dish(
  _dish_id TEXT,
  _region_id TEXT
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

  -- Count main ingredients with active offers
  SELECT COUNT(DISTINCT di.ingredient_id) INTO _main_ingredients_with_offers
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
    AND (
      LOWER(TRIM(COALESCE(di.role, ''))) = 'main' 
      OR LOWER(TRIM(COALESCE(di.role, ''))) = 'hauptzutat'
    );

  -- If at least 1 main ingredient has an offer, display the dish
  IF _main_ingredients_with_offers >= 1 THEN
    RETURN TRUE;
  END IF;

  -- Count secondary ingredients with active offers
  SELECT COUNT(DISTINCT di.ingredient_id) INTO _secondary_ingredients_with_offers
  FROM dish_ingredients di
  JOIN offers o ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = _dish_id
    AND o.region_id = _region_id
    AND o.valid_from <= _today
    AND o.valid_to >= _today
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
$$ LANGUAGE plpgsql IMMUTABLE;


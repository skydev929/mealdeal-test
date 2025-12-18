-- Make qty and unit columns optional (nullable) in dish_ingredients table
-- This aligns with the new MVP requirement where dish_ingredients is for assignment only,
-- and quantities/units are optional (not used in calculations)

-- Drop NOT NULL constraint on qty column
ALTER TABLE dish_ingredients
  ALTER COLUMN qty DROP NOT NULL;

-- Drop NOT NULL constraint on unit column
ALTER TABLE dish_ingredients
  ALTER COLUMN unit DROP NOT NULL;

-- Note: The foreign key constraint on unit (dish_ingredients_unit_fkey) 
-- will automatically allow NULL values since foreign keys in PostgreSQL 
-- allow NULL by default (NULL means "no reference")

-- Add comments for documentation
COMMENT ON COLUMN dish_ingredients.qty IS 'Optional quantity (for reference only, not used in calculations)';
COMMENT ON COLUMN dish_ingredients.unit IS 'Optional unit (for reference only, not used in calculations). References lookups_units(unit) if provided.';


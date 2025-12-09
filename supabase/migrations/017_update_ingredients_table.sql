-- Migration: Update ingredients table to have exactly the specified columns
-- Columns: ingredient_id, name_canonical, unit_default, price_baseline_per_unit, allergen_tags, notes
-- This script ensures the table has exactly these columns with correct types and constraints

-- ============================================================================
-- Step 1: Remove timestamp columns (created_at, updated_at) if they exist
-- ============================================================================
-- These columns are not in the required column list, so we remove them

ALTER TABLE ingredients DROP COLUMN IF EXISTS created_at;
ALTER TABLE ingredients DROP COLUMN IF EXISTS updated_at;

-- ============================================================================
-- Step 2: Ensure column constraints are correct
-- ============================================================================

-- Ensure ingredient_id is PRIMARY KEY (should already be set)
-- Ensure name_canonical is NOT NULL
ALTER TABLE ingredients 
  ALTER COLUMN name_canonical SET NOT NULL;

-- Ensure unit_default is NOT NULL and has foreign key constraint
ALTER TABLE ingredients 
  ALTER COLUMN unit_default SET NOT NULL;

-- Ensure foreign key constraint on unit_default exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'ingredients_unit_default_fkey'
  ) THEN
    ALTER TABLE ingredients
      ADD CONSTRAINT ingredients_unit_default_fkey
      FOREIGN KEY (unit_default)
      REFERENCES lookups_units(unit);
  END IF;
END $$;

-- ============================================================================
-- Step 3: Add comments for documentation
-- ============================================================================

COMMENT ON TABLE ingredients IS 'Ingredient master data with baseline prices';
COMMENT ON COLUMN ingredients.ingredient_id IS 'Primary key: Unique ingredient identifier (e.g., I001, I002)';
COMMENT ON COLUMN ingredients.name_canonical IS 'Canonical ingredient name';
COMMENT ON COLUMN ingredients.unit_default IS 'Default unit of measurement (references lookups_units)';
COMMENT ON COLUMN ingredients.price_baseline_per_unit IS 'Baseline price per unit in default unit';
COMMENT ON COLUMN ingredients.allergen_tags IS 'Array of allergen tags (e.g., ["gluten", "dairy"])';
COMMENT ON COLUMN ingredients.notes IS 'Additional notes about the ingredient';

-- ============================================================================
-- Step 4: Verify table structure (optional - run manually)
-- ============================================================================
-- Run this query to verify the table structure:
/*
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'ingredients'
ORDER BY ordinal_position;
*/


-- Migration: Rollback changes from 017_update_ingredients_table.sql
-- This script restores the ingredients table to its previous state

-- ============================================================================
-- Step 1: Add back timestamp columns (created_at, updated_at)
-- ============================================================================

-- Add created_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'ingredients' AND column_name = 'created_at'
  ) THEN
    ALTER TABLE ingredients 
      ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- Add updated_at column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'ingredients' AND column_name = 'updated_at'
  ) THEN
    ALTER TABLE ingredients 
      ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- ============================================================================
-- Step 2: Revert constraint changes (make columns nullable if needed)
-- ============================================================================
-- Note: We can't easily determine if name_canonical was nullable before,
-- but if it has NULL values, we should make it nullable
-- Otherwise, keeping it NOT NULL is fine since it's a required field

-- Check if name_canonical should be nullable (only if it has NULL values)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM ingredients WHERE name_canonical IS NULL) THEN
    ALTER TABLE ingredients 
      ALTER COLUMN name_canonical DROP NOT NULL;
  END IF;
END $$;

-- Check if unit_default should be nullable (only if it has NULL values)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM ingredients WHERE unit_default IS NULL) THEN
    ALTER TABLE ingredients 
      ALTER COLUMN unit_default DROP NOT NULL;
  END IF;
END $$;

-- ============================================================================
-- Step 3: Keep the foreign key constraint (it should have been there anyway)
-- ============================================================================
-- We'll keep the foreign key constraint as it's part of the original schema
-- If it was added by migration 017, it's still a valid constraint

-- ============================================================================
-- Step 4: Remove comments added by migration 017 (optional)
-- ============================================================================

COMMENT ON TABLE ingredients IS NULL;
COMMENT ON COLUMN ingredients.ingredient_id IS NULL;
COMMENT ON COLUMN ingredients.name_canonical IS NULL;
COMMENT ON COLUMN ingredients.unit_default IS NULL;
COMMENT ON COLUMN ingredients.price_baseline_per_unit IS NULL;
COMMENT ON COLUMN ingredients.allergen_tags IS NULL;
COMMENT ON COLUMN ingredients.notes IS NULL;

-- ============================================================================
-- Verification Query
-- ============================================================================
-- Run this to verify the table structure matches the original:
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

-- Expected columns after rollback:
-- ingredient_id (TEXT, PRIMARY KEY)
-- name_canonical (TEXT, NOT NULL or nullable)
-- unit_default (TEXT, NOT NULL or nullable, FK)
-- price_baseline_per_unit (DECIMAL(10,2))
-- allergen_tags (TEXT[])
-- notes (TEXT)
-- created_at (TIMESTAMPTZ, DEFAULT NOW())
-- updated_at (TIMESTAMPTZ, DEFAULT NOW())


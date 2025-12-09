-- Migration: Fix offers.offer_id to be properly configured as SERIAL
-- This ensures offer_id auto-generates and doesn't require explicit values

-- ============================================================================
-- Step 1: Check current state of offer_id column
-- ============================================================================
-- Run this query first to see the current state:
/*
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'offers' AND column_name = 'offer_id';
*/

-- ============================================================================
-- Step 2: Drop and recreate offer_id as proper SERIAL
-- ============================================================================

-- First, drop the primary key constraint
ALTER TABLE offers DROP CONSTRAINT IF EXISTS offers_pkey;

-- Drop the column (this will fail if there are foreign key references, so check first)
-- If there are foreign keys, you'll need to drop them first
-- For now, we'll try to alter it instead

-- Option 1: If column is already INT4 but not SERIAL, convert it
-- Check if there's a sequence
DO $$
BEGIN
  -- Check if sequence exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_sequences WHERE sequencename = 'offers_offer_id_seq'
  ) THEN
    -- Create sequence
    CREATE SEQUENCE offers_offer_id_seq;
    
    -- Set the sequence to start from the max offer_id + 1
    PERFORM setval('offers_offer_id_seq', COALESCE((SELECT MAX(offer_id) FROM offers), 0) + 1, false);
    
    -- Set the default
    ALTER TABLE offers 
      ALTER COLUMN offer_id SET DEFAULT nextval('offers_offer_id_seq'::regclass);
    
    -- Make it NOT NULL if it isn't already
    ALTER TABLE offers 
      ALTER COLUMN offer_id SET NOT NULL;
  ELSE
    -- Sequence exists, just ensure default is set
    ALTER TABLE offers 
      ALTER COLUMN offer_id SET DEFAULT nextval('offers_offer_id_seq'::regclass);
    
    ALTER TABLE offers 
      ALTER COLUMN offer_id SET NOT NULL;
  END IF;
END $$;

-- Recreate primary key
ALTER TABLE offers ADD PRIMARY KEY (offer_id);

-- ============================================================================
-- Step 3: Verify the fix
-- ============================================================================
-- Run this to verify:
/*
SELECT 
  column_name,
  data_type,
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'offers' AND column_name = 'offer_id';
-- Should show: column_default = 'nextval(''offers_offer_id_seq''::regclass)'
*/

COMMENT ON COLUMN offers.offer_id IS 'Auto-incrementing primary key (SERIAL)';


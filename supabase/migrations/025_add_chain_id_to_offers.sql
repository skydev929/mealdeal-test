-- Add chain_id column to offers table
-- This links offers directly to chains, replacing the indirect relationship through ad_regions

-- Step 1: Add chain_id column (nullable first to allow data migration)
ALTER TABLE offers
  ADD COLUMN IF NOT EXISTS chain_id TEXT;

-- Step 2: Make chain_id NOT NULL and add foreign key constraint
-- Note: Existing data must be populated manually via CSV import with chain_id column
ALTER TABLE offers
  ALTER COLUMN chain_id SET NOT NULL;

ALTER TABLE offers
  ADD CONSTRAINT offers_chain_id_fkey
  FOREIGN KEY (chain_id)
  REFERENCES chains(chain_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Step 4: Add index for performance
CREATE INDEX IF NOT EXISTS idx_offers_chain_id ON offers(chain_id);

-- Step 5: Add comment
COMMENT ON COLUMN offers.chain_id IS 'Chain identifier (references chains.chain_id). Required.';


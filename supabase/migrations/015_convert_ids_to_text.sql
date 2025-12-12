-- Migration: Convert chain_id, region_id, and store_id from INTEGER to TEXT
-- This allows for more flexible ID formats similar to dish_id (e.g., C001, R001, S001)

-- Step 1: Drop all foreign key constraints that reference these columns
-- This must be done before altering column types

-- Drop foreign keys from ad_regions
ALTER TABLE ad_regions
  DROP CONSTRAINT IF EXISTS ad_regions_chain_id_fkey;

-- Drop foreign keys from stores
ALTER TABLE stores
  DROP CONSTRAINT IF EXISTS stores_chain_id_fkey;

-- Drop foreign keys from store_region_map
ALTER TABLE store_region_map
  DROP CONSTRAINT IF EXISTS store_region_map_store_id_fkey;

ALTER TABLE store_region_map
  DROP CONSTRAINT IF EXISTS store_region_map_region_id_fkey;

-- Drop foreign keys from postal_codes
ALTER TABLE postal_codes
  DROP CONSTRAINT IF EXISTS postal_codes_region_id_fkey;

-- Drop foreign keys from offers
ALTER TABLE offers
  DROP CONSTRAINT IF EXISTS offers_region_id_fkey;

-- Step 2: Convert existing integer data to text format (if data exists)
-- This step converts existing integer IDs to text format (e.g., 1 -> C001, 500 -> R500, 100 -> S100)
-- If tables are empty, this step will have no effect

-- Convert chains.chain_id from SERIAL to TEXT
-- First, create a temporary column
ALTER TABLE chains ADD COLUMN IF NOT EXISTS chain_id_new TEXT;

-- Convert existing chain_id values to text format (C001, C002, etc.)
UPDATE chains SET chain_id_new = 'C' || LPAD(chain_id::TEXT, 3, '0') WHERE chain_id_new IS NULL;

-- Make it NOT NULL
ALTER TABLE chains ALTER COLUMN chain_id_new SET NOT NULL;

-- Drop the old primary key constraint
ALTER TABLE chains DROP CONSTRAINT IF EXISTS chains_pkey;

-- Drop the old column and rename the new one
ALTER TABLE chains DROP COLUMN IF EXISTS chain_id;
ALTER TABLE chains RENAME COLUMN chain_id_new TO chain_id;

-- Recreate primary key
ALTER TABLE chains ADD PRIMARY KEY (chain_id);

-- Convert ad_regions.region_id from INTEGER to TEXT
ALTER TABLE ad_regions ADD COLUMN IF NOT EXISTS region_id_new TEXT;
UPDATE ad_regions SET region_id_new = 'R' || LPAD(region_id::TEXT, 3, '0') WHERE region_id_new IS NULL;
ALTER TABLE ad_regions ALTER COLUMN region_id_new SET NOT NULL;
ALTER TABLE ad_regions DROP CONSTRAINT IF EXISTS ad_regions_pkey;
ALTER TABLE ad_regions DROP COLUMN IF EXISTS region_id;
ALTER TABLE ad_regions RENAME COLUMN region_id_new TO region_id;
ALTER TABLE ad_regions ADD PRIMARY KEY (region_id);

-- Convert ad_regions.chain_id from INTEGER to TEXT
ALTER TABLE ad_regions ADD COLUMN IF NOT EXISTS chain_id_new TEXT;
UPDATE ad_regions SET chain_id_new = 'C' || LPAD(chain_id::TEXT, 3, '0') WHERE chain_id_new IS NULL;
ALTER TABLE ad_regions ALTER COLUMN chain_id_new SET NOT NULL;
ALTER TABLE ad_regions DROP COLUMN IF EXISTS chain_id;
ALTER TABLE ad_regions RENAME COLUMN chain_id_new TO chain_id;

-- Convert stores.store_id from INTEGER to TEXT
ALTER TABLE stores ADD COLUMN IF NOT EXISTS store_id_new TEXT;
UPDATE stores SET store_id_new = 'S' || LPAD(store_id::TEXT, 3, '0') WHERE store_id_new IS NULL;
ALTER TABLE stores ALTER COLUMN store_id_new SET NOT NULL;
ALTER TABLE stores DROP CONSTRAINT IF EXISTS stores_pkey;
ALTER TABLE stores DROP COLUMN IF EXISTS store_id;
ALTER TABLE stores RENAME COLUMN store_id_new TO store_id;
ALTER TABLE stores ADD PRIMARY KEY (store_id);

-- Convert stores.chain_id from INTEGER to TEXT
ALTER TABLE stores ADD COLUMN IF NOT EXISTS chain_id_new TEXT;
UPDATE stores SET chain_id_new = 'C' || LPAD(chain_id::TEXT, 3, '0') WHERE chain_id_new IS NULL;
ALTER TABLE stores ALTER COLUMN chain_id_new SET NOT NULL;
ALTER TABLE stores DROP COLUMN IF EXISTS chain_id;
ALTER TABLE stores RENAME COLUMN chain_id_new TO chain_id;

-- Convert store_region_map.store_id from INTEGER to TEXT
ALTER TABLE store_region_map ADD COLUMN IF NOT EXISTS store_id_new TEXT;
UPDATE store_region_map SET store_id_new = 'S' || LPAD(store_id::TEXT, 3, '0') WHERE store_id_new IS NULL;
ALTER TABLE store_region_map ALTER COLUMN store_id_new SET NOT NULL;
ALTER TABLE store_region_map DROP CONSTRAINT IF EXISTS store_region_map_pkey;
ALTER TABLE store_region_map DROP COLUMN IF EXISTS store_id;
ALTER TABLE store_region_map RENAME COLUMN store_id_new TO store_id;

-- Convert store_region_map.region_id from INTEGER to TEXT
ALTER TABLE store_region_map ADD COLUMN IF NOT EXISTS region_id_new TEXT;
UPDATE store_region_map SET region_id_new = 'R' || LPAD(region_id::TEXT, 3, '0') WHERE region_id_new IS NULL;
ALTER TABLE store_region_map ALTER COLUMN region_id_new SET NOT NULL;
ALTER TABLE store_region_map DROP COLUMN IF EXISTS region_id;
ALTER TABLE store_region_map RENAME COLUMN region_id_new TO region_id;
ALTER TABLE store_region_map ADD PRIMARY KEY (store_id, region_id);

-- Convert postal_codes.region_id from INTEGER to TEXT
ALTER TABLE postal_codes ADD COLUMN IF NOT EXISTS region_id_new TEXT;
UPDATE postal_codes SET region_id_new = 'R' || LPAD(region_id::TEXT, 3, '0') WHERE region_id_new IS NULL;
ALTER TABLE postal_codes ALTER COLUMN region_id_new SET NOT NULL;
ALTER TABLE postal_codes DROP COLUMN IF EXISTS region_id;
ALTER TABLE postal_codes RENAME COLUMN region_id_new TO region_id;

-- Convert offers.region_id from INTEGER to TEXT
ALTER TABLE offers ADD COLUMN IF NOT EXISTS region_id_new TEXT;
UPDATE offers SET region_id_new = 'R' || LPAD(region_id::TEXT, 3, '0') WHERE region_id_new IS NULL;
ALTER TABLE offers ALTER COLUMN region_id_new SET NOT NULL;
ALTER TABLE offers DROP COLUMN IF EXISTS region_id;
ALTER TABLE offers RENAME COLUMN region_id_new TO region_id;

-- Step 3: Recreate all foreign key constraints with CASCADE options

-- Ad Regions: chain_id
ALTER TABLE ad_regions
  ADD CONSTRAINT ad_regions_chain_id_fkey
  FOREIGN KEY (chain_id)
  REFERENCES chains(chain_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Stores: chain_id
ALTER TABLE stores
  ADD CONSTRAINT stores_chain_id_fkey
  FOREIGN KEY (chain_id)
  REFERENCES chains(chain_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Store Region Map: store_id
ALTER TABLE store_region_map
  ADD CONSTRAINT store_region_map_store_id_fkey
  FOREIGN KEY (store_id)
  REFERENCES stores(store_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Store Region Map: region_id
ALTER TABLE store_region_map
  ADD CONSTRAINT store_region_map_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Postal Codes: region_id
ALTER TABLE postal_codes
  ADD CONSTRAINT postal_codes_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Offers: region_id
ALTER TABLE offers
  ADD CONSTRAINT offers_region_id_fkey
  FOREIGN KEY (region_id)
  REFERENCES ad_regions(region_id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- Step 4: Update the calculate_dish_price function to use TEXT for region_id

CREATE OR REPLACE FUNCTION calculate_dish_price(
  _dish_id TEXT,
  _user_plz TEXT DEFAULT NULL
)
RETURNS TABLE (
  dish_id TEXT,
  base_price DECIMAL(10, 2),
  offer_price DECIMAL(10, 2),
  savings DECIMAL(10, 2),
  savings_percent DECIMAL(5, 2),
  available_offers_count INTEGER
) AS $$
DECLARE
  _region_id TEXT;  -- Changed from INTEGER to TEXT
  _base_total DECIMAL(10, 2) := 0;
  _offer_total DECIMAL(10, 2) := 0;
  _offers_count INTEGER := 0;
  _ingredient_price DECIMAL(10, 2);
  _offer_price DECIMAL(10, 2);
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL AND _user_plz != '' THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- Calculate base price: sum of all convertible ingredient prices
  SELECT COALESCE(SUM(
    CASE 
      -- Units match exactly
      WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
        di.qty * i.price_baseline_per_unit
      -- Can convert units
      WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
        convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
      -- Can't convert - skip (return 0)
      ELSE
        0
    END
  ), 0) INTO _base_total
  FROM dish_ingredients di
  JOIN ingredients i ON di.ingredient_id = i.ingredient_id
  WHERE di.dish_id = _dish_id
    AND di.optional = FALSE
    AND di.qty IS NOT NULL
    AND di.qty > 0
    AND di.unit IS NOT NULL
    AND di.unit != ''
    AND i.price_baseline_per_unit IS NOT NULL
    AND i.price_baseline_per_unit > 0;

  -- Calculate offer price (using current offers if region available)
  IF _region_id IS NOT NULL THEN
    -- Calculate offer price for each ingredient
    FOR _ingredient_price, _offer_price IN
      SELECT 
        -- Baseline price
        CASE 
          WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
            di.qty * i.price_baseline_per_unit
          WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
            convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
          ELSE
            0
        END,
        -- Offer price (if available)
        CASE 
          WHEN o.offer_id IS NOT NULL THEN
            -- Has offer: calculate offer price
            CASE
              -- Units match offer unit exactly
              WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(o.unit_base)) THEN
                -- Calculate: (qty / pack_size) * price_total
                CASE 
                  WHEN o.pack_size > 0 THEN
                    (di.qty / o.pack_size) * o.price_total
                  ELSE
                    di.qty * i.price_baseline_per_unit
                END
              -- Can convert to offer unit
              WHEN convert_unit(di.qty, di.unit, o.unit_base) IS NOT NULL THEN
                -- Convert qty to offer unit, then calculate
                CASE 
                  WHEN o.pack_size > 0 THEN
                    (convert_unit(di.qty, di.unit, o.unit_base) / o.pack_size) * o.price_total
                  ELSE
                    convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
                END
              -- Can't convert to offer unit, use baseline
              ELSE
                CASE 
                  WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
                    di.qty * i.price_baseline_per_unit
                  WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
                    convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
                  ELSE
                    0
                END
            END
          ELSE
            -- No offer: use baseline price
            CASE 
              WHEN LOWER(TRIM(di.unit)) = LOWER(TRIM(i.unit_default)) THEN
                di.qty * i.price_baseline_per_unit
              WHEN convert_unit(di.qty, di.unit, i.unit_default) IS NOT NULL THEN
                convert_unit(di.qty, di.unit, i.unit_default) * i.price_baseline_per_unit
              ELSE
                0
            END
        END
      FROM dish_ingredients di
      JOIN ingredients i ON di.ingredient_id = i.ingredient_id
      LEFT JOIN offers o ON 
        o.ingredient_id = di.ingredient_id
        AND o.region_id = _region_id
        AND o.valid_from <= CURRENT_DATE
        AND o.valid_to >= CURRENT_DATE
      WHERE di.dish_id = _dish_id
        AND di.optional = FALSE
        AND di.qty IS NOT NULL
        AND di.qty > 0
        AND di.unit IS NOT NULL
        AND di.unit != ''
        AND i.price_baseline_per_unit IS NOT NULL
        AND i.price_baseline_per_unit > 0
    LOOP
      _offer_total := _offer_total + COALESCE(_offer_price, _ingredient_price, 0);
    END LOOP;

    -- Count available offers
    SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
    FROM dish_ingredients di
    JOIN offers o ON o.ingredient_id = di.ingredient_id
    WHERE di.dish_id = _dish_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
      AND di.optional = FALSE
      AND di.qty IS NOT NULL
      AND di.qty > 0;
  ELSE
    -- No PLZ: use base price
    _offer_total := _base_total;
  END IF;

  -- Return results (ensure no NULL values)
  RETURN QUERY SELECT
    _dish_id::TEXT,
    ROUND(COALESCE(_base_total, 0), 2)::DECIMAL(10, 2),
    ROUND(COALESCE(_offer_total, 0), 2)::DECIMAL(10, 2),
    ROUND(COALESCE(_base_total - _offer_total, 0), 2)::DECIMAL(10, 2),
    CASE WHEN COALESCE(_base_total, 0) > 0 THEN
      ROUND(((COALESCE(_base_total, 0) - COALESCE(_offer_total, 0)) / COALESCE(_base_total, 0) * 100), 2)::DECIMAL(5, 2)
    ELSE 0::DECIMAL(5, 2) END,
    COALESCE(_offers_count, 0);
END;
$$ LANGUAGE plpgsql;

-- Step 5: Update indexes (they should work with TEXT, but verify)
-- The existing indexes should continue to work with TEXT columns
-- No changes needed for indexes

-- Step 6: Add comments for documentation
COMMENT ON COLUMN chains.chain_id IS 'Chain identifier in TEXT format (e.g., C001, C002)';
COMMENT ON COLUMN ad_regions.region_id IS 'Region identifier in TEXT format (e.g., R500, R501)';
COMMENT ON COLUMN ad_regions.chain_id IS 'Chain identifier in TEXT format (references chains.chain_id)';
COMMENT ON COLUMN stores.store_id IS 'Store identifier in TEXT format (e.g., S100, S101)';
COMMENT ON COLUMN stores.chain_id IS 'Chain identifier in TEXT format (references chains.chain_id)';
COMMENT ON COLUMN store_region_map.store_id IS 'Store identifier in TEXT format (references stores.store_id)';
COMMENT ON COLUMN store_region_map.region_id IS 'Region identifier in TEXT format (references ad_regions.region_id)';
COMMENT ON COLUMN postal_codes.region_id IS 'Region identifier in TEXT format (references ad_regions.region_id)';
COMMENT ON COLUMN offers.region_id IS 'Region identifier in TEXT format (references ad_regions.region_id)';








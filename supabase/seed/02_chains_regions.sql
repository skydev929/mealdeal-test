-- Seed Data: Chains, Regions, Stores, and Postal Codes
-- Import order: chains -> ad_regions -> stores -> store_region_map -> postal_codes

-- Chains
INSERT INTO chains (chain_id, chain_name) VALUES
  (10, 'REWE'),
  (11, 'Lidl'),
  (12, 'ALDI'),
  (13, 'Edeka')
ON CONFLICT (chain_id) DO UPDATE SET chain_name = EXCLUDED.chain_name;

-- Ad Regions (Advertising regions)
INSERT INTO ad_regions (region_id, chain_id, label) VALUES
  (500, 10, 'REWE_H_NORD'),
  (501, 10, 'REWE_H_SUED'),
  (502, 10, 'REWE_B_BERLIN'),
  (510, 11, 'LIDL_H_WEST'),
  (511, 11, 'LIDL_B_BERLIN'),
  (520, 12, 'ALDI_H_NORD'),
  (521, 12, 'ALDI_B_BERLIN')
ON CONFLICT (region_id) DO UPDATE SET chain_id = EXCLUDED.chain_id, label = EXCLUDED.label;

-- Stores
INSERT INTO stores (store_id, chain_id, store_name, plz, city, street) VALUES
  (1000, 10, 'REWE Hannover Nord', '30165', 'Hannover', NULL),
  (1001, 10, 'REWE Hannover Südstadt', '30171', 'Hannover', NULL),
  (1002, 10, 'REWE Berlin Mitte', '10115', 'Berlin', NULL),
  (1100, 11, 'Lidl Hannover Linden', '30449', 'Hannover', NULL),
  (1101, 11, 'Lidl Berlin Prenzlauer Berg', '10437', 'Berlin', NULL),
  (1200, 12, 'ALDI Hannover Nord', '30165', 'Hannover', NULL),
  (1201, 12, 'ALDI Berlin Mitte', '10115', 'Berlin', NULL)
ON CONFLICT (store_id) DO UPDATE SET 
  chain_id = EXCLUDED.chain_id,
  store_name = EXCLUDED.store_name,
  plz = EXCLUDED.plz,
  city = EXCLUDED.city;

-- Store-Region Mapping
INSERT INTO store_region_map (store_id, region_id) VALUES
  (1000, 500),
  (1001, 501),
  (1002, 502),
  (1100, 510),
  (1101, 511),
  (1200, 520),
  (1201, 521)
ON CONFLICT (store_id, region_id) DO NOTHING;

-- Postal Codes (PLZ) to Region Mapping
-- This maps German postal codes to advertising regions
INSERT INTO postal_codes (plz, region_id, city) VALUES
  -- Hannover area (301xx) -> REWE and Lidl regions
  ('30165', 500, 'Hannover'),
  ('30166', 500, 'Hannover'),
  ('30167', 500, 'Hannover'),
  ('30168', 500, 'Hannover'),
  ('30169', 500, 'Hannover'),
  ('30170', 501, 'Hannover'),
  ('30171', 501, 'Hannover'),
  ('30172', 501, 'Hannover'),
  ('30173', 501, 'Hannover'),
  ('30174', 501, 'Hannover'),
  ('30175', 501, 'Hannover'),
  ('30176', 501, 'Hannover'),
  ('30177', 501, 'Hannover'),
  ('30178', 501, 'Hannover'),
  ('30179', 501, 'Hannover'),
  ('30449', 510, 'Hannover'),
  ('30450', 510, 'Hannover'),
  ('30451', 510, 'Hannover'),
  ('30452', 510, 'Hannover'),
  ('30453', 510, 'Hannover'),
  -- Berlin area (101xx, 104xx) -> Berlin regions
  ('10115', 502, 'Berlin'),
  ('10117', 502, 'Berlin'),
  ('10119', 502, 'Berlin'),
  ('10437', 511, 'Berlin'),
  ('10435', 511, 'Berlin'),
  ('10439', 511, 'Berlin')
ON CONFLICT (plz) DO UPDATE SET region_id = EXCLUDED.region_id, city = EXCLUDED.city;


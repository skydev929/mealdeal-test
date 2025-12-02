-- Complete Seed Data for MealDeal MVP
-- This file contains all seed data needed to demonstrate the app workflow
-- Run this entire file in Supabase SQL Editor

BEGIN;

-- ============================================
-- 1. LOOKUP TABLES
-- ============================================

-- Categories
INSERT INTO lookups_categories (category) VALUES
  ('Aufstrich'), ('Beilage'), ('Dessert'), ('Frühstück'), ('Getränk'),
  ('Hauptgericht'), ('Hauptgericht (vegetarisch)'), ('Hauptgericht (vegan)'),
  ('Pasta'), ('Salat'), ('Snack'), ('Suppe'), ('Süßspeise'), ('Vorspeise')
ON CONFLICT (category) DO NOTHING;

-- Units
INSERT INTO lookups_units (unit, description) VALUES
  ('Bund', 'Bundle'), ('EL', 'Esslöffel'), ('Päckchen', 'Package'),
  ('Rolle', 'Roll'), ('Streifen', 'Strip'), ('Stück', 'Piece'),
  ('TL', 'Teelöffel'), ('Zehen', 'Clove'), ('g', 'Gram'),
  ('ml', 'Milliliter'), ('kg', 'Kilogram'), ('l', 'Liter'), ('st', 'Stück')
ON CONFLICT (unit) DO NOTHING;

-- ============================================
-- 2. CHAINS & REGIONS
-- ============================================

-- Chains
INSERT INTO chains (chain_id, chain_name) VALUES
  (10, 'REWE'), (11, 'Lidl'), (12, 'ALDI'), (13, 'Edeka')
ON CONFLICT (chain_id) DO UPDATE SET chain_name = EXCLUDED.chain_name;

-- Ad Regions
INSERT INTO ad_regions (region_id, chain_id, label) VALUES
  (500, 10, 'REWE_H_NORD'), (501, 10, 'REWE_H_SUED'), (502, 10, 'REWE_B_BERLIN'),
  (510, 11, 'LIDL_H_WEST'), (511, 11, 'LIDL_B_BERLIN'),
  (520, 12, 'ALDI_H_NORD'), (521, 12, 'ALDI_B_BERLIN')
ON CONFLICT (region_id) DO UPDATE SET chain_id = EXCLUDED.chain_id, label = EXCLUDED.label;

-- Stores
INSERT INTO stores (store_id, chain_id, store_name, plz, city) VALUES
  (1000, 10, 'REWE Hannover Nord', '30165', 'Hannover'),
  (1001, 10, 'REWE Hannover Südstadt', '30171', 'Hannover'),
  (1002, 10, 'REWE Berlin Mitte', '10115', 'Berlin'),
  (1100, 11, 'Lidl Hannover Linden', '30449', 'Hannover'),
  (1101, 11, 'Lidl Berlin Prenzlauer Berg', '10437', 'Berlin'),
  (1200, 12, 'ALDI Hannover Nord', '30165', 'Hannover'),
  (1201, 12, 'ALDI Berlin Mitte', '10115', 'Berlin')
ON CONFLICT (store_id) DO UPDATE SET
  chain_id = EXCLUDED.chain_id, store_name = EXCLUDED.store_name, plz = EXCLUDED.plz, city = EXCLUDED.city;

-- Store-Region Mapping
INSERT INTO store_region_map (store_id, region_id) VALUES
  (1000, 500), (1001, 501), (1002, 502),
  (1100, 510), (1101, 511),
  (1200, 520), (1201, 521)
ON CONFLICT (store_id, region_id) DO NOTHING;

-- Postal Codes (PLZ to Region mapping)
INSERT INTO postal_codes (plz, region_id, city) VALUES
  -- Hannover area
  ('30165', 500, 'Hannover'), ('30166', 500, 'Hannover'), ('30167', 500, 'Hannover'),
  ('30168', 500, 'Hannover'), ('30169', 500, 'Hannover'),
  ('30170', 501, 'Hannover'), ('30171', 501, 'Hannover'), ('30172', 501, 'Hannover'),
  ('30173', 501, 'Hannover'), ('30174', 501, 'Hannover'), ('30175', 501, 'Hannover'),
  ('30449', 510, 'Hannover'), ('30450', 510, 'Hannover'), ('30451', 510, 'Hannover'),
  -- Berlin area
  ('10115', 502, 'Berlin'), ('10117', 502, 'Berlin'), ('10119', 502, 'Berlin'),
  ('10437', 511, 'Berlin'), ('10435', 511, 'Berlin'), ('10439', 511, 'Berlin')
ON CONFLICT (plz) DO UPDATE SET region_id = EXCLUDED.region_id, city = EXCLUDED.city;

-- ============================================
-- 3. INGREDIENTS (Essential ingredients for demo)
-- ============================================

INSERT INTO ingredients (ingredient_id, name_canonical, unit_default, price_baseline_per_unit, allergen_tags, notes) VALUES
  ('I001', 'Printen', 'kg', 0, NULL, NULL),
  ('I002', 'Sahne', 'l', 3.75, NULL, NULL),
  ('I003', 'Eier', 'st', 1.99, NULL, NULL),
  ('I004', 'Zucker', 'kg', 0.89, NULL, NULL),
  ('I020', 'Rinderhackfleisch', 'kg', 15.73, NULL, NULL),
  ('I021', 'Eier', 'st', 1.99, NULL, NULL),
  ('I022', 'Tomaten (stückig, Dose)', 'kg', 1.48, NULL, NULL),
  ('I023', 'Zwiebel', 'st', 2.65, NULL, NULL),
  ('I026', 'Äpfel', 'st', 2.29, NULL, NULL),
  ('I030', 'Milch', 'l', 0.99, NULL, NULL),
  ('I031', 'Mehl (Weizen)', 'kg', 0.59, NULL, NULL),
  ('I044', 'Tofu', 'kg', 5.48, NULL, NULL),
  ('I045', 'Brokkoli', 'kg', 2.39, ARRAY['tk'], NULL),
  ('I046', 'Paprika (rot)', 'st', 2.9, NULL, NULL),
  ('I051', 'Spaghetti', 'kg', 1.58, NULL, NULL),
  ('I052', 'Olivenöl', 'l', 7.99, NULL, NULL),
  ('I050', 'Knoblauch', 'kg', 6.95, NULL, NULL),
  ('I053', 'Chiliflocken', 'kg', 42.57, NULL, NULL),
  ('I054', 'Parmesan', 'kg', 19.95, NULL, NULL),
  ('I056', 'Guanciale', 'kg', 29.9, NULL, NULL),
  ('I057', 'Pecorino Romano', 'kg', 23.95, NULL, NULL),
  ('I058', 'Penne', 'kg', 1.58, NULL, NULL),
  ('I059', 'Tomaten (passiert)', 'kg', 1.3, NULL, NULL),
  ('I060', 'Chili (frisch)', 'kg', 10.9, NULL, NULL),
  ('I077', 'Hähnchenbrust', 'kg', 16.9, NULL, NULL),
  ('I079', 'Kokosmilch', 'l', 3.23, NULL, NULL),
  ('I080', 'Currypaste (gelb)', 'kg', 12.64, NULL, NULL),
  ('I089', 'Kartoffeln', 'kg', 0.8, NULL, NULL),
  ('I125', 'Langkornreis', 'kg', 1.59, NULL, NULL),
  ('I153', 'Bratwürste', 'st', 7.02, NULL, NULL),
  ('I156', 'Ketchup', 'kg', 2.58, NULL, NULL),
  ('I195', 'Kidneybohnen', 'kg', 3.5, NULL, NULL),
  ('I199', 'Currypulver', 'kg', 25.0, NULL, NULL),
  ('I202', 'Römersalat', 'kg', 4.5, NULL, NULL)
ON CONFLICT (ingredient_id) DO UPDATE SET
  name_canonical = EXCLUDED.name_canonical,
  unit_default = EXCLUDED.unit_default,
  price_baseline_per_unit = EXCLUDED.price_baseline_per_unit,
  allergen_tags = EXCLUDED.allergen_tags,
  notes = EXCLUDED.notes;

-- ============================================
-- 4. DISHES (Essential dishes for demo)
-- ============================================

INSERT INTO dishes (dish_id, name, category, is_quick, is_meal_prep, season, cuisine, notes) VALUES
  -- Quick meals (highlighted in app)
  ('D115', 'Chili con Carne', 'Hauptgericht', TRUE, TRUE, NULL, NULL, NULL),
  ('D116', 'Carbonara (klassisch)', 'Hauptgericht', TRUE, FALSE, NULL, NULL, NULL),
  ('D117', 'Currywurst mit Kartoffelecken', 'Hauptgericht', TRUE, FALSE, NULL, NULL, NULL),
  ('D118', 'Cevapcici mit Reis', 'Hauptgericht', TRUE, FALSE, NULL, NULL, NULL),
  ('D121', 'Curry-Geschnetzeltes mit Reis', 'Hauptgericht', TRUE, TRUE, NULL, NULL, NULL),
  ('D122', 'Caesar Salad (mit Hähnchen)', 'Hauptgericht', TRUE, FALSE, NULL, NULL, NULL),
  ('D123', 'Chili sin Carne', 'Hauptgericht', TRUE, TRUE, NULL, NULL, NULL),
  ('D124', 'Cremige Tomaten-Pasta', 'Hauptgericht', TRUE, TRUE, NULL, NULL, NULL),
  ('D125', 'Curry-Kartoffel-Pfanne', 'Hauptgericht', TRUE, TRUE, NULL, NULL, NULL),
  ('D126', 'Crêpes', 'Snack', TRUE, FALSE, NULL, NULL, NULL),
  -- Regular dishes
  ('D001', 'Aachener Printen-Parfait', 'Dessert', FALSE, FALSE, NULL, NULL, NULL),
  ('D005', 'Albondigas in Tomatensauce', 'Hauptgericht', FALSE, FALSE, NULL, NULL, NULL),
  ('D006', 'Apfelkompott', 'Süßspeise', FALSE, FALSE, NULL, NULL, NULL),
  ('D007', 'Apfelpfannkuchen', 'Süßspeise', FALSE, FALSE, NULL, NULL, NULL),
  ('D008', 'Apfelstrudel', 'Süßspeise', FALSE, FALSE, NULL, NULL, NULL),
  ('D011', 'Aglio e Olio (Spaghetti)', 'Pasta', FALSE, FALSE, NULL, NULL, NULL),
  ('D012', 'Amatriciana (Pasta)', 'Pasta', FALSE, FALSE, NULL, NULL, NULL),
  ('D013', 'Arrabbiata (Pasta)', 'Pasta', FALSE, FALSE, NULL, NULL, NULL),
  ('D015', 'Allgäuer Käsespätzle', 'Hauptgericht', FALSE, FALSE, NULL, NULL, NULL),
  ('D019', 'Ananas-Curry (Huhn)', 'Hauptgericht', FALSE, FALSE, NULL, NULL, NULL),
  ('D020', 'Ananas-Curry (Tofu)', 'Hauptgericht (vegetarisch)', FALSE, FALSE, NULL, NULL, NULL),
  ('D022', 'Ajvar-Hähnchenpfanne', 'Hauptgericht', FALSE, FALSE, NULL, NULL, NULL),
  ('D033', 'Avocado-Salat (frisch)', 'Salat', FALSE, FALSE, NULL, NULL, NULL),
  ('D035', 'Avo-Toast (klassisch)', 'Snack', FALSE, FALSE, NULL, NULL, NULL),
  ('D046', 'Arroz con Pollo (Huhn)', 'Hauptgericht', FALSE, FALSE, NULL, NULL, NULL)
ON CONFLICT (dish_id) DO UPDATE SET
  name = EXCLUDED.name,
  category = EXCLUDED.category,
  is_quick = EXCLUDED.is_quick,
  is_meal_prep = EXCLUDED.is_meal_prep;

-- ============================================
-- 5. DISH INGREDIENTS (Relationships)
-- ============================================

INSERT INTO dish_ingredients (dish_id, ingredient_id, qty, unit, optional, role) VALUES
  -- D115: Chili con Carne
  ('D115', 'I020', 400, 'g', FALSE, 'main'),
  ('D115', 'I022', 400, 'g', FALSE, 'main'),
  ('D115', 'I023', 1, 'Stück', FALSE, 'main'),
  ('D115', 'I195', 300, 'g', TRUE, 'side'),
  ('D115', 'I046', 1, 'Stück', TRUE, 'side'),
  -- D116: Carbonara
  ('D116', 'I051', 250, 'g', FALSE, 'main'),
  ('D116', 'I056', 120, 'g', FALSE, 'main'),
  ('D116', 'I003', 3, 'Stück', FALSE, 'main'),
  ('D116', 'I057', 40, 'g', FALSE, 'main'),
  -- D117: Currywurst
  ('D117', 'I153', 4, 'Stück', FALSE, 'main'),
  ('D117', 'I156', 2, 'EL', FALSE, 'main'),
  ('D117', 'I089', 500, 'g', FALSE, 'main'),
  ('D117', 'I199', 1, 'TL', FALSE, 'main'),
  -- D118: Cevapcici
  ('D118', 'I020', 400, 'g', FALSE, 'main'),
  ('D118', 'I023', 1, 'Stück', FALSE, 'main'),
  ('D118', 'I125', 250, 'g', FALSE, 'main'),
  -- D121: Curry-Geschnetzeltes
  ('D121', 'I077', 350, 'g', FALSE, 'main'),
  ('D121', 'I080', 2, 'EL', FALSE, 'main'),
  ('D121', 'I079', 400, 'ml', FALSE, 'main'),
  ('D121', 'I125', 250, 'g', FALSE, 'main'),
  ('D121', 'I023', 1, 'Stück', FALSE, 'main'),
  -- D122: Caesar Salad
  ('D122', 'I202', 150, 'g', FALSE, 'main'),
  ('D122', 'I077', 200, 'g', FALSE, 'main'),
  ('D122', 'I054', 30, 'g', FALSE, 'main'),
  -- D123: Chili sin Carne
  ('D123', 'I195', 300, 'g', FALSE, 'main'),
  ('D123', 'I022', 400, 'g', FALSE, 'main'),
  ('D123', 'I023', 1, 'Stück', FALSE, 'main'),
  -- D124: Cremige Tomaten-Pasta
  ('D124', 'I051', 250, 'g', FALSE, 'main'),
  ('D124', 'I059', 400, 'g', FALSE, 'main'),
  ('D124', 'I002', 150, 'ml', FALSE, 'main'),
  ('D124', 'I023', 1, 'Stück', FALSE, 'main'),
  -- D125: Curry-Kartoffel-Pfanne
  ('D125', 'I089', 600, 'g', FALSE, 'main'),
  ('D125', 'I023', 1, 'Stück', FALSE, 'main'),
  ('D125', 'I046', 1, 'Stück', FALSE, 'main'),
  ('D125', 'I199', 1, 'TL', FALSE, 'main'),
  -- D126: Crêpes
  ('D126', 'I031', 200, 'g', FALSE, 'main'),
  ('D126', 'I003', 2, 'Stück', FALSE, 'main'),
  ('D126', 'I030', 250, 'ml', FALSE, 'main'),
  -- D011: Aglio e Olio
  ('D011', 'I051', 250, 'g', FALSE, 'main'),
  ('D011', 'I050', 4, 'Zehen', FALSE, 'main'),
  ('D011', 'I052', 60, 'ml', FALSE, 'main'),
  -- D005: Albondigas
  ('D005', 'I020', 400, 'g', FALSE, 'main'),
  ('D005', 'I021', 1, 'Stück', FALSE, 'main'),
  ('D005', 'I022', 400, 'g', FALSE, 'main'),
  -- D007: Apfelpfannkuchen
  ('D007', 'I026', 2, 'Stück', FALSE, 'main'),
  ('D007', 'I021', 3, 'Stück', FALSE, 'main'),
  ('D007', 'I030', 250, 'ml', FALSE, 'main'),
  ('D007', 'I031', 150, 'g', FALSE, 'main')
ON CONFLICT (dish_id, ingredient_id) DO NOTHING;

-- ============================================
-- 6. CURRENT OFFERS (Valid for current week)
-- ===========================================

DO $$
DECLARE
  current_monday DATE;
  current_sunday DATE;
BEGIN
  -- Calculate current week (Monday to Sunday)
  current_monday := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  current_sunday := current_monday + INTERVAL '6 days';
  
  -- REWE Region 500 (Hannover Nord) - Good deals
  INSERT INTO offers (region_id, ingredient_id, price_total, pack_size, unit_base, valid_from, valid_to, source, source_ref_id, offer_hash)
  VALUES
    (500, 'I051', 0.99, 0.5, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_spaghetti_500g', 
     MD5('500|I051|0.99|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_spaghetti_500g')),
    (500, 'I020', 6.99, 1.0, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_hack_1kg',
     MD5('500|I020|6.99|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_hack_1kg')),
    (500, 'I077', 12.99, 1.0, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_haehnchen_1kg',
     MD5('500|I077|12.99|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_haehnchen_1kg')),
    (500, 'I089', 0.49, 2.5, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_kartoffeln_2.5kg',
     MD5('500|I089|0.49|2.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_kartoffeln_2.5kg')),
    (500, 'I003', 1.49, 10, 'st', current_monday, current_sunday, 'REWE Prospekt', 'rewe_eier_10st',
     MD5('500|I003|1.49|10|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_eier_10st')),
    (500, 'I030', 0.79, 1.0, 'l', current_monday, current_sunday, 'REWE Prospekt', 'rewe_milch_1l',
     MD5('500|I030|0.79|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_milch_1l')),
    (500, 'I045', 1.99, 0.5, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_brokkoli_500g',
     MD5('500|I045|1.99|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_brokkoli_500g')),
    (500, 'I046', 2.49, 1.0, 'st', current_monday, current_sunday, 'REWE Prospekt', 'rewe_paprika_1st',
     MD5('500|I046|2.49|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_paprika_1st')),
    (500, 'I059', 0.89, 0.5, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_tomaten_500g',
     MD5('500|I059|0.89|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_tomaten_500g')),
    
    -- Lidl Region 510 (Hannover West) - Competitive prices
    (510, 'I051', 0.89, 0.5, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_spaghetti_500g',
     MD5('510|I051|0.89|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_spaghetti_500g')),
    (510, 'I020', 6.49, 1.0, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_hack_1kg',
     MD5('510|I020|6.49|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_hack_1kg')),
    (510, 'I059', 0.79, 0.5, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_tomaten_500g',
     MD5('510|I059|0.79|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_tomaten_500g')),
    (510, 'I044', 4.99, 0.4, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_tofu_400g',
     MD5('510|I044|4.99|0.4|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_tofu_400g')),
    (510, 'I089', 0.39, 2.5, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_kartoffeln_2.5kg',
     MD5('510|I089|0.39|2.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_kartoffeln_2.5kg')),
    (510, 'I003', 1.39, 10, 'st', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_eier_10st',
     MD5('510|I003|1.39|10|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_eier_10st')),
    (510, 'I030', 0.69, 1.0, 'l', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_milch_1l',
     MD5('510|I030|0.69|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_milch_1l')),
    (510, 'I045', 1.79, 0.5, 'kg', current_monday, current_sunday, 'Lidl Prospekt', 'lidl_brokkoli_500g',
     MD5('510|I045|1.79|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|lidl_brokkoli_500g')),
    
    -- ALDI Region 520 (Hannover Nord)
    (520, 'I051', 0.95, 0.5, 'kg', current_monday, current_sunday, 'ALDI Prospekt', 'aldi_spaghetti_500g',
     MD5('520|I051|0.95|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|aldi_spaghetti_500g')),
    (520, 'I020', 6.79, 1.0, 'kg', current_monday, current_sunday, 'ALDI Prospekt', 'aldi_hack_1kg',
     MD5('520|I020|6.79|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|aldi_hack_1kg')),
    (520, 'I089', 0.45, 2.5, 'kg', current_monday, current_sunday, 'ALDI Prospekt', 'aldi_kartoffeln_2.5kg',
     MD5('520|I089|0.45|2.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|aldi_kartoffeln_2.5kg')),
    (520, 'I003', 1.59, 10, 'st', current_monday, current_sunday, 'ALDI Prospekt', 'aldi_eier_10st',
     MD5('520|I003|1.59|10|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|aldi_eier_10st')),
    (520, 'I030', 0.75, 1.0, 'l', current_monday, current_sunday, 'ALDI Prospekt', 'aldi_milch_1l',
     MD5('520|I030|0.75|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|aldi_milch_1l'))
  ON CONFLICT (offer_hash) DO NOTHING;
  
  RAISE NOTICE 'Inserted offers for week % to %', current_monday, current_sunday;
END $$;

COMMIT;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check data counts
SELECT 'Lookups Categories' as table_name, COUNT(*) as count FROM lookups_categories
UNION ALL SELECT 'Lookups Units', COUNT(*) FROM lookups_units
UNION ALL SELECT 'Chains', COUNT(*) FROM chains
UNION ALL SELECT 'Ad Regions', COUNT(*) FROM ad_regions
UNION ALL SELECT 'Stores', COUNT(*) FROM stores
UNION ALL SELECT 'Postal Codes', COUNT(*) FROM postal_codes
UNION ALL SELECT 'Ingredients', COUNT(*) FROM ingredients
UNION ALL SELECT 'Dishes', COUNT(*) FROM dishes
UNION ALL SELECT 'Dish Ingredients', COUNT(*) FROM dish_ingredients
UNION ALL SELECT 'Offers (Current)', COUNT(*) FROM offers WHERE valid_to >= CURRENT_DATE;

-- Test pricing calculation
SELECT * FROM calculate_dish_price('D115', '30165');
SELECT * FROM calculate_dish_price('D116', '30165');
SELECT * FROM calculate_dish_price('D117', '30165');


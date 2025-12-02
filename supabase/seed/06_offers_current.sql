-- Seed Data: Current Offers
-- These offers are valid for the current week to demonstrate the app functionality
-- Dates are set to current week (adjust as needed)

-- Get current week dates (Monday to Sunday)
-- This uses a function to calculate current week
DO $$
DECLARE
  current_monday DATE;
  current_sunday DATE;
  offer_hash_val TEXT;
BEGIN
  -- Calculate current week (Monday to Sunday)
  current_monday := DATE_TRUNC('week', CURRENT_DATE)::DATE;
  current_sunday := current_monday + INTERVAL '6 days';
  
  -- Insert offers for current week
  -- REWE Region 500 (Hannover Nord)
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
    (500, 'I026', 1.99, 1.0, 'st', current_monday, current_sunday, 'REWE Prospekt', 'rewe_aepfel_1kg',
     MD5('500|I026|1.99|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_aepfel_1kg')),
    (500, 'I003', 1.49, 10, 'st', current_monday, current_sunday, 'REWE Prospekt', 'rewe_eier_10st',
     MD5('500|I003|1.49|10|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_eier_10st')),
    (500, 'I030', 0.79, 1.0, 'l', current_monday, current_sunday, 'REWE Prospekt', 'rewe_milch_1l',
     MD5('500|I030|0.79|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_milch_1l')),
    (500, 'I045', 1.99, 0.5, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_brokkoli_500g',
     MD5('500|I045|1.99|0.5|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_brokkoli_500g')),
    (500, 'I046', 2.49, 1.0, 'st', current_monday, current_sunday, 'REWE Prospekt', 'rewe_paprika_1st',
     MD5('500|I046|2.49|1.0|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_paprika_1st')),
    (500, 'I040', 4.99, 0.25, 'kg', current_monday, current_sunday, 'REWE Prospekt', 'rewe_mozzarella_250g',
     MD5('500|I040|4.99|0.25|' || current_monday::TEXT || '|' || current_sunday::TEXT || '|rewe_mozzarella_250g')),
    
    -- Lidl Region 510 (Hannover West)
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


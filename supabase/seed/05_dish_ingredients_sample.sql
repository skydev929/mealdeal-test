-- Seed Data: Dish Ingredients (Sample - for first 50 dishes)
-- Full data should be imported via CSV

INSERT INTO dish_ingredients (dish_id, ingredient_id, qty, unit, optional, role) VALUES
  -- D001: Aachener Printen-Parfait
  ('D001', 'I001', 150, 'g', FALSE, 'main'),
  ('D001', 'I002', 300, 'ml', FALSE, 'main'),
  ('D001', 'I003', 3, 'Stück', FALSE, 'main'),
  ('D001', 'I004', 2, 'EL', TRUE, 'side'),
  ('D001', 'I005', 1, 'TL', TRUE, 'side'),
  -- D002: Aal Grün
  ('D002', 'I006', 600, 'g', FALSE, 'main'),
  ('D002', 'I007', 150, 'g', FALSE, 'main'),
  ('D002', 'I008', 1, 'Bund', FALSE, 'main'),
  ('D002', 'I009', 3, 'EL', TRUE, 'side'),
  -- D003: Aalrauch-Forellenaufstrich
  ('D003', 'I011', 200, 'g', FALSE, 'main'),
  ('D003', 'I012', 200, 'g', FALSE, 'main'),
  ('D003', 'I013', 0.5, 'Stück', FALSE, 'main'),
  -- D004: Agnolotti mit Ricotta-Spinat
  ('D004', 'I016', 400, 'g', FALSE, 'main'),
  ('D004', 'I017', 250, 'g', FALSE, 'main'),
  ('D004', 'I018', 200, 'g', FALSE, 'main'),
  -- D005: Albondigas
  ('D005', 'I020', 400, 'g', FALSE, 'main'),
  ('D005', 'I021', 1, 'Stück', FALSE, 'main'),
  ('D005', 'I022', 400, 'g', FALSE, 'main'),
  -- D011: Aglio e Olio (Quick meal)
  ('D011', 'I051', 250, 'g', FALSE, 'main'),
  ('D011', 'I050', 4, 'Zehen', FALSE, 'main'),
  ('D011', 'I052', 60, 'ml', FALSE, 'main'),
  -- D115: Chili con Carne (Quick meal)
  ('D115', 'I020', 400, 'g', FALSE, 'main'),
  ('D115', 'I022', 400, 'g', FALSE, 'main'),
  ('D115', 'I023', 1, 'Stück', FALSE, 'main'),
  -- D116: Carbonara (Quick meal)
  ('D116', 'I051', 250, 'g', FALSE, 'main'),
  ('D116', 'I056', 120, 'g', FALSE, 'main'),
  ('D116', 'I003', 3, 'Stück', FALSE, 'main'),
  ('D116', 'I057', 40, 'g', FALSE, 'main'),
  -- D117: Currywurst
  ('D117', 'I153', 4, 'Stück', FALSE, 'main'),
  ('D117', 'I156', 2, 'EL', FALSE, 'main'),
  ('D117', 'I089', 500, 'g', FALSE, 'main'),
  -- D118: Cevapcici
  ('D118', 'I020', 400, 'g', FALSE, 'main'),
  ('D118', 'I023', 1, 'Stück', FALSE, 'main'),
  ('D118', 'I125', 250, 'g', FALSE, 'main'),
  -- D121: Curry-Geschnetzeltes
  ('D121', 'I077', 350, 'g', FALSE, 'main'),
  ('D121', 'I080', 2, 'EL', FALSE, 'main'),
  ('D121', 'I079', 400, 'ml', FALSE, 'main'),
  ('D121', 'I125', 250, 'g', FALSE, 'main'),
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
  ('D126', 'I030', 250, 'ml', FALSE, 'main')
ON CONFLICT (dish_id, ingredient_id) DO NOTHING;


-- Fix: Add missing units to lookups_units table
-- The ingredients CSV uses units that might not exist in lookups_units

-- Add common units that might be missing
INSERT INTO lookups_units (unit, description)
VALUES 
  ('kg', 'Kilogram'),
  ('l', 'Liter'),
  ('st', 'Stück'),
  ('g', 'Gramm'),
  ('ml', 'Milliliter')
ON CONFLICT (unit) DO NOTHING;

-- Verify all units from ingredients exist
-- Run this query to check:
SELECT DISTINCT i.unit_default
FROM (
  SELECT 'kg' as unit_default UNION
  SELECT 'l' UNION
  SELECT 'st' UNION
  SELECT 'g' UNION
  SELECT 'ml' UNION
  SELECT 'Bund' UNION
  SELECT 'EL' UNION
  SELECT 'TL' UNION
  SELECT 'Stück' UNION
  SELECT 'Zehen' UNION
  SELECT 'Päckchen' UNION
  SELECT 'Rolle' UNION
  SELECT 'Streifen'
) i
LEFT JOIN lookups_units lu ON i.unit_default = lu.unit
WHERE lu.unit IS NULL;

-- If the query above returns any rows, those units are missing and need to be added


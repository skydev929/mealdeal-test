-- Seed Data: Lookup Tables
-- These must be imported first as they have no dependencies

-- Lookup Categories
INSERT INTO lookups_categories (category) VALUES
  ('Aufstrich'),
  ('Beilage'),
  ('Dessert'),
  ('Frühstück'),
  ('Getränk'),
  ('Hauptgericht'),
  ('Hauptgericht (vegetarisch)'),
  ('Hauptgericht (vegan)'),
  ('Pasta'),
  ('Salat'),
  ('Snack'),
  ('Suppe'),
  ('Süßspeise'),
  ('Vorspeise')
ON CONFLICT (category) DO NOTHING;

-- Lookup Units
INSERT INTO lookups_units (unit, description) VALUES
  ('Bund', 'Bundle'),
  ('EL', 'Esslöffel'),
  ('Päckchen', 'Package'),
  ('Rolle', 'Roll'),
  ('Streifen', 'Strip'),
  ('Stück', 'Piece'),
  ('TL', 'Teelöffel'),
  ('Zehen', 'Clove'),
  ('g', 'Gram'),
  ('ml', 'Milliliter'),
  ('kg', 'Kilogram'),
  ('l', 'Liter'),
  ('st', 'Stück (abbreviation)')
ON CONFLICT (unit) DO NOTHING;


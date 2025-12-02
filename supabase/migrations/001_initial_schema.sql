-- MealDeal Database Schema
-- This migration creates all necessary tables for the MealDeal application

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Lookup Tables
CREATE TABLE IF NOT EXISTS lookups_categories (
  category TEXT PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS lookups_units (
  unit TEXT PRIMARY KEY,
  description TEXT
);

-- Chains (Supermarket chains)
CREATE TABLE IF NOT EXISTS chains (
  chain_id SERIAL PRIMARY KEY,
  chain_name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ad Regions (Advertising regions for offers)
CREATE TABLE IF NOT EXISTS ad_regions (
  region_id INTEGER PRIMARY KEY,
  chain_id INTEGER NOT NULL REFERENCES chains(chain_id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stores
CREATE TABLE IF NOT EXISTS stores (
  store_id INTEGER PRIMARY KEY,
  chain_id INTEGER NOT NULL REFERENCES chains(chain_id) ON DELETE CASCADE,
  store_name TEXT NOT NULL,
  plz TEXT,
  city TEXT,
  street TEXT,
  lat DECIMAL(10, 8),
  lon DECIMAL(11, 8),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Store-Region Mapping
CREATE TABLE IF NOT EXISTS store_region_map (
  store_id INTEGER NOT NULL REFERENCES stores(store_id) ON DELETE CASCADE,
  region_id INTEGER NOT NULL REFERENCES ad_regions(region_id) ON DELETE CASCADE,
  PRIMARY KEY (store_id, region_id)
);

-- Postal Codes (PLZ) to Region Mapping
CREATE TABLE IF NOT EXISTS postal_codes (
  plz TEXT PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES ad_regions(region_id) ON DELETE CASCADE,
  city TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ingredients
CREATE TABLE IF NOT EXISTS ingredients (
  ingredient_id TEXT PRIMARY KEY,
  name_canonical TEXT NOT NULL,
  unit_default TEXT NOT NULL REFERENCES lookups_units(unit),
  price_baseline_per_unit DECIMAL(10, 2),
  allergen_tags TEXT[],
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dishes
CREATE TABLE IF NOT EXISTS dishes (
  dish_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL REFERENCES lookups_categories(category),
  is_quick BOOLEAN DEFAULT FALSE,
  is_meal_prep BOOLEAN DEFAULT FALSE,
  season TEXT,
  cuisine TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dish-Ingredients (Many-to-Many)
CREATE TABLE IF NOT EXISTS dish_ingredients (
  dish_id TEXT NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
  qty DECIMAL(10, 3) NOT NULL,
  unit TEXT NOT NULL REFERENCES lookups_units(unit),
  optional BOOLEAN DEFAULT FALSE,
  role TEXT, -- 'main', 'side', 'Hauptzutat', 'Nebenzutat'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (dish_id, ingredient_id)
);

-- Product Map (Aggregator products to ingredients)
CREATE TABLE IF NOT EXISTS product_map (
  aggregator_product_id TEXT PRIMARY KEY,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
  confidence DECIMAL(3, 2) DEFAULT 0.0,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Offers (Current supermarket offers)
CREATE TABLE IF NOT EXISTS offers (
  offer_id SERIAL PRIMARY KEY,
  region_id INTEGER NOT NULL REFERENCES ad_regions(region_id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
  price_total DECIMAL(10, 2) NOT NULL,
  pack_size DECIMAL(10, 3) NOT NULL,
  unit_base TEXT NOT NULL REFERENCES lookups_units(unit),
  valid_from DATE NOT NULL,
  valid_to DATE NOT NULL,
  source TEXT,
  source_ref_id TEXT,
  offer_hash TEXT UNIQUE, -- For deduplication
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_offers_region ON offers(region_id);
CREATE INDEX IF NOT EXISTS idx_offers_ingredient ON offers(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_offers_valid_dates ON offers(valid_from, valid_to);
CREATE INDEX IF NOT EXISTS idx_offers_hash ON offers(offer_hash);
CREATE INDEX IF NOT EXISTS idx_dish_ingredients_dish ON dish_ingredients(dish_id);
CREATE INDEX IF NOT EXISTS idx_dish_ingredients_ingredient ON dish_ingredients(ingredient_id);
CREATE INDEX IF NOT EXISTS idx_stores_chain ON stores(chain_id);
CREATE INDEX IF NOT EXISTS idx_postal_codes_plz ON postal_codes(plz);

-- User Profiles (Anonymous UUID + optional email auth)
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE,
  username TEXT,
  plz TEXT,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Roles
CREATE TABLE IF NOT EXISTS user_roles (
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, role)
);

-- Favorites (Paywall feature)
CREATE TABLE IF NOT EXISTS favorites (
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  dish_id TEXT NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, dish_id)
);

-- Meal Plans
CREATE TABLE IF NOT EXISTS plans (
  plan_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  week_start_date DATE NOT NULL,
  week_iso TEXT,
  status TEXT DEFAULT 'draft',
  locked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Plan Items
CREATE TABLE IF NOT EXISTS plan_items (
  plan_item_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_id UUID NOT NULL REFERENCES plans(plan_id) ON DELETE CASCADE,
  day_of_week INTEGER CHECK (day_of_week >= 0 AND day_of_week <= 6),
  dish_id TEXT NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
  servings INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Plan Item Prices (Detailed pricing breakdown)
CREATE TABLE IF NOT EXISTS plan_item_prices (
  plan_item_price_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  plan_item_id UUID NOT NULL REFERENCES plan_items(plan_item_id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
  qty DECIMAL(10, 3) NOT NULL,
  unit TEXT NOT NULL REFERENCES lookups_units(unit),
  baseline_price_per_unit DECIMAL(10, 2),
  baseline_total DECIMAL(10, 2),
  offer_price_per_unit DECIMAL(10, 2),
  offer_total DECIMAL(10, 2),
  offer_source TEXT,
  offer_ref_id TEXT,
  savings_abs DECIMAL(10, 2) DEFAULT 0,
  savings_pct DECIMAL(5, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Plan Totals
CREATE TABLE IF NOT EXISTS plan_totals (
  plan_id UUID PRIMARY KEY REFERENCES plans(plan_id) ON DELETE CASCADE,
  total_baseline DECIMAL(10, 2) DEFAULT 0,
  total_offer DECIMAL(10, 2) DEFAULT 0,
  total_savings_abs DECIMAL(10, 2) DEFAULT 0,
  total_savings_pct DECIMAL(5, 2) DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Events/Analytics (Optional)
CREATE TABLE IF NOT EXISTS events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  event_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_events_user ON events(user_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);

-- Functions for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_chains_updated_at BEFORE UPDATE ON chains
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ad_regions_updated_at BEFORE UPDATE ON ad_regions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ingredients_updated_at BEFORE UPDATE ON ingredients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dishes_updated_at BEFORE UPDATE ON dishes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_map_updated_at BEFORE UPDATE ON product_map
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plans_updated_at BEFORE UPDATE ON plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plan_totals_updated_at BEFORE UPDATE ON plan_totals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate dish price based on offers and PLZ
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
  _region_id INTEGER;
  _base_total DECIMAL(10, 2) := 0;
  _offer_total DECIMAL(10, 2) := 0;
  _offers_count INTEGER := 0;
BEGIN
  -- Get region_id from PLZ if provided
  IF _user_plz IS NOT NULL THEN
    SELECT region_id INTO _region_id
    FROM postal_codes
    WHERE plz = _user_plz
    LIMIT 1;
  END IF;

  -- Calculate base price (using baseline prices)
  SELECT COALESCE(SUM(
    di.qty * COALESCE(i.price_baseline_per_unit, 0)
  ), 0) INTO _base_total
  FROM dish_ingredients di
  JOIN ingredients i ON di.ingredient_id = i.ingredient_id
  WHERE di.dish_id = _dish_id
    AND di.optional = FALSE;

  -- Calculate offer price (using current offers if region available)
  IF _region_id IS NOT NULL THEN
    SELECT COALESCE(SUM(
      CASE 
        WHEN o.offer_id IS NOT NULL THEN
          (di.qty / o.pack_size) * o.price_total
        ELSE
          di.qty * COALESCE(i.price_baseline_per_unit, 0)
      END
    ), 0) INTO _offer_total
    FROM dish_ingredients di
    JOIN ingredients i ON di.ingredient_id = i.ingredient_id
    LEFT JOIN offers o ON 
      o.ingredient_id = di.ingredient_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
    WHERE di.dish_id = _dish_id
      AND di.optional = FALSE;

    -- Count available offers
    SELECT COUNT(DISTINCT o.offer_id) INTO _offers_count
    FROM dish_ingredients di
    JOIN offers o ON o.ingredient_id = di.ingredient_id
    WHERE di.dish_id = _dish_id
      AND o.region_id = _region_id
      AND o.valid_from <= CURRENT_DATE
      AND o.valid_to >= CURRENT_DATE
      AND di.optional = FALSE;
  ELSE
    _offer_total := _base_total;
  END IF;

  RETURN QUERY SELECT
    _dish_id,
    _base_total,
    _offer_total,
    _base_total - _offer_total,
    CASE WHEN _base_total > 0 THEN
      ((_base_total - _offer_total) / _base_total * 100)
    ELSE 0 END,
    _offers_count;
END;
$$ LANGUAGE plpgsql;


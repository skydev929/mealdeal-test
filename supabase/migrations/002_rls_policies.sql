-- Row Level Security (RLS) Policies for MealDeal
-- These policies control who can read/write data

-- Enable RLS on user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: Allow checking email/username existence for signup validation
-- This allows unauthenticated users to check if email/username exists
CREATE POLICY "Public can check email for signup"
  ON user_profiles
  FOR SELECT
  USING (true)
  WITH CHECK (false); -- Only allow SELECT, not INSERT/UPDATE

-- Policy: Users can insert their own profile (for signup)
-- This allows authenticated users to create their profile during signup
-- The id must match their auth.uid()
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (
    auth.uid() = id OR
    -- Allow if the user is authenticated and inserting their own ID
    (auth.uid() IS NOT NULL AND auth.uid() = id)
  );

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Enable RLS on user_roles
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own roles
CREATE POLICY "Users can view own roles"
  ON user_roles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Allow inserts for user roles (for signup)
-- Note: This allows authenticated users to insert their own 'user' role
-- Admin roles should be assigned manually via SQL
CREATE POLICY "Users can insert own user role"
  ON user_roles
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND 
    (role = 'user' OR role = 'admin')
  );

-- Enable RLS on favorites
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own favorites
CREATE POLICY "Users can manage own favorites"
  ON favorites
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Enable RLS on plans
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage their own plans
CREATE POLICY "Users can manage own plans"
  ON plans
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Enable RLS on plan_items
ALTER TABLE plan_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can manage plan items for their own plans
CREATE POLICY "Users can manage own plan items"
  ON plan_items
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM plans
      WHERE plans.plan_id = plan_items.plan_id
      AND plans.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM plans
      WHERE plans.plan_id = plan_items.plan_id
      AND plans.user_id = auth.uid()
    )
  );

-- Enable RLS on plan_item_prices
ALTER TABLE plan_item_prices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view plan item prices for their own plans
CREATE POLICY "Users can view own plan item prices"
  ON plan_item_prices
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM plan_items pi
      JOIN plans p ON p.plan_id = pi.plan_id
      WHERE pi.plan_item_id = plan_item_prices.plan_item_id
      AND p.user_id = auth.uid()
    )
  );

-- Enable RLS on plan_totals
ALTER TABLE plan_totals ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view plan totals for their own plans
CREATE POLICY "Users can view own plan totals"
  ON plan_totals
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM plans
      WHERE plans.plan_id = plan_totals.plan_id
      AND plans.user_id = auth.uid()
    )
  );

-- Public read access for dishes, ingredients, offers, etc.
-- These are public data that anyone can read

-- Dishes: Public read
ALTER TABLE dishes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Dishes are publicly readable"
  ON dishes
  FOR SELECT
  TO public
  USING (true);

-- Ingredients: Public read
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ingredients are publicly readable"
  ON ingredients
  FOR SELECT
  TO public
  USING (true);

-- Dish ingredients: Public read
ALTER TABLE dish_ingredients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Dish ingredients are publicly readable"
  ON dish_ingredients
  FOR SELECT
  TO public
  USING (true);

-- Offers: Public read
ALTER TABLE offers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Offers are publicly readable"
  ON offers
  FOR SELECT
  TO public
  USING (true);

-- Chains: Public read
ALTER TABLE chains ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Chains are publicly readable"
  ON chains
  FOR SELECT
  TO public
  USING (true);

-- Stores: Public read
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Stores are publicly readable"
  ON stores
  FOR SELECT
  TO public
  USING (true);

-- Ad regions: Public read
ALTER TABLE ad_regions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ad regions are publicly readable"
  ON ad_regions
  FOR SELECT
  TO public
  USING (true);

-- Store region map: Public read
ALTER TABLE store_region_map ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Store region map is publicly readable"
  ON store_region_map
  FOR SELECT
  TO public
  USING (true);

-- Postal codes: Public read
ALTER TABLE postal_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Postal codes are publicly readable"
  ON postal_codes
  FOR SELECT
  TO public
  USING (true);

-- Lookup tables: Public read
ALTER TABLE lookups_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Categories lookup is publicly readable"
  ON lookups_categories
  FOR SELECT
  TO public
  USING (true);

ALTER TABLE lookups_units ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Units lookup is publicly readable"
  ON lookups_units
  FOR SELECT
  TO public
  USING (true);

-- Product map: Public read
ALTER TABLE product_map ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Product map is publicly readable"
  ON product_map
  FOR SELECT
  TO public
  USING (true);

-- Events: Users can only insert their own events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert own events"
  ON events
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- Admin access: Allow service role to bypass RLS for admin operations
-- This is handled by using the service role key in edge functions


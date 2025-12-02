-- Allow service role (used by edge functions) to insert into public tables
-- These policies allow the import-csv edge function to insert data

-- Ingredients: Allow service role to insert
CREATE POLICY "Service role can insert ingredients"
  ON ingredients
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Dishes: Allow service role to insert
CREATE POLICY "Service role can insert dishes"
  ON dishes
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Dish ingredients: Allow service role to insert
CREATE POLICY "Service role can insert dish_ingredients"
  ON dish_ingredients
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Offers: Allow service role to insert
CREATE POLICY "Service role can insert offers"
  ON offers
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Also allow updates for upsert operations
CREATE POLICY "Service role can update ingredients"
  ON ingredients
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can update dishes"
  ON dishes
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can update dish_ingredients"
  ON dish_ingredients
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Service role can update offers"
  ON offers
  FOR UPDATE
  TO service_role
  USING (true)
  WITH CHECK (true);


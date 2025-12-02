# Quick Start Guide - Seed Data

## Fastest Way to Get Started

### Step 1: Run Complete Seed File

1. **Open Supabase SQL Editor:**
   https://supabase.com/dashboard/project/hvjufetqddjxtmuariwr/sql/new

2. **Copy and paste the entire contents of:**
   `supabase/seed/complete_seed.sql`

3. **Click "Run"**

This will populate your database with:
- ✅ All lookup tables (categories, units)
- ✅ Chains, regions, stores, postal codes
- ✅ 30+ essential ingredients
- ✅ 25+ dishes (including quick meals)
- ✅ Dish-ingredient relationships
- ✅ Current offers for this week

### Step 2: Test the App

1. **Start the app:**
   ```bash
   npm run dev
   ```

2. **Sign up/Login** as a user

3. **Enter PLZ:** `30165` (Hannover Nord - has REWE offers)

4. **Browse dishes** - You should see:
   - Dishes with pricing
   - Savings displayed for dishes with offers
   - Filter options working

5. **Try filters:**
   - Category: "Hauptgericht"
   - Chain: "REWE"
   - Max Price: 15€
   - Quick Meals: Check the filter

### Step 3: Verify Data

Run this query in SQL Editor to verify:

```sql
-- Check counts
SELECT 'Dishes' as type, COUNT(*) as count FROM dishes
UNION ALL SELECT 'Offers (Current)', COUNT(*) FROM offers WHERE valid_to >= CURRENT_DATE
UNION ALL SELECT 'Ingredients', COUNT(*) FROM ingredients;

-- Test pricing for a dish
SELECT * FROM calculate_dish_price('D115', '30165');
```

## What You'll See

After seeding, the app will show:

- **~25 dishes** with names and categories
- **~20 active offers** for the current week
- **Pricing calculations** showing:
  - Base price (from ingredient baseline prices)
  - Offer price (using current offers)
  - Savings amount and percentage
- **Filtering** by category, chain, price, location
- **Quick meals** highlighted (is_quick = TRUE)

## Example Workflow

1. User enters PLZ: `30165`
2. System maps to region: `500` (REWE_H_NORD)
3. User browses dishes
4. System calculates prices:
   - **D115 (Chili con Carne)**: 
     - Base: ~€8.50 (using baseline prices)
     - Offer: ~€7.20 (using current REWE offers)
     - Savings: ~€1.30 (15%)
5. User filters by "REWE" → sees dishes with REWE offers
6. User filters by "Quick Meals" → sees D115, D116, D117, etc.

## Next Steps

- Import full CSV data via Admin Dashboard for complete dataset
- Add more offers for different weeks
- Add more postal codes for your target regions
- Test favorites feature (paywall placeholder)


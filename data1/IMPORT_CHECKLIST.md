# CSV Import Checklist

Use this checklist to import all seed data via Admin Dashboard.

## ✅ Import Order (Follow Exactly!)

### Step 1: Lookup Tables
- [ ] `seed_lookups_categories.csv` → Type: `lookups_categories`
- [ ] `seed_lookups_units.csv` → Type: `lookups_units`

### Step 2: Chains & Regions  
- [ ] `seed_chains.csv` → Type: `chains`
- [ ] `seed_ad_regions.csv` → Type: `ad_regions`
- [ ] `seed_stores.csv` → Type: `stores`
- [ ] `seed_store_region_map.csv` → Type: `store_region_map`

### Step 3: Postal Codes (Optional - may need SQL)
- [ ] `seed_postal_codes.csv` → Type: `postal_codes` (if supported)
  - **OR** import via SQL: `supabase/seed/02_chains_regions.sql` (postal_codes section)

### Step 4: Core Data
- [ ] `seed_ingredients.csv` → Type: `ingredients`
- [ ] `seed_dishes.csv` → Type: `dishes`
- [ ] `seed_dish_ingredients.csv` → Type: `dish_ingredients`

### Step 5: Offers
- [ ] `seed_offers.csv` → Type: `offers`
  - **⚠️ IMPORTANT:** Update dates in CSV to current week before importing
  - Current dates: `2025-01-13` to `2025-01-19`
  - Update `valid_from` and `valid_to` to match current week (Monday to Sunday)

## Quick Date Update for Offers

Before importing `seed_offers.csv`, update the dates:

1. Calculate current week:
   - Monday = Today - (DayOfWeek - 1) days
   - Sunday = Monday + 6 days

2. Replace all `2025-01-13` with current Monday date
3. Replace all `2025-01-19` with current Sunday date

**Example:** If today is 2025-11-14 (Friday):
- Monday = 2025-11-10
- Sunday = 2025-11-16
- Update CSV: `2025-11-10` to `2025-11-16`

## After Import

1. ✅ Verify counts match expected values
2. ✅ Test with PLZ `30165` in the app
3. ✅ Check that dishes show pricing
4. ✅ Verify offers are applied (base price ≠ offer price)

## Troubleshooting

- **Foreign key errors:** Check import order
- **Zero prices:** Run migration `010_fix_offer_calculation.sql`
- **Offers not showing:** Check dates are current and region_id matches PLZ


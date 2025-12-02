# Database Schema Quick Reference

## Table Summary

| Table | Primary Key | Key Fields | Purpose |
|-------|------------|------------|---------|
| **Lookups** |
| `lookups_categories` | `category` (TEXT) | category | Master category list |
| `lookups_units` | `unit` (TEXT) | unit, description | Master unit list |
| **Chains & Stores** |
| `chains` | `chain_id` (SERIAL) | chain_name | Supermarket chains |
| `ad_regions` | `region_id` (INTEGER) | chain_id, label | Advertising regions |
| `stores` | `store_id` (INTEGER) | chain_id, store_name, plz | Store locations |
| `store_region_map` | (store_id, region_id) | - | Store-region mapping |
| `postal_codes` | `plz` (TEXT) | region_id, city | PLZ to region mapping |
| **Ingredients & Dishes** |
| `ingredients` | `ingredient_id` (TEXT) | name_canonical, unit_default, price_baseline_per_unit | Ingredient master data |
| `dishes` | `dish_id` (TEXT) | name, category, is_quick, is_meal_prep | Recipe/dish data |
| `dish_ingredients` | (dish_id, ingredient_id) | qty, unit, optional, role | Dish-ingredient relationships |
| **Offers** |
| `offers` | `offer_id` (SERIAL) | region_id, ingredient_id, price_total, pack_size, valid_from, valid_to | Current offers |
| `product_map` | `aggregator_product_id` (TEXT) | ingredient_id, confidence | External product mapping |
| **Users** |
| `user_profiles` | `id` (UUID) | email, username, plz | User profiles |
| `user_roles` | (user_id, role) | role | User roles |
| `favorites` | (user_id, dish_id) | - | Favorite dishes |
| **Meal Planning** |
| `plans` | `plan_id` (UUID) | user_id, week_start_date, status | Weekly meal plans |
| `plan_items` | `plan_item_id` (UUID) | plan_id, dish_id, day_of_week | Plan items |
| `plan_item_prices` | `plan_item_price_id` (UUID) | plan_item_id, ingredient_id, baseline_total, offer_total | Detailed pricing |
| `plan_totals` | `plan_id` (UUID) | total_baseline, total_offer, total_savings_abs | Plan totals |

## Key Relationships

```
User Flow:
user_profiles.plz → postal_codes.plz → postal_codes.region_id → ad_regions.region_id → offers.region_id

Dish Pricing:
dishes.dish_id → dish_ingredients.dish_id → dish_ingredients.ingredient_id → ingredients.ingredient_id
                                                                              ↓
                                                                    offers.ingredient_id (if region matches)

Meal Planning:
user_profiles.id → plans.user_id → plan_items.plan_id → plan_items.dish_id → dishes.dish_id
                                                      ↓
                                            plan_item_prices.plan_item_id → plan_item_prices.ingredient_id
```

## Important Functions

### `calculate_dish_price(_dish_id TEXT, _user_plz TEXT)`
Calculates dish pricing with offers.

**Returns:**
- `base_price` - Baseline price
- `offer_price` - Price with offers
- `savings` - Amount saved
- `savings_percent` - Percentage saved
- `available_offers_count` - Number of offers

### `convert_unit(qty DECIMAL, from_unit TEXT, to_unit TEXT)`
Converts between compatible units (g↔kg, ml↔l, Stück↔st).

## CSV Import Order

1. `lookups_categories` - Categories lookup
2. `lookups_units` - Units lookup
3. `chains` - Chains
4. `ad_regions` - Regions (requires chains)
5. `stores` - Stores (requires chains)
6. `store_region_map` - Store-region mapping
7. `postal_codes` - PLZ mapping (requires regions)
8. `ingredients` - Ingredients (requires units)
9. `dishes` - Dishes (requires categories)
10. `dish_ingredients` - Dish-ingredient relationships
11. `offers` - Offers (requires regions, ingredients)
12. `product_map` - Product mapping (optional)

## Common Queries

### Get dishes with pricing for a PLZ
```sql
SELECT * FROM calculate_dish_price('D115', '30165');
```

### Get active offers for a region
```sql
SELECT * FROM offers 
WHERE region_id = 500 
  AND valid_from <= CURRENT_DATE 
  AND valid_to >= CURRENT_DATE;
```

### Get user's meal plan
```sql
SELECT p.*, pi.*, d.name as dish_name
FROM plans p
JOIN plan_items pi ON p.plan_id = pi.plan_id
JOIN dishes d ON pi.dish_id = d.dish_id
WHERE p.user_id = 'user-uuid';
```

## Data Types Reference

- **SERIAL** - Auto-incrementing integer (chains, stores, offers)
- **INTEGER** - Integer (region_id, store_id)
- **TEXT** - Text string (dish_id, ingredient_id, names)
- **UUID** - UUID (user_profiles, plans)
- **DECIMAL(10,2)** - Money/price values
- **DECIMAL(10,3)** - Quantities with precision
- **BOOLEAN** - True/false flags
- **DATE** - Date values (no time)
- **TIMESTAMPTZ** - Timestamp with timezone
- **TEXT[]** - Array of text (allergen_tags)




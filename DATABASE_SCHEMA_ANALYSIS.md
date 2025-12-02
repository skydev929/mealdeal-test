# Database Schema Analysis

## Overview

This document provides a comprehensive analysis of the MealDeal database schema, including table structures, relationships, functions, and data flow.

## Database Architecture

The database uses **PostgreSQL** via Supabase with the following key characteristics:
- **Primary Keys**: Mix of SERIAL (INTEGER), TEXT, and UUID
- **Foreign Keys**: Properly defined with CASCADE deletes
- **Indexes**: Strategic indexes on frequently queried columns
- **Row Level Security (RLS)**: Enabled on user-related tables
- **Functions**: Custom PostgreSQL functions for pricing calculations

---

## Core Tables

### 1. Lookup Tables

#### `lookups_categories`
- **Purpose**: Master list of dish categories
- **Structure**:
  - `category` (TEXT, PRIMARY KEY)
- **Seed Data**: 15 categories (Aufstrich, Beilage, Dessert, Frühstück, etc.)
- **Usage**: Referenced by `dishes.category`

#### `lookups_units`
- **Purpose**: Master list of measurement units
- **Structure**:
  - `unit` (TEXT, PRIMARY KEY)
  - `description` (TEXT)
- **Seed Data**: 14 units (Bund, EL, g, kg, l, ml, Stück, st, etc.)
- **Usage**: Referenced by `ingredients.unit_default`, `dish_ingredients.unit`, `offers.unit_base`

---

### 2. Chains & Stores

#### `chains`
- **Purpose**: Supermarket chains (REWE, Lidl, ALDI, Edeka)
- **Structure**:
  - `chain_id` (SERIAL PRIMARY KEY)
  - `chain_name` (TEXT, UNIQUE, NOT NULL)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 4 chains (chain_id: 10, 11, 12, 13)
- **Relationships**: 
  - Referenced by `ad_regions.chain_id`
  - Referenced by `stores.chain_id`

#### `ad_regions`
- **Purpose**: Advertising regions (chain-specific)
- **Structure**:
  - `region_id` (INTEGER PRIMARY KEY)
  - `chain_id` (INTEGER, FK → chains)
  - `label` (TEXT, NOT NULL) - e.g., "REWE_H_NORD", "LIDL_H_WEST"
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 8 regions (500-521)
- **Key Feature**: Regions are chain-specific (one chain can have multiple regions)
- **Relationships**:
  - Referenced by `stores` (via `store_region_map`)
  - Referenced by `postal_codes.region_id`
  - Referenced by `offers.region_id`

#### `stores`
- **Purpose**: Individual store locations
- **Structure**:
  - `store_id` (INTEGER PRIMARY KEY)
  - `chain_id` (INTEGER, FK → chains)
  - `store_name` (TEXT, NOT NULL)
  - `plz` (TEXT) - Postal code
  - `city` (TEXT)
  - `street` (TEXT)
  - `lat`, `lon` (DECIMAL) - Coordinates
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 7 stores across 3 chains
- **Relationships**:
  - Many-to-many with `ad_regions` via `store_region_map`

#### `store_region_map`
- **Purpose**: Maps stores to advertising regions
- **Structure**:
  - `store_id` (INTEGER, FK → stores)
  - `region_id` (INTEGER, FK → ad_regions)
  - PRIMARY KEY (store_id, region_id)
- **Seed Data**: 7 mappings
- **Note**: One store can belong to multiple regions

#### `postal_codes`
- **Purpose**: Maps PLZ (postal codes) to advertising regions
- **Structure**:
  - `plz` (TEXT PRIMARY KEY)
  - `region_id` (INTEGER, FK → ad_regions)
  - `city` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 22 PLZ mappings
- **Current Limitation**: One PLZ maps to one region (PRIMARY KEY on plz)
- **Business Logic**: Used to determine which offers a user sees based on their PLZ

---

### 3. Ingredients & Dishes

#### `ingredients`
- **Purpose**: Master ingredient catalog
- **Structure**:
  - `ingredient_id` (TEXT PRIMARY KEY) - e.g., "I001", "I002"
  - `name_canonical` (TEXT, NOT NULL) - Canonical name
  - `unit_default` (TEXT, FK → lookups_units) - Default unit
  - `price_baseline_per_unit` (DECIMAL(10,2)) - Baseline price
  - `allergen_tags` (TEXT[]) - Array of allergens
  - `notes` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 36 ingredients
- **Key Fields**:
  - `price_baseline_per_unit`: Used for base price calculations
  - `unit_default`: Used for unit conversions
- **Relationships**:
  - Referenced by `dish_ingredients.ingredient_id`
  - Referenced by `offers.ingredient_id`
  - Referenced by `plan_item_prices.ingredient_id`

#### `dishes`
- **Purpose**: Recipe/dish master data
- **Structure**:
  - `dish_id` (TEXT PRIMARY KEY) - e.g., "D115", "D116"
  - `name` (TEXT, NOT NULL)
  - `category` (TEXT, FK → lookups_categories)
  - `is_quick` (BOOLEAN) - Quick preparation flag
  - `is_meal_prep` (BOOLEAN) - Meal prep friendly
  - `season` (TEXT) - Seasonal availability
  - `cuisine` (TEXT) - Cuisine type
  - `notes` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 27 dishes
- **Relationships**:
  - One-to-many with `dish_ingredients`
  - Referenced by `favorites.dish_id`
  - Referenced by `plan_items.dish_id`

#### `dish_ingredients`
- **Purpose**: Many-to-many relationship between dishes and ingredients
- **Structure**:
  - `dish_id` (TEXT, FK → dishes)
  - `ingredient_id` (TEXT, FK → ingredients)
  - `qty` (DECIMAL(10,3), NOT NULL) - Quantity needed
  - `unit` (TEXT, FK → lookups_units) - Unit for this quantity
  - `optional` (BOOLEAN) - Whether ingredient is optional
  - `role` (TEXT) - Role: 'main', 'side', etc.
  - `created_at` (TIMESTAMPTZ)
  - PRIMARY KEY (dish_id, ingredient_id)
- **Seed Data**: 51 dish-ingredient relationships
- **Key Features**:
  - Supports different units than ingredient default (requires conversion)
  - Optional ingredients are excluded from pricing calculations
  - Role field helps categorize ingredients

---

### 4. Offers

#### `offers`
- **Purpose**: Current supermarket offers/deals
- **Structure**:
  - `offer_id` (SERIAL PRIMARY KEY)
  - `region_id` (INTEGER, FK → ad_regions)
  - `ingredient_id` (TEXT, FK → ingredients)
  - `price_total` (DECIMAL(10,2), NOT NULL) - Total price of offer
  - `pack_size` (DECIMAL(10,3), NOT NULL) - Size of package
  - `unit_base` (TEXT, FK → lookups_units) - Base unit
  - `valid_from` (DATE, NOT NULL) - Offer start date
  - `valid_to` (DATE, NOT NULL) - Offer end date
  - `source` (TEXT) - Source of offer (e.g., "REWE Prospekt")
  - `source_ref_id` (TEXT) - Reference ID from source
  - `offer_hash` (TEXT, UNIQUE) - For deduplication
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Seed Data**: 23 offers across 3 regions
- **Key Features**:
  - Directly links to `ingredient_id` (no product_map needed)
  - Region-specific (same ingredient can have different offers in different regions)
  - Time-bound (valid_from/valid_to)
  - Deduplication via `offer_hash`
- **Indexes**:
  - `idx_offers_region` - Fast region lookups
  - `idx_offers_ingredient` - Fast ingredient lookups
  - `idx_offers_valid_dates` - Fast date range queries
  - `idx_offers_hash` - Fast deduplication checks

#### `product_map`
- **Purpose**: Maps external aggregator products to ingredients
- **Structure**:
  - `aggregator_product_id` (TEXT PRIMARY KEY)
  - `ingredient_id` (TEXT, FK → ingredients)
  - `confidence` (DECIMAL(3,2)) - Match confidence (0.0-1.0)
  - `notes` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **Note**: This is for external product matching, NOT for basic offer-ingredient relationships
- **Usage**: Used when importing offers from external aggregators

---

### 5. User Data

#### `user_profiles`
- **Purpose**: User profiles (supports anonymous UUID + optional email auth)
- **Structure**:
  - `id` (UUID PRIMARY KEY, DEFAULT uuid_generate_v4())
  - `email` (TEXT, UNIQUE) - Optional email
  - `username` (TEXT) - Optional username
  - `plz` (TEXT) - User's postal code
  - `last_seen` (TIMESTAMPTZ)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **RLS**: Enabled
- **Policies**:
  - Users can view/update their own profile
  - Users can insert their own profile (for signup)

#### `user_roles`
- **Purpose**: User roles (user, admin)
- **Structure**:
  - `user_id` (UUID, FK → user_profiles)
  - `role` (TEXT, NOT NULL, DEFAULT 'user')
  - `created_at` (TIMESTAMPTZ)
  - PRIMARY KEY (user_id, role)
- **RLS**: Enabled
- **Roles**: 'user', 'admin'

#### `favorites`
- **Purpose**: User favorite dishes (paywall feature)
- **Structure**:
  - `user_id` (UUID, FK → user_profiles)
  - `dish_id` (TEXT, FK → dishes)
  - `created_at` (TIMESTAMPTZ)
  - PRIMARY KEY (user_id, dish_id)
- **RLS**: Enabled
- **Note**: Paywall feature - users can save favorites

---

### 6. Meal Planning

#### `plans`
- **Purpose**: Weekly meal plans
- **Structure**:
  - `plan_id` (UUID PRIMARY KEY)
  - `user_id` (UUID, FK → user_profiles)
  - `week_start_date` (DATE, NOT NULL)
  - `week_iso` (TEXT) - ISO week format
  - `status` (TEXT, DEFAULT 'draft') - draft, active, locked, completed
  - `locked_at` (TIMESTAMPTZ)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- **RLS**: Enabled

#### `plan_items`
- **Purpose**: Individual dishes in a meal plan
- **Structure**:
  - `plan_item_id` (UUID PRIMARY KEY)
  - `plan_id` (UUID, FK → plans)
  - `day_of_week` (INTEGER, CHECK 0-6) - 0=Monday, 6=Sunday
  - `dish_id` (TEXT, FK → dishes)
  - `servings` (INTEGER, DEFAULT 1)
  - `created_at` (TIMESTAMPTZ)
- **RLS**: Enabled

#### `plan_item_prices`
- **Purpose**: Detailed pricing breakdown for plan items
- **Structure**:
  - `plan_item_price_id` (UUID PRIMARY KEY)
  - `plan_item_id` (UUID, FK → plan_items)
  - `ingredient_id` (TEXT, FK → ingredients)
  - `qty` (DECIMAL(10,3), NOT NULL)
  - `unit` (TEXT, FK → lookups_units)
  - `baseline_price_per_unit` (DECIMAL(10,2))
  - `baseline_total` (DECIMAL(10,2))
  - `offer_price_per_unit` (DECIMAL(10,2))
  - `offer_total` (DECIMAL(10,2))
  - `offer_source` (TEXT)
  - `offer_ref_id` (TEXT)
  - `savings_abs` (DECIMAL(10,2), DEFAULT 0)
  - `savings_pct` (DECIMAL(5,2), DEFAULT 0)
  - `created_at` (TIMESTAMPTZ)
- **RLS**: Enabled
- **Purpose**: Stores calculated prices for each ingredient in a plan item

#### `plan_totals`
- **Purpose**: Aggregated totals for a meal plan
- **Structure**:
  - `plan_id` (UUID PRIMARY KEY, FK → plans)
  - `total_baseline` (DECIMAL(10,2), DEFAULT 0)
  - `total_offer` (DECIMAL(10,2), DEFAULT 0)
  - `total_savings_abs` (DECIMAL(10,2), DEFAULT 0)
  - `total_savings_pct` (DECIMAL(5,2), DEFAULT 0)
  - `updated_at` (TIMESTAMPTZ)
- **RLS**: Enabled
- **Purpose**: Summary totals for entire plan

---

### 7. Analytics

#### `events`
- **Purpose**: Optional event tracking/analytics
- **Structure**:
  - `event_id` (UUID PRIMARY KEY)
  - `user_id` (UUID, FK → user_profiles, NULLABLE)
  - `event_type` (TEXT, NOT NULL)
  - `event_data` (JSONB)
  - `created_at` (TIMESTAMPTZ)
- **Indexes**: On user_id, event_type, created_at

---

## Database Functions

### `convert_unit(qty, from_unit, to_unit)`
- **Purpose**: Converts quantities between compatible units
- **Supported Conversions**:
  - Weight: g ↔ kg
  - Volume: ml ↔ l
  - Pieces: Stück ↔ st (same)
- **Returns**: DECIMAL or NULL if conversion not possible
- **Usage**: Used in pricing calculations

### `calculate_dish_price(_dish_id, _user_plz)`
- **Purpose**: Calculates dish pricing based on offers and user location
- **Parameters**:
  - `_dish_id` (TEXT): Dish ID
  - `_user_plz` (TEXT, optional): User's postal code
- **Returns**:
  - `dish_id` (TEXT)
  - `base_price` (DECIMAL) - Price using baseline prices
  - `offer_price` (DECIMAL) - Price using current offers
  - `savings` (DECIMAL) - Amount saved
  - `savings_percent` (DECIMAL) - Percentage saved
  - `available_offers_count` (INTEGER) - Number of offers applied
- **Logic**:
  1. Gets `region_id` from PLZ via `postal_codes`
  2. Calculates base price from `ingredients.price_baseline_per_unit`
  3. If region available, finds active offers for each ingredient
  4. Converts units as needed using `convert_unit()`
  5. Calculates offer price using best available offers
  6. Returns pricing breakdown

---

## Data Relationships Diagram

```
chains (1) ──< (many) ad_regions (1) ──< (many) offers
  │                                              │
  │                                              │
  └──< (many) stores                            │
       │                                         │
       └──< (many) store_region_map             │
                                                 │
postal_codes (many) ──> (1) ad_regions         │
                                                 │
ingredients (1) ──< (many) offers ──────────────┘
  │
  └──< (many) dish_ingredients (many) ──> (1) dishes
       │
       └──< (many) plan_item_prices

user_profiles (1) ──< (many) plans (1) ──< (many) plan_items
  │                                                      │
  ├──< (many) favorites                                  │
  └──< (many) user_roles                                 │
                                                          │
                                                          └──< (many) plan_item_prices
```

---

## Key Design Decisions

### 1. **Direct Ingredient-Offer Relationship**
- Offers directly link to `ingredient_id`
- No intermediate `product_map` needed for basic offers
- Simplifies queries and improves performance

### 2. **Chain-Specific Regions**
- Regions are tied to chains (`ad_regions.chain_id`)
- Allows different chains to have different regional structures
- Supports chain-specific pricing strategies

### 3. **Single PLZ → Region Mapping**
- Currently: One PLZ maps to one region (PRIMARY KEY on `plz`)
- **Limitation**: Users in a PLZ can only see offers from one region
- **Potential Enhancement**: Support multiple regions per PLZ

### 4. **Unit Conversion System**
- Ingredients have `unit_default`
- Dish ingredients can use different units
- `convert_unit()` function handles conversions
- Only supports standard conversions (g/kg, ml/l, Stück/st)

### 5. **Time-Bound Offers**
- Offers have `valid_from` and `valid_to` dates
- Pricing function only considers active offers
- Supports weekly/monthly promotional cycles

### 6. **Meal Planning with Detailed Pricing**
- `plan_item_prices` stores per-ingredient pricing
- Allows detailed breakdown of plan costs
- Supports baseline vs. offer price comparison

---

## Current Limitations & Potential Improvements

### 1. **Postal Code Mapping**
- **Current**: One PLZ → One region
- **Issue**: Users in a PLZ can only see offers from one chain/region
- **Enhancement**: Support multiple regions per PLZ (remove PRIMARY KEY, add unique constraint on (plz, region_id))

### 2. **Unit Conversion**
- **Current**: Limited to g/kg, ml/l, Stück/st
- **Issue**: Non-standard units (EL, TL, Bund, Zehen) can't be converted
- **Enhancement**: Add conversion rules for common non-standard units

### 3. **Offer Deduplication**
- **Current**: Uses `offer_hash` for deduplication
- **Enhancement**: Could use `source_ref_id` as alternative deduplication key

### 4. **Pricing Function Performance**
- **Current**: Loops through ingredients
- **Enhancement**: Could be optimized with better indexing or materialized views

### 5. **Missing Fields**
- `offers` table missing `chain_id` (could be derived from `region_id` via `ad_regions`)
- Could add `image_url` to offers for better UI display

---

## Seed Data Analysis

### Data Completeness
- ✅ Chains: 4 chains
- ✅ Regions: 8 regions (2-3 per chain)
- ✅ Stores: 7 stores
- ✅ Ingredients: 36 ingredients
- ✅ Dishes: 27 dishes
- ✅ Dish-Ingredients: 51 relationships
- ✅ Offers: 23 offers (across 3 regions)
- ✅ Postal Codes: 22 PLZ mappings

### Data Quality
- All foreign key relationships are valid
- Unit references match `lookups_units`
- Category references match `lookups_categories`
- Offer dates are in the future (2025-01-13 to 2025-01-19)

---

## Security & Access Control

### Row Level Security (RLS)
- Enabled on: `user_profiles`, `user_roles`, `favorites`, `plans`, `plan_items`, `plan_item_prices`, `plan_totals`
- Public read access on: `dishes`, `ingredients`, `offers`, `chains`, `stores`
- Admin-only write access on: All master data tables

### Policies
- Users can only access their own data
- Public can read dishes, ingredients, offers
- Admin role required for data management

---

## Performance Considerations

### Indexes
- Strategic indexes on foreign keys
- Date range indexes on offers
- Composite indexes where needed

### Query Patterns
- Most queries filter by `region_id` or `ingredient_id`
- Date range queries on offers are common
- Dish pricing is the most complex query

### Optimization Opportunities
- Materialized view for active offers
- Caching of pricing calculations
- Batch processing for meal plan calculations

---

## Migration History

1. `001_initial_schema.sql` - Initial schema creation
2. `002_rls_policies.sql` - Row Level Security policies
3. `003_fix_signup_trigger.sql` - Signup trigger fixes
4. `004_admin_insert_policies.sql` - Admin policies
5. `005-010_fix_pricing_*.sql` - Multiple pricing function fixes

---

## Conclusion

The database schema is well-structured with:
- ✅ Clear separation of concerns
- ✅ Proper normalization
- ✅ Good indexing strategy
- ✅ Comprehensive meal planning support
- ✅ Flexible offer system

**Areas for Enhancement**:
- Multiple regions per PLZ
- Extended unit conversion support
- Performance optimizations
- Additional offer metadata


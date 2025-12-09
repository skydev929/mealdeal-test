# Database Schema Documentation

## Overview

The MealDeal database uses PostgreSQL with a normalized relational schema. The design focuses on flexibility, data integrity, and performance for real-time price calculations.

## Entity Relationship Diagram

```
┌─────────────┐
│   chains    │
└──────┬──────┘
       │
       ├───┐
       │   │
┌──────▼───▼──────┐     ┌──────────────┐
│   ad_regions    │────▶│ postal_codes │
└──────┬──────────┘     └──────────────┘
       │
       │
┌──────▼──────────┐
│     stores      │
└──────┬──────────┘
       │
       │
┌──────▼──────────────┐
│ store_region_map    │
└─────────────────────┘

┌──────────────┐
│  ingredients │
└──────┬───────┘
       │
       ├──────────────┐
       │              │
┌──────▼──────┐  ┌────▼──────────┐
│   dishes    │  │ dish_ingredients│
└──────┬──────┘  └─────────────────┘
       │              │
       │              │
       └──────────────┘
              │
              │
       ┌──────▼──────┐
       │   offers   │
       └────────────┘

┌──────────────┐
│user_profiles │
└──────┬───────┘
       │
       ├──────────────┐
       │              │
┌──────▼──────┐  ┌────▼──────────┐
│ user_roles  │  │   favorites   │
└─────────────┘  └────┬───────────┘
                      │
              ┌───────▼──────┐
              │    dishes    │
              └──────────────┘
```

## Table Definitions

### Lookup Tables

#### `lookups_categories`
Stores dish categories (e.g., "Main Course", "Dessert", "Appetizer").

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| category | TEXT | PRIMARY KEY | Category name |

**Example Data:**
```
category
---------
Main Course
Dessert
Appetizer
Side Dish
```

#### `lookups_units`
Stores measurement units for ingredients.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| unit | TEXT | PRIMARY KEY | Unit abbreviation |
| description | TEXT | | Human-readable description |

**Example Data:**
```
unit | description
-----|------------
g    | Gram
kg   | Kilogram
ml   | Milliliter
l    | Liter
stück| Piece
```

### Location & Chains

#### `chains`
Supermarket chains (e.g., Aldi, Lidl, Rewe).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| chain_id | SERIAL | PRIMARY KEY | Auto-increment ID |
| chain_name | TEXT | NOT NULL, UNIQUE | Chain name |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `chain_name` (unique)

**Example Data:**
```
chain_id | chain_name | created_at
---------|------------|------------
1        | Aldi       | 2025-01-01
2        | Lidl      | 2025-01-01
```

#### `ad_regions`
Advertising regions for offers. Each chain has multiple regions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| region_id | INTEGER | PRIMARY KEY | Region identifier |
| chain_id | INTEGER | NOT NULL, FK → chains | Chain reference |
| label | TEXT | NOT NULL | Region label/name |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `chain_id` → `chains(chain_id)` ON DELETE CASCADE

**Indexes:**
- `chain_id`

**Example Data:**
```
region_id | chain_id | label
----------|---------|------------
500       | 1       | Berlin-Nord
501       | 1       | Berlin-Süd
502       | 2       | Berlin-Nord
```

#### `stores`
Physical store locations.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| store_id | INTEGER | PRIMARY KEY | Store identifier |
| chain_id | INTEGER | NOT NULL, FK → chains | Chain reference |
| store_name | TEXT | NOT NULL | Store name |
| plz | TEXT | | Postal code |
| city | TEXT | | City name |
| street | TEXT | | Street address |
| lat | DECIMAL(10,8) | | Latitude |
| lon | DECIMAL(11,8) | | Longitude |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `chain_id` → `chains(chain_id)` ON DELETE CASCADE

**Indexes:**
- `chain_id`

#### `store_region_map`
Maps stores to advertising regions (many-to-many).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| store_id | INTEGER | NOT NULL, FK → stores | Store reference |
| region_id | INTEGER | NOT NULL, FK → ad_regions | Region reference |

**Primary Key:**
- Composite: `(store_id, region_id)`

**Foreign Keys:**
- `store_id` → `stores(store_id)` ON DELETE CASCADE
- `region_id` → `ad_regions(region_id)` ON DELETE CASCADE

#### `postal_codes`
Maps German postal codes (PLZ) to advertising regions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| plz | TEXT | PRIMARY KEY | Postal code (5 digits) |
| region_id | INTEGER | NOT NULL, FK → ad_regions | Region reference |
| city | TEXT | | City name |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `region_id` → `ad_regions(region_id)` ON DELETE CASCADE

**Indexes:**
- `plz` (primary key)
- `region_id`

**Example Data:**
```
plz   | region_id | city
------|----------|--------
10115 | 500      | Berlin
10117 | 500      | Berlin
10243 | 501      | Berlin
```

### Products & Dishes

#### `ingredients`
Individual ingredients with baseline pricing.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| ingredient_id | TEXT | PRIMARY KEY | Ingredient ID (I001 format) |
| name_canonical | TEXT | NOT NULL | Canonical ingredient name |
| unit_default | TEXT | NOT NULL, FK → lookups_units | Default unit |
| price_baseline_per_unit | DECIMAL(10,2) | | Baseline price per unit |
| allergen_tags | TEXT[] | | Array of allergen tags |
| notes | TEXT | | Additional notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `unit_default` → `lookups_units(unit)`

**Example Data:**
```
ingredient_id | name_canonical | unit_default | price_baseline_per_unit
--------------|----------------|--------------|------------------------
I001          | Tomatoes       | kg          | 2.99
I002          | Milk           | l           | 1.29
I003          | Eggs           | stück       | 0.25
```

#### `dishes`
Meal recipes/dishes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| dish_id | TEXT | PRIMARY KEY | Dish ID (D001 format) |
| name | TEXT | NOT NULL | Dish name |
| category | TEXT | NOT NULL, FK → lookups_categories | Category |
| is_quick | BOOLEAN | DEFAULT FALSE | Quick meal flag |
| is_meal_prep | BOOLEAN | DEFAULT FALSE | Meal prep flag |
| season | TEXT | | Season (e.g., "Summer") |
| cuisine | TEXT | | Cuisine type (e.g., "Italian") |
| notes | TEXT | | Recipe notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `category` → `lookups_categories(category)`

**Example Data:**
```
dish_id | name              | category    | is_quick | is_meal_prep
--------|-------------------|-------------|----------|-------------
D001    | Spaghetti Carbonara | Main Course | FALSE   | FALSE
D002    | Quick Pasta       | Main Course | TRUE    | FALSE
```

#### `dish_ingredients`
Many-to-many relationship between dishes and ingredients.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| dish_id | TEXT | NOT NULL, FK → dishes | Dish reference |
| ingredient_id | TEXT | NOT NULL, FK → ingredients | Ingredient reference |
| qty | DECIMAL(10,3) | NOT NULL | Quantity needed |
| unit | TEXT | NOT NULL, FK → lookups_units | Unit of measurement |
| optional | BOOLEAN | DEFAULT FALSE | Optional ingredient flag |
| role | TEXT | | Role (e.g., "main", "side") |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Primary Key:**
- Composite: `(dish_id, ingredient_id)`

**Foreign Keys:**
- `dish_id` → `dishes(dish_id)` ON DELETE CASCADE
- `ingredient_id` → `ingredients(ingredient_id)` ON DELETE CASCADE
- `unit` → `lookups_units(unit)`

**Indexes:**
- `dish_id`
- `ingredient_id`

**Example Data:**
```
dish_id | ingredient_id | qty  | unit  | optional | role
--------|--------------|------|-------|----------|-----
D001    | I001         | 500  | g     | FALSE    | main
D001    | I002         | 200  | ml    | FALSE    |
D001    | I003         | 2    | stück | FALSE    |
D001    | I004         | 1    | TL    | TRUE     |
```

#### `product_map`
Maps aggregator products to ingredients (for future integration).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| aggregator_product_id | TEXT | PRIMARY KEY | External product ID |
| ingredient_id | TEXT | NOT NULL, FK → ingredients | Ingredient reference |
| confidence | DECIMAL(3,2) | DEFAULT 0.0 | Mapping confidence (0-1) |
| notes | TEXT | | Mapping notes |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `ingredient_id` → `ingredients(ingredient_id)` ON DELETE CASCADE

### Offers

#### `offers`
Current supermarket offers for ingredients.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| offer_id | SERIAL | PRIMARY KEY | Auto-increment ID |
| region_id | INTEGER | NOT NULL, FK → ad_regions | Region reference |
| ingredient_id | TEXT | NOT NULL, FK → ingredients | Ingredient reference |
| price_total | DECIMAL(10,2) | NOT NULL | Total price for pack |
| pack_size | DECIMAL(10,3) | NOT NULL | Pack size |
| unit_base | TEXT | NOT NULL, FK → lookups_units | Unit for pack |
| valid_from | DATE | NOT NULL | Offer start date |
| valid_to | DATE | NOT NULL | Offer end date |
| source | TEXT | | Source (e.g., "aldi", "lidl") |
| source_ref_id | TEXT | | External reference ID |
| offer_hash | TEXT | UNIQUE | Hash for deduplication |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `region_id` → `ad_regions(region_id)` ON DELETE CASCADE
- `ingredient_id` → `ingredients(ingredient_id)` ON DELETE CASCADE
- `unit_base` → `lookups_units(unit)`

**Indexes:**
- `region_id`
- `ingredient_id`
- `(valid_from, valid_to)` - Composite for date range queries
- `offer_hash` (unique)

**Example Data:**
```
offer_id | region_id | ingredient_id | price_total | pack_size | unit_base | valid_from | valid_to
---------|----------|---------------|-------------|-----------|-----------|-----------|----------
1        | 500      | I001          | 2.99        | 500       | g         | 2025-01-13| 2025-01-19
2        | 500      | I002          | 1.49        | 1         | l         | 2025-01-13| 2025-01-19
```

### User Data

#### `user_profiles`
User accounts and profiles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | User UUID (from auth) |
| email | TEXT | UNIQUE | Email address |
| username | TEXT | UNIQUE | Username (optional) |
| plz | TEXT | | Postal code |
| last_seen | TIMESTAMPTZ | DEFAULT NOW() | Last activity timestamp |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `email` (unique)
- `username` (unique)

#### `user_roles`
User roles for authorization.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | UUID | NOT NULL, FK → user_profiles | User reference |
| role | TEXT | NOT NULL, DEFAULT 'user' | Role name |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Primary Key:**
- Composite: `(user_id, role)`

**Foreign Keys:**
- `user_id` → `user_profiles(id)` ON DELETE CASCADE

**Example Roles:**
- `user` - Regular user
- `admin` - Administrator

#### `favorites`
User's favorite dishes.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| user_id | UUID | NOT NULL, FK → user_profiles | User reference |
| dish_id | TEXT | NOT NULL, FK → dishes | Dish reference |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Primary Key:**
- Composite: `(user_id, dish_id)`

**Foreign Keys:**
- `user_id` → `user_profiles(id)` ON DELETE CASCADE
- `dish_id` → `dishes(dish_id)` ON DELETE CASCADE

### Meal Plans (Future Feature)

#### `plans`
User meal plans.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| plan_id | UUID | PRIMARY KEY | Plan UUID |
| user_id | UUID | NOT NULL, FK → user_profiles | User reference |
| week_start_date | DATE | NOT NULL | Week start date |
| week_iso | TEXT | | ISO week identifier |
| status | TEXT | DEFAULT 'draft' | Plan status |
| locked_at | TIMESTAMPTZ | | Lock timestamp |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `user_id` → `user_profiles(id)` ON DELETE CASCADE

#### `plan_items`
Items in meal plans.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| plan_item_id | UUID | PRIMARY KEY | Item UUID |
| plan_id | UUID | NOT NULL, FK → plans | Plan reference |
| day_of_week | INTEGER | CHECK (0-6) | Day of week (0=Sunday) |
| dish_id | TEXT | NOT NULL, FK → dishes | Dish reference |
| servings | INTEGER | DEFAULT 1 | Number of servings |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Foreign Keys:**
- `plan_id` → `plans(plan_id)` ON DELETE CASCADE
- `dish_id` → `dishes(dish_id)` ON DELETE CASCADE

#### `plan_item_prices`
Detailed pricing for plan items.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| plan_item_price_id | UUID | PRIMARY KEY | Price UUID |
| plan_item_id | UUID | NOT NULL, FK → plan_items | Plan item reference |
| ingredient_id | TEXT | NOT NULL, FK → ingredients | Ingredient reference |
| qty | DECIMAL(10,3) | NOT NULL | Quantity |
| unit | TEXT | NOT NULL, FK → lookups_units | Unit |
| baseline_price_per_unit | DECIMAL(10,2) | | Baseline price |
| baseline_total | DECIMAL(10,2) | | Baseline total |
| offer_price_per_unit | DECIMAL(10,2) | | Offer price |
| offer_total | DECIMAL(10,2) | | Offer total |
| offer_source | TEXT | | Offer source |
| offer_ref_id | TEXT | | Offer reference |
| savings_abs | DECIMAL(10,2) | DEFAULT 0 | Absolute savings |
| savings_pct | DECIMAL(5,2) | DEFAULT 0 | Percentage savings |
| created_at | TIMESTAMPTZ | DEFAULT NOW() | Creation timestamp |

**Foreign Keys:**
- `plan_item_id` → `plan_items(plan_item_id)` ON DELETE CASCADE
- `ingredient_id` → `ingredients(ingredient_id)` ON DELETE CASCADE
- `unit` → `lookups_units(unit)`

#### `plan_totals`
Aggregated pricing for plans.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| plan_id | UUID | PRIMARY KEY, FK → plans | Plan reference |
| total_baseline | DECIMAL(10,2) | DEFAULT 0 | Total baseline price |
| total_offer | DECIMAL(10,2) | DEFAULT 0 | Total offer price |
| total_savings_abs | DECIMAL(10,2) | DEFAULT 0 | Total absolute savings |
| total_savings_pct | DECIMAL(5,2) | DEFAULT 0 | Total percentage savings |
| updated_at | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Foreign Keys:**
- `plan_id` → `plans(plan_id)` ON DELETE CASCADE

## Database Functions

### `calculate_dish_price(dish_id, user_plz)`

Calculates dish pricing based on current offers.

**Parameters:**
- `dish_id` (TEXT) - Dish identifier
- `user_plz` (TEXT, optional) - User postal code

**Returns:**
- `dish_id` (TEXT)
- `base_price` (DECIMAL) - Baseline price
- `offer_price` (DECIMAL) - Price with offers
- `savings` (DECIMAL) - Absolute savings
- `savings_percent` (DECIMAL) - Percentage savings
- `available_offers_count` (INTEGER) - Number of active offers

**Logic:**
1. Get `region_id` from `user_plz` (if provided)
2. Calculate base price: Sum of ingredient baseline prices
3. Calculate offer price: Use current offers if available
4. Handle unit conversions
5. Return pricing summary

### `convert_unit(qty, from_unit, to_unit)`

Converts between compatible units.

**Supported Conversions:**
- Weight: `g` ↔ `kg`
- Volume: `ml` ↔ `l`
- Pieces: `stück` ↔ `st`

**Returns:** Converted quantity or NULL if not convertible

## Indexes

### Performance Indexes

- `idx_offers_region` - Fast region-based offer queries
- `idx_offers_ingredient` - Fast ingredient-based offer queries
- `idx_offers_valid_dates` - Fast date range queries
- `idx_dish_ingredients_dish` - Fast dish ingredient lookups
- `idx_dish_ingredients_ingredient` - Fast ingredient dish lookups
- `idx_stores_chain` - Fast chain store queries
- `idx_postal_codes_plz` - Fast PLZ lookups
- `idx_events_user` - User event queries
- `idx_events_type` - Event type queries
- `idx_events_created` - Event timestamp queries

## Triggers

### Automatic Timestamp Updates

All tables with `updated_at` columns have triggers that automatically update the timestamp on row updates:

- `update_chains_updated_at`
- `update_ad_regions_updated_at`
- `update_stores_updated_at`
- `update_ingredients_updated_at`
- `update_dishes_updated_at`
- `update_product_map_updated_at`
- `update_offers_updated_at`
- `update_user_profiles_updated_at`
- `update_plans_updated_at`
- `update_plan_totals_updated_at`

## Data Integrity

### Foreign Key Constraints

All foreign keys use `ON DELETE CASCADE` to maintain referential integrity:
- Deleting a chain deletes its regions and stores
- Deleting a dish deletes its ingredients relationships
- Deleting a user deletes their favorites and plans

### Unique Constraints

- `chains.chain_name` - Unique chain names
- `offers.offer_hash` - Prevents duplicate offers
- `user_profiles.email` - Unique emails
- `user_profiles.username` - Unique usernames

### Check Constraints

- `plan_items.day_of_week` - Must be 0-6
- `offers.valid_from <= valid_to` - Date range validation (implicit)

## Data Types

### Common Patterns

- **IDs:** TEXT for dishes/ingredients (D001, I001), INTEGER for chains/stores, UUID for users/plans
- **Prices:** DECIMAL(10,2) for currency
- **Quantities:** DECIMAL(10,3) for precise measurements
- **Dates:** DATE for offer validity, TIMESTAMPTZ for timestamps
- **Booleans:** BOOLEAN for flags
- **Arrays:** TEXT[] for allergen tags

## Migration Strategy

Migrations are numbered sequentially (001, 002, 003...) and should be run in order:
1. Schema creation
2. RLS policies
3. Functions
4. Indexes
5. Triggers
6. Data fixes/updates

---

**Note:** This schema is optimized for read-heavy workloads with frequent price calculations. Indexes and functions are designed to support real-time pricing queries efficiently.


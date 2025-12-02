# MealDeal - MVP Backend Implementation

A web app that helps users find meals based on current supermarket offers, making everyday cooking cheaper and easier.

## Project Overview

MealDeal connects recipes with current supermarket deals. The system calculates the total price per dish based on current sale prices and allows users to filter by supermarket, price, location, or dietary preference.

## Architecture

### Database Schema

The database is built on Supabase (PostgreSQL) with the following main tables:

- **Core Data:**
  - `dishes` - Recipe/dish information
  - `ingredients` - Ingredient master data
  - `dish_ingredients` - Many-to-many relationship between dishes and ingredients
  - `lookups_categories` - Dish categories
  - `lookups_units` - Measurement units

- **Offers & Stores:**
  - `chains` - Supermarket chains (REWE, Lidl, ALDI, etc.)
  - `stores` - Individual store locations
  - `ad_regions` - Advertising regions for offers
  - `store_region_map` - Mapping stores to regions
  - `postal_codes` - PLZ (ZIP code) to region mapping
  - `offers` - Current supermarket offers/deals
  - `product_map` - Mapping aggregator products to ingredients

- **User Data:**
  - `user_profiles` - User profiles (anonymous UUID + optional email)
  - `user_roles` - User roles (user, admin)
  - `favorites` - User favorite dishes (paywall feature)

- **Meal Planning:**
  - `plans` - Weekly meal plans
  - `plan_items` - Dishes in a plan
  - `plan_item_prices` - Detailed pricing breakdown
  - `plan_totals` - Plan summary totals

- **Analytics:**
  - `events` - Optional event tracking

### Backend Logic

The backend is implemented as an API service layer (`src/services/api.ts`) that:

1. **Abstracts Supabase calls** - Provides a clean interface for the UI
2. **Handles business logic** - Dish pricing, filtering, favorites
3. **Manages data relationships** - Chains, regions, PLZ mapping
4. **Provides admin functions** - CSV import, data viewing

### Key Features

1. **Dish Pricing Calculation** - Database function `calculate_dish_price()` computes:
   - Base price (using baseline ingredient prices)
   - Offer price (using current offers for user's region)
   - Savings amount and percentage
   - Available offers count

2. **PLZ/Region Mapping** - Users enter their postal code (PLZ), which maps to advertising regions to show relevant offers

3. **Filtering** - Dishes can be filtered by:
   - Category
   - Supermarket chain
   - Maximum price
   - Location (PLZ)
   - Quick meals / Meal prep options

4. **Favorites** - Users can save favorite dishes (paywall placeholder implemented)

5. **CSV Import** - Admin tool for importing data with:
   - Validation
   - Dry-run mode
   - Hash-based deduplication for offers

## Setup Instructions

### 1. Database Setup

Run the migration file to create all tables:

```bash
# Using Supabase CLI
supabase db reset
supabase migration up

# Or apply the SQL directly in Supabase Dashboard
# Copy contents of supabase/migrations/001_initial_schema.sql
```

### 2. Environment Variables

Ensure your Supabase credentials are configured in:
- `src/integrations/supabase/client.ts` (already configured)

### 3. CSV Data Import

Import your data files in this order (via Admin Dashboard):

1. `lookups_categories.csv`
2. `lookups_units.csv`
3. `chains_csv.csv`
4. `ad_regions_csv.csv`
5. `stores_csv.csv`
6. `store_region_map_csv.csv`
7. `postal_codes.csv` (create this from your PLZ data)
8. `ingredients.csv`
9. `dishes.csv`
10. `dish_ingredients.csv`
11. `offers_csv.csv`
12. `product_map_csv.csv`

### 4. Deploy Edge Function (CSV Import)

```bash
supabase functions deploy import-csv
```

## API Service Usage

The API service (`src/services/api.ts`) provides these main functions:

```typescript
import { api } from '@/services/api';

// Get dishes with filters
const dishes = await api.getDishes({
  category: 'Hauptgericht',
  chain: 'REWE',
  maxPrice: 30,
  plz: '30165'
});

// Get dish pricing
const pricing = await api.getDishPricing('D001', '30165');

// Manage favorites
await api.addFavorite(userId, dishId);
await api.removeFavorite(userId, dishId);

// Update user PLZ
await api.updateUserPLZ(userId, '30165');
```

## Authentication

Authentication uses Supabase Auth with:
- **Anonymous users** - UUID-based identity (stored in localStorage)
- **Optional email auth** - Magic link login for favorites backup
- **Admin auth** - Email/password for admin dashboard

The authentication workflow is kept separate from business logic and continues to use Supabase directly.

## Database Functions

### `calculate_dish_price(_dish_id, _user_plz)`

Calculates dish pricing based on:
- Base prices from `ingredients.price_baseline_per_unit`
- Current offers from `offers` table (filtered by region from PLZ)
- Returns: base_price, offer_price, savings, savings_percent, available_offers_count

## CSV Import Format

CSV files should have headers matching the database table columns. The import function:
- Validates data types
- Handles date formats
- Converts boolean strings (TRUE/FALSE)
- Generates offer hashes for deduplication
- Supports dry-run mode for validation

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build
```

## Project Structure

```
src/
├── services/
│   └── api.ts              # API service layer
├── hooks/
│   ├── useAuth.ts          # Authentication (uses Supabase directly)
│   ├── useDishPricing.ts   # Dish pricing hook (uses API service)
│   └── ...
├── pages/
│   ├── Index.tsx           # Main dish listing page (uses API service)
│   └── AdminDashboard.tsx  # Admin interface
├── components/
│   ├── admin/
│   │   ├── DataTable.tsx   # Database viewer (uses API service)
│   │   └── CSVImport.tsx   # CSV import tool (uses API service)
│   └── ...
└── integrations/
    └── supabase/           # Supabase client (auth only)

supabase/
├── migrations/
│   └── 001_initial_schema.sql  # Database schema
└── functions/
    └── import-csv/         # CSV import edge function
```

## Notes

- All direct Supabase calls for business logic have been replaced with API service calls
- Authentication continues to use Supabase directly (as per requirements)
- The pricing calculation is done server-side via database function for performance
- Offers are deduplicated using hash-based matching
- PLZ mapping is required for region-based offer filtering

## Privacy & Compliance

- No personal data collected (anonymous UUID)
- Optional email auth for favorites backup
- Short privacy note banner in UI
- Hosting in EU region (Supabase EU/Vercel EU)


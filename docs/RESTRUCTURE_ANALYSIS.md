# Project Restructure Analysis - New Requirements

## Overview
This document outlines the step-by-step changes needed to restructure the ThriftyWe project according to the new MVP requirements.

## Key Conceptual Changes

### 1. **Dishes are NOT recipes**
- Dishes are containers/contexts to make relevant offers visible
- No complete preparation instructions
- No mandatory quantity specifications
- Quantities and units in `dish_ingredients` are optional

### 2. **No total price per dish**
- Dishes do NOT have a total price
- `dish_ingredients` is NOT used for price calculations
- Only used for assignment purposes

### 3. **Savings calculation is per-unit only**
- Formula: `Savings = Base Price (per unit) - Offer Price (per unit)`
- Always calculated per unit (kg/liter/piece)
- No calculation at recipe/dish level
- Aggregated savings at dish level = sum of individual ingredient savings (per unit)

### 4. **Display logic for dishes**
- A dish is displayed if:
  - At least **1 main ingredient** has an active offer, OR
  - At least **2 secondary ingredients** have active offers
- Main vs secondary is determined by `dish_ingredients.role` field

---

## Step-by-Step Implementation Plan

### **PHASE 1: Database & Backend Changes**

#### Step 1.1: Create new SQL function for per-unit savings calculation
**File**: `supabase/migrations/020_calculate_ingredient_savings.sql`

**Changes**:
- Create function `calculate_ingredient_savings_per_unit()` that:
  - Takes `ingredient_id`, `region_id`, `unit` as parameters
  - Returns: `base_price_per_unit`, `offer_price_per_unit`, `savings_per_unit`
  - Always calculates per unit (kg/liter/piece)
  - Selects lowest offer price when multiple offers exist

#### Step 1.2: Create new SQL function for aggregated dish savings
**File**: `supabase/migrations/021_calculate_dish_aggregated_savings.sql`

**Changes**:
- Replace or create new function `calculate_dish_aggregated_savings()` that:
  - Takes `dish_id`, `user_plz` as parameters
  - For each ingredient with an active offer:
    - Calculate per-unit savings using `calculate_ingredient_savings_per_unit()`
    - Sum all per-unit savings to get total aggregated savings
  - Returns: `total_aggregated_savings`, `ingredients_with_offers_count`
  - **DOES NOT** use `dish_ingredients.qty` or `dish_ingredients.unit` for calculation
  - Only uses `dish_ingredients` to determine which ingredients belong to the dish

#### Step 1.3: Create SQL function for dish display filtering
**File**: `supabase/migrations/022_dish_display_filter.sql`

**Changes**:
- Create function `should_display_dish()` that:
  - Takes `dish_id`, `region_id` as parameters
  - Checks if dish has:
    - At least 1 main ingredient (`role = 'main'` or `role = 'Hauptzutat'`) with active offer, OR
    - At least 2 secondary ingredients (`role = 'side'` or `role = 'Nebenzutat'` or `role IS NULL` or `role != 'main'`) with active offers
  - Returns boolean

#### Step 1.4: Deprecate old `calculate_dish_price` function
**File**: `supabase/migrations/023_deprecate_old_pricing_function.sql`

**Changes**:
- Mark old function as deprecated (add comment)
- Keep it for backwards compatibility during migration
- Or remove it if safe to do so

---

### **PHASE 2: API Service Layer Changes**

#### Step 2.1: Update `Dish` interface
**File**: `src/services/api.ts`

**Changes**:
- Remove: `currentPrice`, `basePrice`
- Keep: `savings` (now represents aggregated savings), `savingsPercent`, `availableOffers`
- Add: `totalAggregatedSavings` (sum of per-unit savings)

#### Step 2.2: Update `DishPricing` interface
**File**: `src/services/api.ts`

**Changes**:
- Remove: `base_price`, `offer_price`
- Add: `total_aggregated_savings` (sum of per-unit savings)
- Keep: `available_offers_count`

#### Step 2.3: Create new `IngredientSavings` interface
**File**: `src/services/api.ts`

**Changes**:
- Add interface:
  ```typescript
  export interface IngredientSavings {
    ingredient_id: string;
    ingredient_name: string;
    base_price_per_unit: number;
    offer_price_per_unit: number;
    savings_per_unit: number;
    unit: string; // kg/liter/piece
    has_offer: boolean;
  }
  ```

#### Step 2.4: Update `getDishPricing()` method
**File**: `src/services/api.ts`

**Changes**:
- Replace call to `calculate_dish_price` with `calculate_dish_aggregated_savings`
- Return aggregated savings instead of total price
- Remove price calculations

#### Step 2.5: Update `getDishes()` method
**File**: `src/services/api.ts`

**Changes**:
- Remove price calculation logic
- Use `should_display_dish()` function to filter dishes
- Update filtering logic:
  - If PLZ provided: filter by display criteria (1 main OR 2 secondary)
  - If no PLZ: show nothing (as before)
- Remove `currentPrice` and `basePrice` from returned dishes
- Add `totalAggregatedSavings` to returned dishes

#### Step 2.6: Create new `getIngredientSavings()` method
**File**: `src/services/api.ts`

**Changes**:
- New method to get per-unit savings for a specific ingredient
- Used in dish detail page to show individual ingredient savings

#### Step 2.7: Update `getDishIngredients()` method
**File**: `src/services/api.ts`

**Changes**:
- Remove price calculations based on `qty` and `unit` from `dish_ingredients`
- Calculate per-unit savings only
- Add `savings_per_unit` to `DishIngredient` interface
- Keep `all_offers` array for display purposes

---

### **PHASE 3: Frontend Component Changes**

#### Step 3.1: Update `DishCard` component
**File**: `src/components/DishCard.tsx`

**Changes**:
- Remove price display (`€X.XX`)
- Display aggregated savings: `Save €X.XX` (if savings > 0)
- Show savings percentage badge
- Show number of offers available
- Remove "Pricing unavailable" message (not applicable anymore)

#### Step 3.2: Update `DishDetail` page
**File**: `src/pages/DishDetail.tsx`

**Changes**:
- Remove total dish price display
- Remove `calculateIngredientPrice()` function (no longer needed)
- Remove `calculateBaselinePrice()` function (no longer needed)
- Update ingredient display to show:
  - Per-unit savings: `Base: €X.XX/kg - Offer: €Y.YY/kg = Save €Z.ZZ/kg`
  - Clear notice: "Savings are based on prices per kilo/liter/piece."
- Show aggregated savings at top: `Total Savings: €X.XX`
- Keep offer details display (all offers with "Best Price" badge)
- Remove quantity-based price calculations

#### Step 3.3: Update main menu/Index page
**File**: `src/pages/Index.tsx`

**Changes**:
- Remove price-based sorting (if exists)
- Update sorting to use savings instead of price
- Update filters to remove max price filter (no longer applicable)
- Update display to show aggregated savings instead of prices

---

### **PHASE 4: Data Model & Validation**

#### Step 4.1: Update CSV import validation
**File**: `supabase/functions/import-csv/index.ts`

**Changes**:
- Make `qty` and `unit` optional for `dish_ingredients` table
- Update validation to allow NULL/empty `qty` and `unit`
- Ensure `role` field is properly validated (should be 'main', 'side', 'Hauptzutat', 'Nebenzutat', or NULL)

#### Step 4.2: Update database schema documentation
**File**: `docs/Specification/DATABASE_SCHEMA.md`

**Changes**:
- Document that `dish_ingredients.qty` and `dish_ingredients.unit` are optional
- Document that `dish_ingredients` is for assignment only, not for calculations
- Document new savings calculation logic

---

### **PHASE 5: Testing & Verification**

#### Step 5.1: Test dish display filtering
- Verify dishes with 1 main ingredient offer are shown
- Verify dishes with 2+ secondary ingredient offers are shown
- Verify dishes with 0 main and <2 secondary offers are NOT shown

#### Step 5.2: Test savings calculation
- Verify per-unit savings are calculated correctly
- Verify aggregated savings = sum of per-unit savings
- Verify savings display on dish cards and detail pages

#### Step 5.3: Test offer display
- Verify all offers are shown on detail page
- Verify "Best Price" badge on lowest offer
- Verify per-unit savings notice is displayed

---

## Migration Strategy

### Option A: Big Bang (Recommended for MVP)
1. Implement all changes in sequence
2. Deploy all at once
3. Test thoroughly before release

### Option B: Phased Rollout
1. Phase 1: Backend changes (database functions)
2. Phase 2: API changes
3. Phase 3: Frontend changes
4. Test after each phase

---

## Files to Modify

### Database Migrations (New)
- `supabase/migrations/020_calculate_ingredient_savings.sql`
- `supabase/migrations/021_calculate_dish_aggregated_savings.sql`
- `supabase/migrations/022_dish_display_filter.sql`
- `supabase/migrations/023_deprecate_old_pricing_function.sql`

### Backend/API
- `src/services/api.ts` (major changes)

### Frontend Components
- `src/components/DishCard.tsx`
- `src/pages/DishDetail.tsx`
- `src/pages/Index.tsx`

### Edge Functions
- `supabase/functions/import-csv/index.ts` (validation updates)

### Documentation
- `docs/Specification/DATABASE_SCHEMA.md`

---

## Key Decisions Needed

1. **Role field values**: Confirm what values indicate "main" vs "secondary" ingredients
   - Current: `'main'`, `'side'`, `'Hauptzutat'`, `'Nebenzutat'`
   - Need to standardize or handle all variations

2. **Private label products**: Requirement says "not considered for MVP"
   - Need to identify how to filter these out (by source? by chain?)

3. **Unit standardization**: Ensure all savings are per-unit
   - Need to handle unit conversions for display (kg vs g, liter vs ml)

4. **Backwards compatibility**: 
   - Keep old functions for migration period?
   - Or remove immediately?

---

## Estimated Effort

- **Phase 1 (Database)**: 4-6 hours
- **Phase 2 (API)**: 6-8 hours
- **Phase 3 (Frontend)**: 4-6 hours
- **Phase 4 (Validation)**: 2-3 hours
- **Phase 5 (Testing)**: 4-6 hours

**Total**: ~20-29 hours

---

## Next Steps

1. Review and approve this plan
2. Clarify role field values and private label filtering
3. Start with Phase 1 (Database functions)
4. Test incrementally as we build


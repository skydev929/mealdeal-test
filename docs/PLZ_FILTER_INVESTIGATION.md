# PLZ Filter Logic Investigation

## Overview
This document investigates how the PLZ (postal code) filter logic works in the MealDeal application and identifies potential issues.

## Current Implementation

### 1. PLZ to Region Mapping
- **Table**: `postal_codes`
- **Mapping**: Each PLZ maps to a `region_id` (one-to-one relationship)
- **Usage**: PLZ is used to determine which advertising region the user is in

### 2. Offer Calculation Flow

#### In `calculate_dish_price` Database Function:
1. **PLZ → Region Conversion** (lines 24-30):
   ```sql
   IF _user_plz IS NOT NULL AND _user_plz != '' THEN
     SELECT region_id INTO _region_id
     FROM postal_codes
     WHERE plz = _user_plz
     LIMIT 1;
   END IF;
   ```

2. **Offer Counting** (lines 135-145):
   - Only counts offers if `_region_id IS NOT NULL`
   - If no PLZ or PLZ doesn't match any region → `_offers_count = 0`
   - If PLZ matches region → counts offers for that specific region

3. **Result**:
   - Returns `available_offers_count` (0 if no region found)

#### In `getDishes` API Method:
1. **Pricing Calculation** (line 125):
   ```typescript
   const pricing = await this.getDishPricing(dish.dish_id, filters?.plz);
   ```

2. **Offer Filtering** (line 139):
   ```typescript
   let filtered = dishesWithPricing.filter((d) => d.availableOffers > 0);
   ```
   - **This filters out ALL dishes with 0 offers**

## Identified Issues

### Issue 1: No Dishes Shown Without PLZ
**Problem**: 
- When user hasn't entered PLZ → `available_offers_count = 0` for all dishes
- Filter `availableOffers > 0` excludes ALL dishes
- **Result**: Empty dish list even if offers exist in the database

**Root Cause**:
- The database function requires a valid `region_id` to count offers
- Without PLZ → no `region_id` → `available_offers_count = 0`

### Issue 2: Invalid PLZ Results in Empty List
**Problem**:
- If user enters a PLZ that doesn't exist in `postal_codes` table
- `_region_id` remains NULL
- `available_offers_count = 0` for all dishes
- **Result**: Empty dish list

**Root Cause**:
- No validation or fallback when PLZ doesn't match any region
- No error message to inform user their PLZ is invalid

### Issue 3: Inconsistent Chain Filter Behavior
**Problem**:
- **Chain filter** (lines 165-174): If no PLZ, falls back to ALL regions for that chain
- **Offer filter** (line 139): If no PLZ, returns 0 offers (no fallback)
- **Result**: Inconsistent behavior - chain filter is more lenient than offer filter

**Example**:
- User selects "REWE" chain but no PLZ
- Chain filter: Shows dishes with offers from ANY REWE region
- Offer filter: Shows NO dishes (because `availableOffers = 0`)

### Issue 4: PLZ Required for Offer Filtering
**Problem**:
- The requirement "show only offer available meals" is too strict
- It requires:
  1. PLZ to be set
  2. PLZ to map to a valid region
  3. That region to have active offers
- **Result**: Very restrictive - users without valid PLZ see nothing

## Data Flow Diagram

```
User Input (PLZ)
    ↓
[Index.tsx] loadDishes()
    ↓
[api.ts] getDishes(filters: { plz })
    ↓
For each dish:
    ↓
[api.ts] getDishPricing(dishId, plz)
    ↓
[Database] calculate_dish_price(_dish_id, _user_plz)
    ↓
    ├─→ PLZ → region_id lookup (postal_codes)
    │   ├─→ Found: _region_id = <number>
    │   │   └─→ Count offers for that region
    │   │       └─→ available_offers_count = <count>
    │   └─→ Not Found: _region_id = NULL
    │       └─→ available_offers_count = 0
    ↓
[api.ts] Filter: availableOffers > 0
    ↓
    ├─→ availableOffers > 0: Include dish
    └─→ availableOffers = 0: Exclude dish
```

## Potential Solutions

### Solution 1: Make PLZ Optional for Offer Filtering
**Approach**: Only filter by offers if PLZ is provided and valid
```typescript
// Filter to show only dishes with available offers (if PLZ is set)
let filtered = dishesWithPricing;
if (filters?.plz) {
  filtered = dishesWithPricing.filter((d) => d.availableOffers > 0);
}
```

**Pros**:
- Users without PLZ can still see dishes (with baseline prices)
- Less restrictive

**Cons**:
- Doesn't meet requirement "only show offer available meals"
- Shows dishes without offers when PLZ not set

### Solution 2: Fallback to All Regions When PLZ Invalid
**Approach**: If PLZ doesn't match any region, check offers across all regions
```typescript
// In calculate_dish_price function
IF _region_id IS NULL AND _user_plz IS NOT NULL THEN
  -- PLZ provided but invalid: check all regions
  -- Count offers across all regions
END IF;
```

**Pros**:
- More lenient for invalid PLZ
- Still shows dishes with offers somewhere

**Cons**:
- May show offers not available in user's area
- Complex logic

### Solution 3: Require PLZ and Show Clear Error
**Approach**: Enforce PLZ requirement with clear messaging
```typescript
if (!filters?.plz) {
  // Show message: "Please enter your postal code to see dishes with offers"
  return [];
}
```

**Pros**:
- Clear user guidance
- Meets requirement strictly

**Cons**:
- Blocks users without PLZ
- Poor UX if PLZ validation fails

### Solution 4: Validate PLZ and Provide Feedback
**Approach**: Validate PLZ exists, show error if invalid
```typescript
// Validate PLZ before filtering
if (filters?.plz) {
  const { data: postalData } = await supabase
    .from('postal_codes')
    .select('region_id')
    .eq('plz', filters.plz)
    .limit(1);
  
  if (!postalData || postalData.length === 0) {
    // PLZ not found - show error message
    throw new Error('Postal code not found. Please enter a valid German postal code.');
  }
}
```

**Pros**:
- Clear feedback to user
- Prevents silent failures

**Cons**:
- Requires error handling in UI
- May frustrate users with valid but unmapped PLZ

## Recommendations

1. **Immediate Fix**: Add PLZ validation and user feedback
   - Check if PLZ exists in `postal_codes` table
   - Show clear error message if invalid
   - Guide user to enter valid PLZ

2. **Short-term**: Make offer filtering conditional
   - Only filter by offers if PLZ is valid
   - Show all dishes (with baseline prices) if PLZ not set/invalid
   - Add UI indicator showing "offers available" vs "baseline prices"

3. **Long-term**: Consider multi-region support
   - Allow users to select multiple regions
   - Show offers from all selected regions
   - Better handling of edge cases

## Testing Scenarios

1. **No PLZ entered**:
   - Expected: Show message prompting for PLZ
   - Current: Empty dish list

2. **Valid PLZ with offers**:
   - Expected: Show dishes with offers
   - Current: Works correctly

3. **Valid PLZ without offers**:
   - Expected: Empty list or message
   - Current: Empty list (correct)

4. **Invalid PLZ (not in database)**:
   - Expected: Error message
   - Current: Empty list (silent failure)

5. **PLZ maps to region with no offers**:
   - Expected: Empty list or message
   - Current: Empty list (correct)

## Related Files

- `src/services/api.ts`: `getDishes()`, `getDishPricing()`
- `src/pages/Index.tsx`: `loadDishes()`, PLZ input handling
- `supabase/migrations/010_fix_offer_calculation.sql`: Database function
- `src/components/PLZInput.tsx`: PLZ input component


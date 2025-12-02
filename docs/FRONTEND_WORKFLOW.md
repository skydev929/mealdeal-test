# Frontend Workflow Implementation

This document describes the complete frontend workflow implementation for MealDeal, aligned with the database schema.

## Overview

The frontend is fully integrated with the Supabase backend and provides a complete user experience for browsing dishes, filtering, viewing pricing, and managing favorites.

## Key Features Implemented

### 1. **Dish Browsing & Display**
- Grid layout showing dish cards with all relevant information
- Responsive design (1 column mobile, 2 columns tablet, 3 columns desktop)
- Real-time pricing calculations based on user's PLZ
- Savings display when offers are available

### 2. **Filtering System**
- **Category Filter**: Filter by dish category (Hauptgericht, Dessert, etc.)
- **Chain Filter**: Filter by supermarket chain (REWE, Lidl, ALDI)
- **Price Filter**: Slider to set maximum price (€5-€50)
- **Quick Meals Filter**: Checkbox to show only quick meals (is_quick = TRUE)
- **Meal Prep Filter**: Checkbox to show only meal prep dishes (is_meal_prep = TRUE)

### 3. **Sorting Options**
- **Price (Low to High)**: Sort by current offer price
- **Savings (High to Low)**: Sort by savings amount
- **Name (A-Z)**: Alphabetical sorting

### 4. **Dish Card Features**
- Dish name and category
- Quick meal badge (⚡) when applicable
- Meal prep badge (👨‍🍳) when applicable
- Current price (using offers if available)
- Base price (strikethrough when offers exist)
- Savings badge with amount and percentage
- Available offers count
- Favorite heart button (with paywall placeholder)

### 5. **Location-Based Pricing**
- PLZ input in hero section
- Automatic price calculation based on user's postal code
- Region mapping (PLZ → region_id → offers)
- Shows "for PLZ {code}" in results header

### 6. **User Experience Enhancements**
- Loading states during data fetching
- Empty states with helpful messages
- Error handling with toast notifications
- Responsive design for all screen sizes
- Smooth transitions and hover effects

## Component Structure

### `src/pages/Index.tsx`
Main page component that orchestrates the entire workflow:
- Manages all state (filters, dishes, user data)
- Handles API calls through the `api` service
- Coordinates between filters and dish display
- Manages favorites and user preferences

### `src/components/DishCard.tsx`
Individual dish card component:
- Displays dish information
- Shows pricing and savings
- Badges for quick meals and meal prep
- Favorite button integration

### `src/components/DishFilters.tsx`
Filter sidebar component:
- Category dropdown
- Chain dropdown
- Quick meals checkbox
- Meal prep checkbox
- Price slider

### `src/components/PLZInput.tsx`
Postal code input component:
- Validates 5-digit PLZ format
- Updates user location
- Shows loading state during update

## Data Flow

1. **User Authentication**
   - User signs up/logs in
   - User profile created with UUID
   - PLZ loaded from user profile

2. **Initial Data Load**
   - Categories loaded from `lookups_categories`
   - Chains loaded from `chains`
   - Dishes loaded from `dishes` with filters

3. **Pricing Calculation**
   - For each dish, `calculate_dish_price` RPC function called
   - Function uses user's PLZ to find region
   - Looks up offers for dish ingredients in that region
   - Calculates base price (from ingredient baselines)
   - Calculates offer price (from current offers)
   - Returns savings amount and percentage

4. **Filtering**
   - Filters applied in `getDishes` API call
   - Category, is_quick, is_meal_prep: Database-level filtering
   - Chain: Post-query filtering (checks if dish has offers from chain)
   - Max Price: Client-side filtering after pricing calculation

5. **Sorting**
   - Client-side sorting after all data loaded
   - Sorts by price, savings, or name

## API Integration

All data access goes through `src/services/api.ts`:
- `getDishes()`: Fetches dishes with filters and pricing
- `getDishPricing()`: Calls `calculate_dish_price` RPC
- `getCategories()`: Fetches categories
- `getChains()`: Fetches chains
- `getFavorites()`: Fetches user's favorites
- `addFavorite()` / `removeFavorite()`: Manages favorites (paywall placeholder)

## Database Schema Alignment

The frontend correctly uses:
- `dish_id` (not `id`) for dishes
- `is_quick` and `is_meal_prep` boolean fields
- `category` from `lookups_categories`
- `chain_name` from `chains`
- `plz` from `user_profiles`
- `calculate_dish_price()` RPC function for pricing

## User Workflow

1. **Sign Up/Login**
   - User authenticates via Supabase Auth
   - Profile created automatically

2. **Enter Location**
   - User enters PLZ in hero section
   - Location saved to user profile
   - Dishes reload with location-based pricing

3. **Browse Dishes**
   - Dishes displayed in grid
   - Each card shows pricing, savings, badges
   - User can scroll and browse

4. **Apply Filters**
   - Select category, chain, price range
   - Toggle quick meals or meal prep
   - Results update automatically

5. **Sort Results**
   - Choose sort option from dropdown
   - Results re-sorted instantly

6. **View Favorites** (Paywall Placeholder)
   - Click heart icon on dish card
   - Shows paywall message
   - Feature ready for implementation

## Responsive Design

- **Mobile (< 640px)**: 1 column grid, stacked filters
- **Tablet (640px - 1024px)**: 2 column grid, sidebar filters
- **Desktop (> 1024px)**: 3 column grid, sticky sidebar filters

## Performance Optimizations

- Pricing calculated in parallel for all dishes
- Filters applied at database level when possible
- Client-side sorting for instant feedback
- Loading states prevent UI blocking
- Error boundaries for graceful error handling

## Future Enhancements

- [ ] Implement favorites (remove paywall placeholder)
- [ ] Add dish detail page
- [ ] Add ingredient list view
- [ ] Add meal planning feature
- [ ] Add shopping list generation
- [ ] Add notifications for new offers
- [ ] Add analytics tracking


# Quick Reference Guide

## For Developers

### Project Setup
```bash
npm install
# Set .env.local with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
npm run dev
```

### Key Files
- `src/App.tsx` - Main app component, routing
- `src/services/api.ts` - API service layer
- `src/hooks/useAuth.ts` - Authentication logic
- `supabase/migrations/` - Database migrations

### Common Tasks

**Add New Page:**
1. Create component in `src/pages/`
2. Add route in `src/App.tsx`
3. Update navigation if needed

**Add New API Method:**
1. Add method to `src/services/api.ts`
2. Use Supabase client for queries
3. Handle errors appropriately

**Database Migration:**
1. Create file: `supabase/migrations/XXX_description.sql`
2. Run: `supabase db push` (or manually in SQL Editor)

## For Admins

### CSV Import Order
1. Lookup tables (categories, units)
2. Chains
3. Ad Regions
4. Stores
5. Postal Codes
6. Store-Region Map
7. Ingredients
8. Dishes
9. Dish-Ingredients
10. Offers

### Common CSV Errors
- **Foreign key error:** Import referenced table first
- **Date format:** Use YYYY-MM-DD (e.g., 2025-01-13)
- **Number format:** Use 2.99 or 2,99 (no currency symbols)
- **Unit not found:** Import units lookup first

### Admin SQL Commands

**Assign Admin Role:**
```sql
INSERT INTO user_roles (user_id, role)
VALUES ('user-uuid-here', 'admin');
```

**Check User Roles:**
```sql
SELECT up.email, ur.role
FROM user_profiles up
LEFT JOIN user_roles ur ON up.id = ur.user_id;
```

**View Current Offers:**
```sql
SELECT o.*, i.name_canonical, ar.label
FROM offers o
JOIN ingredients i ON o.ingredient_id = i.ingredient_id
JOIN ad_regions ar ON o.region_id = ar.region_id
WHERE o.valid_from <= CURRENT_DATE
  AND o.valid_to >= CURRENT_DATE;
```

## For Users

### Quick Actions
- **Set Location:** Enter PLZ in hero section
- **Filter Dishes:** Use sidebar filters
- **View Details:** Click dish card
- **Add Favorite:** Click heart icon
- **View Favorites:** Click "Favorites" tab

### Understanding Prices
- **Green Badge:** Savings amount and percentage
- **Strikethrough:** Base price (when offer exists)
- **"On Sale" Badge:** Ingredient has current offer

## Database Quick Reference

### Key Tables
- `dishes` - Meal recipes
- `ingredients` - Individual ingredients
- `dish_ingredients` - Dish-ingredient relationships
- `offers` - Current supermarket offers
- `postal_codes` - PLZ to region mapping
- `user_profiles` - User accounts
- `favorites` - User's favorite dishes

### Key Functions
- `calculate_dish_price(dish_id, user_plz)` - Calculate dish pricing
- `convert_unit(qty, from, to)` - Convert units
- `check_email_exists(email)` - Validate email
- `check_username_exists(username)` - Validate username

### Common Queries

**Get dishes with offers:**
```sql
SELECT d.*, 
       calculate_dish_price(d.dish_id, '10115') as pricing
FROM dishes d
WHERE EXISTS (
  SELECT 1 FROM offers o
  JOIN dish_ingredients di ON o.ingredient_id = di.ingredient_id
  WHERE di.dish_id = d.dish_id
    AND o.region_id = (SELECT region_id FROM postal_codes WHERE plz = '10115')
    AND o.valid_from <= CURRENT_DATE
    AND o.valid_to >= CURRENT_DATE
);
```

**Get user favorites:**
```sql
SELECT d.*
FROM dishes d
JOIN favorites f ON d.dish_id = f.dish_id
WHERE f.user_id = 'user-uuid-here';
```

## API Quick Reference

### Common API Calls

**Get Dishes:**
```typescript
const dishes = await api.getDishes({
  category: 'Main Course',
  maxPrice: 30,
  plz: '10115'
});
```

**Get Dish Details:**
```typescript
const dish = await api.getDishById('D001');
const ingredients = await api.getDishIngredients('D001', '10115');
const pricing = await api.getDishPricing('D001', '10115');
```

**Favorites:**
```typescript
await api.addFavorite(userId, dishId);
await api.removeFavorite(userId, dishId);
const favorites = await api.getFavorites(userId);
```

**User Profile:**
```typescript
await api.updateUserPLZ(userId, '10115');
const plz = await api.getUserPLZ(userId);
const isValid = await api.validatePLZ('10115');
```

## Environment Variables

```env
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=xxx
```

## URLs

- **Development:** http://localhost:8080
- **Login:** /login
- **Main Page:** /
- **Dish Detail:** /dish/:dishId
- **Admin Dashboard:** /admin/dashboard
- **Privacy:** /privacy
- **Terms:** /terms

## File Structure

```
src/
├── components/     # React components
├── hooks/         # Custom hooks
├── pages/         # Page components
├── services/      # API services
└── integrations/  # Third-party integrations

supabase/
├── migrations/    # Database migrations
├── functions/     # Edge functions
└── seed/          # Seed data
```

## Troubleshooting

**"No dishes found"**
- Check PLZ is set
- Verify offers exist for region
- Check offer dates are current

**"Postal code not found"**
- Verify PLZ exists in `postal_codes` table
- Check format (5 digits for Germany)

**"CSV import fails"**
- Check import order
- Verify foreign key references
- Validate date format (YYYY-MM-DD)

**"Authentication errors"**
- Check Supabase URL and keys
- Verify RLS policies
- Check user profile exists

---

**Need more details?** See full documentation in `/docs` folder.


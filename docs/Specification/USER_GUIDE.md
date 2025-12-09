# User Guide

## Getting Started

### Creating an Account

1. **Navigate to Login Page**
   - Click "Sign Up" or navigate to `/login`
   - Toggle to "Sign Up" mode if needed

2. **Fill in Information**
   - **Email:** Your email address (required)
   - **Password:** At least 6 characters (required)
   - **Username:** Optional display name
   - **PLZ:** Optional postal code (can be set later)

3. **Submit**
   - Click "Sign Up"
   - If email confirmation is required, check your email
   - Sign in after confirmation

### Signing In

1. Enter your email and password
2. Click "Sign In"
3. You'll be redirected to the main page

## Main Features

### Setting Your Location

**Why it matters:**
- Supermarket offers vary by region
- Prices are calculated based on offers in your area
- Only dishes with available offers in your region are shown

**How to set:**
1. On the main page, find the PLZ input field in the hero section
2. Enter your German postal code (e.g., "10115" for Berlin)
3. Click "Update" or press Enter
4. The system validates your PLZ and updates your location

**Note:** If your PLZ is not found, it may not be in our database yet. Contact support to add your area.

### Browsing Dishes

**Main View:**
- Grid of dish cards showing available meals
- Each card displays:
  - Dish name
  - Category badge
  - Current price (with offers applied)
  - Base price (if different)
  - Savings amount and percentage
  - Number of available offers
  - Favorite button

**Filtering Dishes:**

1. **Category Filter:**
   - Select a category from the dropdown
   - Options: All, Main Course, Dessert, etc.
   - "All" shows dishes from all categories

2. **Chain Filter:**
   - Select a supermarket chain
   - Only shows dishes with offers from that chain
   - Options depend on your PLZ region

3. **Price Filter:**
   - Use the slider to set maximum price
   - Only dishes at or below this price are shown
   - Default: €30

4. **Quick Meals Toggle:**
   - Enable to show only quick meals (< 30 min prep)
   - Useful for busy weekdays

5. **Meal Prep Toggle:**
   - Enable to show only meal prep dishes
   - Good for weekend cooking

**Sorting Dishes:**
- **Price (Low):** Cheapest dishes first
- **Savings (High):** Best savings first
- **Name (A-Z):** Alphabetical order

### Viewing Dish Details

1. **Click on a dish card** to view details
2. **Dish Information:**
   - Full dish name
   - Category and tags (Quick, Meal Prep, Cuisine, Season)
   - Pricing summary with savings
   - Notes (if available)

3. **Ingredients List:**
   - **Required Ingredients:**
     - Ingredient name
     - Quantity and unit
     - Current price (with offer if available)
     - Baseline price (if different)
     - "On Sale" badge if offer exists
   - **Optional Ingredients:**
     - Same information as required
     - Marked as "Optional"

4. **Pricing Breakdown:**
   - Total ingredients cost
   - Current price vs. base price
   - Savings amount and percentage

### Using Favorites

**Adding to Favorites:**
1. Click the heart icon on any dish card
2. The heart fills in red
3. A success message appears

**Removing from Favorites:**
1. Click the filled heart icon
2. The heart becomes empty
3. A success message appears

**Viewing Favorites:**
1. Click the "Favorites" tab on the main page
2. See all your favorited dishes
3. Badge shows count of favorites
4. Filter and sort work the same as "All Meals"

**Use Cases:**
- Save dishes you want to cook this week
- Build a personal recipe collection
- Quick access to your preferred meals

## Understanding Pricing

### How Prices Are Calculated

1. **Base Price:**
   - Sum of all required ingredient baseline prices
   - Uses standard market prices
   - Represents "normal" cost

2. **Offer Price:**
   - Uses current supermarket offers when available
   - Calculated per ingredient:
     - If offer exists: `(quantity / pack_size) × offer_price`
     - If no offer: Uses baseline price
   - Sum of all ingredient offer prices

3. **Savings:**
   - Difference: `base_price - offer_price`
   - Percentage: `(savings / base_price) × 100`

### Price Display

- **Green Badge:** Shows savings amount and percentage
- **Strikethrough:** Base price when offer price is lower
- **"On Sale" Badge:** Individual ingredients with offers
- **"N/A":** Price unavailable (missing baseline or offer data)

### Important Notes

- Prices update automatically when offers change
- Only dishes with at least one active offer are shown
- Prices are estimates based on current offers
- Actual store prices may vary slightly

## Tips for Best Experience

### Maximizing Savings

1. **Check Regularly:**
   - Offers change weekly
   - Refresh the page to see new deals

2. **Use Filters:**
   - Filter by chain to see specific supermarket deals
   - Set max price to find budget-friendly options

3. **Look for High Savings:**
   - Sort by "Savings (High)" to see best deals first
   - Green badges indicate significant savings

4. **Plan Ahead:**
   - Favorite dishes you want to cook
   - Check favorites tab for quick access

### Finding the Right Dish

1. **Quick Meals:**
   - Enable "Quick Meals" filter for fast preparation
   - Perfect for weeknight dinners

2. **Meal Prep:**
   - Enable "Meal Prep" filter for batch cooking
   - Great for weekend meal preparation

3. **Category Browsing:**
   - Browse by category to find specific meal types
   - Explore new cuisines and dishes

### Managing Your Account

**Updating Location:**
- Change PLZ anytime from the main page
- System updates dishes automatically
- Previous location is remembered

**Profile Information:**
- Username and email shown in user menu
- Click user avatar to see profile
- Sign out from user menu

## Troubleshooting

### "No dishes found"

**Possible Causes:**
- No PLZ set: Enter your postal code
- No offers in your region: Offers may not be available yet
- Filters too restrictive: Try removing filters
- No valid offers: Check back later for new offers

**Solutions:**
- Enter or update your PLZ
- Remove or adjust filters
- Try a different category or chain
- Contact support if issue persists

### "Postal code not found"

**Cause:** Your PLZ is not in our database

**Solutions:**
- Try a nearby postal code
- Contact support to add your area
- Check that you entered the correct format (5 digits for Germany)

### Prices seem incorrect

**Possible Causes:**
- Offers may have expired
- Unit conversion issues
- Missing baseline prices

**Solutions:**
- Refresh the page
- Check dish detail page for ingredient breakdown
- Report issue to support with dish ID

### Can't add to favorites

**Possible Causes:**
- Not signed in
- Session expired

**Solutions:**
- Sign in or refresh session
- Try signing out and back in
- Clear browser cache if issue persists

## Keyboard Shortcuts

- **Enter:** Submit PLZ input
- **Tab:** Navigate between filters
- **Escape:** Close modals/dropdowns

## Browser Compatibility

**Supported Browsers:**
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

**Mobile:**
- iOS Safari
- Chrome Mobile
- Responsive design for all screen sizes

## Privacy & Data

**What We Store:**
- Email address (for authentication)
- Username (optional)
- Postal code (for location-based offers)
- Favorite dishes

**What We Don't Store:**
- Payment information
- Personal shopping history
- Location data beyond PLZ

**Data Usage:**
- Used only to provide service
- Not shared with third parties
- See Privacy Policy for details

## Getting Help

**Support Channels:**
- Email: [support email]
- In-app: Contact form (if available)
- Documentation: Check this guide

**Reporting Issues:**
- Include your PLZ
- Describe the problem
- Screenshots helpful
- Dish ID if relevant

---

**Happy cooking and saving! 🍽️💰**


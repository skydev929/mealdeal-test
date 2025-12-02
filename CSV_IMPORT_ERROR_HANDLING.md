# CSV Import Error Handling Guide

## Overview

The CSV import feature now provides **user-friendly error messages** with actionable fixes. When errors occur during validation or import, users see clear explanations of what went wrong and how to fix it.

## Features

### 1. User-Friendly Error Messages

Errors are automatically translated from technical database messages to plain language that non-developers can understand.

**Example:**
- ❌ **Before**: `violates foreign key constraint "ingredients_unit_default_fkey"`
- ✅ **After**: `Unit Not Found - The unit specified in your CSV does not exist in the system.`

### 2. Actionable Fix Instructions

Each error includes step-by-step instructions on how to resolve it.

**Example:**
```
Error: Unit Not Found
Fix Instructions:
1. Check that the unit value matches exactly (case-sensitive)
2. Import the "Units (Lookup)" CSV file first
3. Verify the unit exists in lookups_units table
4. Common units: g, kg, l, ml, st, Stück, EL, TL, Bund, Zehen
```

### 3. Error Categories

Errors are categorized by severity:
- 🔴 **Errors**: Must be fixed before import can succeed
- 🟡 **Warnings**: May not prevent import but should be reviewed
- 🔵 **Info**: Informational messages

### 4. Expandable Error Details

- Click "Show How to Fix" to see detailed instructions
- Click "Show technical details" to see the original error message (for debugging)

## Error Types and Fixes

### Foreign Key Errors

#### Unit Not Found
**When it occurs:** Importing ingredients, dish_ingredients, or offers with a unit that doesn't exist.

**How to fix:**
1. Import `lookups_units.csv` first
2. Verify unit names match exactly (case-sensitive)
3. Common units: g, kg, l, ml, st, Stück, EL, TL, Bund, Zehen

#### Category Not Found
**When it occurs:** Importing dishes with a category that doesn't exist.

**How to fix:**
1. Import `lookups_categories.csv` first
2. Verify category names match exactly (case-sensitive)
3. Common categories: Hauptgericht, Dessert, Snack, etc.

#### Ingredient Not Found
**When it occurs:** Importing dish_ingredients or offers referencing a non-existent ingredient.

**How to fix:**
1. Import `ingredients.csv` first
2. Check that ingredient_id matches exactly (e.g., I001, I002)
3. Verify the ingredient exists in the ingredients table

#### Dish Not Found
**When it occurs:** Importing dish_ingredients or plan_items referencing a non-existent dish.

**How to fix:**
1. Import `dishes.csv` first
2. Check that dish_id matches exactly (e.g., D001, D002)
3. Verify the dish exists in the dishes table

#### Region Not Found
**When it occurs:** Importing offers or postal_codes with a region_id that doesn't exist.

**How to fix:**
1. Import `ad_regions.csv` first
2. Check that region_id is a valid number (e.g., 500, 501)
3. Verify the region exists in the ad_regions table

#### Chain Not Found
**When it occurs:** Importing ad_regions or stores with a chain_id that doesn't exist.

**How to fix:**
1. Import `chains.csv` first
2. Check that chain_id is a valid number (e.g., 10, 11)
3. Verify the chain exists in the chains table

### Format Errors

#### Wrong Number of Columns
**When it occurs:** CSV row has different number of columns than the header.

**How to fix:**
1. Check for extra commas or missing values
2. Verify the header row matches the expected format
3. Check for empty rows or formatting issues
4. Make sure text with commas is properly quoted

#### Invalid Number Format
**When it occurs:** A number field contains non-numeric characters.

**How to fix:**
1. Use dots (.) or commas (,) as decimal separators
2. Remove any text or special characters from number fields
3. German format: `3,75` (automatically converted)
4. English format: `3.75`

#### Invalid Date Format
**When it occurs:** Date fields are not in the correct format.

**How to fix:**
1. Use format: `YYYY-MM-DD` (e.g., 2025-01-13)
2. Make sure dates are valid (not 2025-13-45)
3. Check that valid_from is before valid_to

#### Invalid Quantity
**When it occurs:** Quantity is not a valid number or is zero/negative.

**How to fix:**
1. Use numbers only (e.g., 250 or 250,5)
2. Quantity must be greater than 0
3. Check for typos or formatting issues

### Duplicate Entry Warnings

**When it occurs:** Record already exists in the database.

**Note:** This is usually OK - the system will update existing records. If you want to avoid duplicates, check your CSV for repeated entries.

### Permission Errors

**When it occurs:** The import function doesn't have permission to write to the database.

**How to fix:**
1. This is a system configuration issue
2. Contact your administrator
3. Make sure SUPABASE_SERVICE_ROLE_KEY is configured

## Import Order

To avoid foreign key errors, import data in this order:

1. ✅ **lookups_categories** - Categories lookup
2. ✅ **lookups_units** - Units lookup
3. ✅ **chains** - Chains
4. ✅ **ad_regions** - Regions (requires chains)
5. ✅ **stores** - Stores (requires chains)
6. ✅ **store_region_map** - Store-region mapping
7. ✅ **postal_codes** - PLZ mapping (requires regions)
8. ✅ **ingredients** - Ingredients (requires units)
9. ✅ **dishes** - Dishes (requires categories)
10. ✅ **dish_ingredients** - Dish-ingredient relationships
11. ✅ **offers** - Offers (requires regions, ingredients)
12. ✅ **product_map** - Product mapping (optional)

## Using the Error Display

### During Validation (Dry Run)

1. Select your CSV file and data type
2. Keep "Dry run" checked
3. Click "Validate"
4. Review all errors in the error display
5. Fix errors in your CSV file
6. Re-validate until no errors remain
7. Uncheck "Dry run" and click "Import"

### During Import

1. Errors are displayed after import completes
2. Check how many rows were imported successfully
3. Review errors for rows that failed
4. Fix errors and re-import (duplicates will be updated)

## Best Practices

1. **Always validate first**: Use dry run to catch errors before importing
2. **Fix errors systematically**: Start with the first error and work through them
3. **Check import order**: Make sure prerequisite data is imported first
4. **Verify data exists**: Check that referenced IDs exist in the database
5. **Check formatting**: Ensure dates, numbers, and text match expected formats

## Technical Details

The error handling system:
- Maps technical database errors to user-friendly messages
- Provides context-specific fixes based on the table being imported
- Shows row numbers for easy error location
- Groups errors by severity (error, warning, info)
- Allows expanding/collapsing error details
- Preserves original error messages for debugging

## Support

If you encounter errors that aren't covered here:
1. Check the "Show technical details" section
2. Verify your CSV format matches the expected structure
3. Check the import order guide
4. Contact support with the error message and CSV file




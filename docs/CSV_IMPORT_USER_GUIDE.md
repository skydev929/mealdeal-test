# CSV Import Guide - Complete User Manual

Welcome! This guide will walk you through importing data into MealDeal using CSV files. Whether you're setting up the system for the first time or updating existing data, this guide will help you do it successfully.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Understanding the Import Process](#understanding-the-import-process)
3. [Required vs Optional Fields](#required-vs-optional-fields)
4. [Import Order - Why It Matters](#import-order---why-it-matters)
5. [Table-by-Table Guide](#table-by-table-guide)
6. [Understanding Validation](#understanding-validation)
7. [Common Errors and How to Fix Them](#common-errors-and-how-to-fix-them)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Getting Started

### What is CSV Import?

CSV (Comma-Separated Values) import allows you to upload data files that contain information about:
- Supermarket chains and stores
- Ingredients and their prices
- Recipes (dishes) and their ingredients
- Current offers and deals
- Geographic regions and postal codes

Think of it like filling out a spreadsheet - each row is a record, and each column is a piece of information about that record.

### Before You Begin

**Always use "Dry Run" first!** This feature validates your data without actually importing it. It's like a practice run that shows you any problems before they cause issues.

---

## Understanding the Import Process

### Step 1: Prepare Your CSV File

Your CSV file should:
- Have a **header row** as the first line (column names)
- Use commas (`,`) to separate values
- Use quotes (`"`) around values that contain commas
- Be saved in UTF-8 encoding
- Have consistent formatting throughout

**Example of a good CSV file:**
```csv
chain_id,chain_name
C01,REWE
C02,Lidl
C03,ALDI
```

### Step 2: Select Your File Type

In the admin dashboard, you'll see a dropdown menu with different table types. Choose the one that matches your CSV file. For example:
- If your file contains chain information → select "Chains"
- If your file contains ingredient data → select "Ingredients"
- And so on...

### Step 3: Run Validation (Dry Run)

Click "Dry Run" to check your data. The system will:
- ✅ Check that all required fields are filled
- ✅ Verify data formats (dates, numbers, etc.)
- ✅ Check that referenced IDs exist in other tables
- ✅ Show you any errors before importing

**If validation succeeds:** You'll see a green message showing how many rows are valid and ready to import.

**If validation fails:** You'll see detailed error messages explaining what's wrong and which rows have problems.

### Step 4: Import Your Data

Once validation passes, click "Import" to actually add the data to the database. The system will show you how many rows were successfully imported.

---

## Required vs Optional Fields

### What Does "Required" Mean?

Required fields **must** have a value in every row. If a required field is empty, the import will fail for that row.

Think of it like filling out a form:
- **Required fields** are like your name on a form - you can't leave it blank
- **Optional fields** are like your middle name - nice to have, but not necessary

### Why Some Fields Are Required

Required fields are essential for the system to work properly. For example:
- `chain_id` is required because every store needs to belong to a chain
- `ingredient_id` is required because every offer must reference a specific ingredient
- `label` is required because every region needs a name to identify it

### What Happens If You Leave a Required Field Empty?

The system will show you an error message like this:
```
Row 5: Invalid label: label cannot be empty or null. label is a required field.
Row Data:
  region_id: "R001"
  chain_id: "C11"
  label: "(empty)"
```

This tells you:
- Which row has the problem (Row 5)
- Which field is missing (label)
- What the rest of the row looks like

---

## Import Order - Why It Matters

### The Problem: Dependencies

Some tables reference data from other tables. For example:
- A **store** must reference a **chain** that already exists
- An **offer** must reference an **ingredient** that already exists
- A **dish_ingredient** must reference both a **dish** and an **ingredient** that exist

If you try to import data that references something that doesn't exist yet, you'll get a "foreign key" error.

### The Solution: Import in Order

Import tables in this specific order:

#### Phase 1: Foundation Data (No Dependencies)
1. **Lookup Tables** (if you have them)
   - `lookups_categories` - Categories like "Hauptgericht", "Dessert"
   - `lookups_units` - Units like "kg", "g", "l", "ml"

#### Phase 2: Chains and Locations
2. **Chains** - Supermarket chains (REWE, Lidl, ALDI, etc.)
3. **Ad Regions** - Geographic regions for advertising
4. **Stores** - Individual store locations
5. **Store Region Map** - Links stores to regions
6. **Postal Codes** - Links postal codes to regions

#### Phase 3: Core Content
7. **Ingredients** - All ingredients used in recipes
8. **Dishes** - All recipes/meals

#### Phase 4: Relationships
9. **Dish Ingredients** - Links dishes to their ingredients

#### Phase 5: Current Data
10. **Offers** - Current deals and prices

### Quick Reference Order

```
1. lookups_categories (if needed)
2. lookups_units (if needed)
3. chains
4. ad_regions
5. stores
6. store_region_map
7. postal_codes
8. ingredients
9. dishes
10. dish_ingredients
11. offers
```

**Remember:** If you skip a step or import out of order, you'll get errors about missing data!

---

## Table-by-Table Guide

### 1. Chains

**What it is:** Supermarket chains like REWE, Lidl, ALDI, etc.

**Required Fields:**
- `chain_id` - Unique identifier (e.g., "C01", "C02")
- `chain_name` - Name of the chain (e.g., "REWE", "Lidl")

**Example:**
```csv
chain_id,chain_name
C01,REWE
C02,Lidl
C03,ALDI
```

**Tips:**
- Use consistent ID format (e.g., always "C01" not sometimes "1")
- Chain names should match how they appear in stores

---

### 2. Ad Regions

**What it is:** Geographic regions used for organizing offers and advertising.

**Required Fields:**
- `region_id` - Unique identifier (e.g., "R001", "R002")
- `chain_id` - Must match a chain_id from the chains table
- `label` - Descriptive name (e.g., "REWE_NORD", "LIDL_BERLIN")

**Example:**
```csv
region_id,chain_id,label
R001,C01,REWE_NORD
R002,C01,REWE_SUED
R003,C02,LIDL_BERLIN
```

**Common Mistakes:**
- ❌ Leaving `label` empty
- ❌ Using a `chain_id` that doesn't exist in chains table
- ❌ Using duplicate `region_id` values

**Tips:**
- Import chains first!
- Use descriptive labels that make sense (e.g., "REWE_HAMBURG" not just "R001")

---

### 3. Stores

**What it is:** Individual store locations.

**Required Fields:**
- `store_id` - Unique identifier (e.g., "S001", "S002")
- `chain_id` - Must match a chain_id from chains table
- `store_name` - Name of the store (e.g., "REWE Hannover Nord")
- `plz` - Postal code (e.g., "30165")
- `city` - City name (e.g., "Hannover")
- `street` - Street address (e.g., "Hauptstraße 123")

**Example:**
```csv
store_id,chain_id,store_name,plz,city,street,lat,lon
S001,C01,REWE Hannover Nord,30165,Hannover,Hauptstraße 123,,
S002,C02,Lidl Berlin Mitte,10115,Berlin,Friedrichstraße 100,,
```

**Optional Fields:**
- `lat` - Latitude (for mapping)
- `lon` - Longitude (for mapping)

**Common Mistakes:**
- ❌ Missing street address (it's required!)
- ❌ Using a `chain_id` that doesn't exist

**Tips:**
- Import chains first!
- Even if you don't have exact coordinates, include the street address

---

### 4. Store Region Map

**What it is:** Links stores to their advertising regions.

**Required Fields:**
- `store_id` - Must match a store_id from stores table
- `region_id` - Must match a region_id from ad_regions table

**Example:**
```csv
store_id,region_id
S001,R001
S002,R003
```

**Common Mistakes:**
- ❌ Using `store_id` or `region_id` that don't exist
- ❌ Missing one of the required fields

**Tips:**
- Import stores and ad_regions first!
- Each store can belong to multiple regions (multiple rows with same store_id)

---

### 5. Postal Codes

**What it is:** Links postal codes (PLZ) to regions.

**Required Fields:**
- `plz` - Postal code (e.g., "30165")
- `region_id` - Must match a region_id from ad_regions table
- `city` - City name (e.g., "Hannover")

**Example:**
```csv
plz,region_id,city
30165,R001,Hannover
30167,R001,Hannover
10115,R003,Berlin
```

**Common Mistakes:**
- ❌ Using a `region_id` that doesn't exist
- ❌ Leaving city empty

**Tips:**
- Import ad_regions first!
- Multiple postal codes can map to the same region

---

### 6. Ingredients

**What it is:** All ingredients used in recipes (e.g., tomatoes, pasta, chicken).

**Required Fields:**
- `ingredient_id` - Unique identifier (e.g., "I001", "I020")
- `name_canonical` - Standard name (e.g., "Rinderhackfleisch", "Eier")
- `unit_default` - Default unit (e.g., "kg", "g", "st") - must exist in lookups_units
- `price_baseline_per_unit` - Baseline price (e.g., 15.73 or 15,73)

**Example:**
```csv
ingredient_id,name_canonical,unit_default,price_baseline_per_unit,allergen_tags,notes
I001,Tomaten,kg,3.50,,
I002,Eier,st,0.25,ei,
I003,Rinderhackfleisch,kg,15.73,,
```

**Optional Fields:**
- `allergen_tags` - Comma-separated allergens (e.g., "ei,gluten")
- `notes` - Additional notes

**Common Mistakes:**
- ❌ Leaving `price_baseline_per_unit` empty (it's required!)
- ❌ Using a `unit_default` that doesn't exist in lookups_units
- ❌ Using invalid number format for price

**Tips:**
- Import lookups_units first (if you have it)!
- Prices can use either `.` or `,` as decimal separator (15.73 or 15,73)
- Use consistent ingredient_id format

---

### 7. Dishes

**What it is:** Recipes/meals (e.g., "Chili con Carne", "Spaghetti Carbonara").

**Required Fields:**
- `dish_id` - Unique identifier (e.g., "D001", "D115")
- `name` - Dish name (e.g., "Chili con Carne")
- `category` - Must exist in lookups_categories (e.g., "Hauptgericht", "Dessert")
- `is_quick` - TRUE or FALSE (quick to prepare?)
- `is_meal_prep` - TRUE or FALSE (good for meal prep?)

**Example:**
```csv
dish_id,name,category,is_quick,is_meal_prep,season,cuisine,notes
D001,Chili con Carne,Hauptgericht,TRUE,TRUE,,,
D002,Spaghetti Carbonara,Hauptgericht,FALSE,FALSE,,,
```

**Optional Fields:**
- `season` - Season preference (e.g., "Sommer", "Winter")
- `cuisine` - Cuisine type (e.g., "Italienisch", "Mexikanisch")
- `notes` - Additional notes

**Common Mistakes:**
- ❌ Using "yes"/"no" instead of "TRUE"/"FALSE" for boolean fields
- ❌ Using a `category` that doesn't exist in lookups_categories
- ❌ Leaving boolean fields empty (they're required!)

**Tips:**
- Import lookups_categories first (if you have it)!
- Boolean fields must be exactly "TRUE" or "FALSE" (case-sensitive)
- Use descriptive dish names

---

### 8. Dish Ingredients

**What it is:** Links dishes to their ingredients and specifies quantities.

**Required Fields:**
- `dish_id` - Must match a dish_id from dishes table
- `ingredient_id` - Must match an ingredient_id from ingredients table
- `qty` - Quantity (e.g., 400, 0.5, 250.5)
- `unit` - Unit (e.g., "g", "kg", "ml") - must exist in lookups_units
- `optional` - TRUE or FALSE (is this ingredient optional?)
- `role` - Role of ingredient (e.g., "main", "side", "seasoning")

**Example:**
```csv
dish_id,ingredient_id,qty,unit,optional,role
D001,I001,400,g,FALSE,main
D001,I002,2,st,FALSE,main
D001,I003,500,g,FALSE,main
D001,I004,1,TL,TRUE,seasoning
```

**Common Mistakes:**
- ❌ Using `dish_id` or `ingredient_id` that don't exist
- ❌ Leaving `role` empty (it's required!)
- ❌ Using a `unit` that doesn't exist in lookups_units
- ❌ Using "yes"/"no" instead of "TRUE"/"FALSE"

**Tips:**
- Import dishes and ingredients first!
- Quantities can use `.` or `,` as decimal separator
- Use meaningful roles (e.g., "main", "side", "garnish", "seasoning")

---

### 9. Offers

**What it is:** Current deals and prices for ingredients in specific regions.

**Required Fields:**
- `region_id` - Must match a region_id from ad_regions table
- `ingredient_id` - Must match an ingredient_id from ingredients table
- `price_total` - Total price (e.g., 12.49 or 12,49)
- `unit_base` - Base unit (e.g., "kg", "g") - must exist in lookups_units
- `source` - Source of the offer (e.g., "REWE Prospekt KW46")

**Example:**
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source,source_ref_id
R001,I077,12.49,5,kg,2025-11-10,2025-11-15,REWE Prospekt KW46,
R001,I020,3.99,500,g,2025-11-10,2025-11-15,Lidl Angebot,
```

**Optional Fields:**
- `pack_size` - Size of the package (defaults to 1.0 if empty)
- `valid_from` - Start date (YYYY-MM-DD format)
- `valid_to` - End date (YYYY-MM-DD format)
- `source_ref_id` - Reference ID from source

**Common Mistakes:**
- ❌ Leaving `source` empty (it's required!)
- ❌ Using `region_id` or `ingredient_id` that don't exist
- ❌ Using invalid date format (must be YYYY-MM-DD)
- ❌ Using a `unit_base` that doesn't exist in lookups_units

**Tips:**
- Import ad_regions and ingredients first!
- Always update `valid_from` and `valid_to` to current dates
- Use descriptive source names (e.g., "REWE Prospekt KW46" not just "REWE")
- Prices can use `.` or `,` as decimal separator

---

## Understanding Validation

### What Gets Validated?

The system checks:

1. **Required Fields** - All required fields must have values
2. **Data Types** - Numbers must be numbers, dates must be dates, etc.
3. **Foreign Keys** - Referenced IDs must exist in other tables
4. **Format** - Dates, booleans, and numbers must be in correct format
5. **Column Count** - Each row must have the right number of columns

### Reading Error Messages

When validation fails, you'll see messages like this:

```
Row 5: Invalid label: label cannot be empty or null. label is a required field.
Row Data:
  region_id: "R001"
  chain_id: "C11"
  label: "(empty)"
```

This tells you:
- **Row 5** - Which row has the problem (row 5 in your CSV, not counting the header)
- **Invalid label** - What field has the problem
- **label cannot be empty** - What the problem is
- **Row Data** - Shows all the values in that row so you can see the context

### Types of Errors

**1. Missing Required Field**
```
Row 3: Invalid chain_name: chain_name cannot be empty or null. chain_name is a required field.
```
**Fix:** Fill in the empty field

**2. Foreign Key Error**
```
Row 7: Chain ID "C99" not found in chains table. Make sure you've imported chains first.
```
**Fix:** Import the referenced table first, or fix the ID

**3. Invalid Format**
```
Row 2: Invalid date format for valid_from: "13-01-2025". Use format YYYY-MM-DD (e.g., 2025-01-13).
```
**Fix:** Change the date format

**4. Invalid Number**
```
Row 4: Invalid number for price_total: "abc". Use numbers only (e.g., 1.99 or 1,99).
```
**Fix:** Use a valid number

---

## Common Errors and How to Fix Them

### Error: "Foreign key constraint violation"

**What it means:** You're trying to reference data that doesn't exist yet.

**Example:**
```
Chain ID "C01" not found in chains table. Make sure you've imported chains first.
```

**How to fix:**
1. Check the import order - did you import the referenced table first?
2. Check that the ID exists in the other table
3. Verify the ID format matches exactly (e.g., "C01" not "c01" or "1")

### Error: "Invalid [field]: [field] cannot be empty or null"

**What it means:** A required field is empty.

**Example:**
```
Row 5: Invalid label: label cannot be empty or null. label is a required field.
```

**How to fix:**
1. Find the row mentioned in the error
2. Fill in the empty required field
3. Make sure there are no extra commas creating empty columns

### Error: "Wrong number of columns"

**What it means:** A row has too many or too few columns.

**Example:**
```
Row 3: Wrong number of columns: found 5, expected 3-3. Check for extra commas or missing values.
```

**How to fix:**
1. Count the columns in that row
2. Check for extra commas (e.g., `value1,value2,,value4` has an empty column)
3. Check for missing commas
4. Make sure all rows have the same number of columns as the header

### Error: "Invalid date format"

**What it means:** A date is not in the correct format.

**Example:**
```
Row 2: Invalid date format for valid_from: "13-01-2025". Use format YYYY-MM-DD (e.g., 2025-01-13).
```

**How to fix:**
1. Change dates to YYYY-MM-DD format
2. Use `2025-01-13` not `13-01-2025` or `01/13/2025`
3. Make sure dates are valid (not `2025-13-45`)

### Error: "Invalid number"

**What it means:** A number field contains non-numeric characters.

**Example:**
```
Row 4: Invalid number for price_total: "abc". Use numbers only (e.g., 1.99 or 1,99).
```

**How to fix:**
1. Remove any text or special characters
2. Use numbers only (e.g., `15.73` or `15,73`)
3. Don't include currency symbols (e.g., use `15.73` not `€15.73`)

### Error: "Unit not found"

**What it means:** A unit value doesn't exist in the lookups_units table.

**Example:**
```
Unit "kilogram" not found. Make sure you've imported units lookup first.
```

**How to fix:**
1. Import lookups_units first
2. Check that the unit value matches exactly (case-sensitive)
3. Use standard abbreviations (e.g., "kg" not "kilogram")

---

## Best Practices

### 1. Always Use Dry Run First

Before importing, always click "Dry Run" to check for errors. This saves time and prevents problems.

### 2. Import in Order

Follow the import order exactly. Skipping steps will cause errors.

### 3. Use Consistent Formats

- Use the same ID format throughout (e.g., always "I001" not sometimes "1")
- Use consistent date formats (YYYY-MM-DD)
- Use consistent boolean values (TRUE/FALSE, not yes/no)

### 4. Keep IDs Unique

Each ID should be unique within its table. Duplicates will cause problems.

### 5. Update Offer Dates

When importing offers, always update `valid_from` and `valid_to` to current dates. Old offers won't show up in searches.

### 6. Use Descriptive Names

Use clear, descriptive names for:
- Chain names (e.g., "REWE" not "R")
- Store names (e.g., "REWE Hannover Nord" not "Store 1")
- Region labels (e.g., "REWE_NORD" not "R1")

### 7. Check Your Data Before Importing

- Review your CSV file in a spreadsheet program first
- Look for empty required fields
- Verify IDs match between tables
- Check date formats

### 8. Save Your CSV Files

Keep copies of your CSV files so you can:
- Re-import if needed
- Track changes
- Share with team members

---

## Troubleshooting

### My Import Failed - What Do I Do?

1. **Read the error messages carefully** - They tell you exactly what's wrong
2. **Check the row number** - Find that row in your CSV file
3. **Look at the row data** - The error message shows all values in that row
4. **Fix the problem** - Usually it's a missing field or wrong format
5. **Try Dry Run again** - Keep fixing errors until validation passes

### Some Rows Imported, But Others Failed

This is normal! The system will:
- Import all valid rows
- Show you which rows failed
- Tell you why they failed

Fix the errors and import again - the system won't duplicate rows that already exist.

### I'm Getting Foreign Key Errors

**Check:**
1. Did you import the referenced table first? (e.g., import chains before stores)
2. Does the ID exist in the other table?
3. Is the ID format correct? (e.g., "C01" not "c01" or "1")

### My Dates Are Wrong

**Check:**
1. Format must be YYYY-MM-DD (e.g., `2025-01-13`)
2. Dates must be valid (not `2025-13-45`)
3. No slashes or dots (use dashes: `2025-01-13`)

### My Numbers Aren't Working

**Check:**
1. Use only numbers (no text or symbols)
2. Use `.` or `,` for decimals (e.g., `15.73` or `15,73`)
3. Don't include currency symbols
4. Don't include spaces

### Boolean Fields Are Causing Problems

**Remember:**
- Must be exactly `TRUE` or `FALSE` (all caps)
- Not `true`, `True`, `yes`, `no`, `1`, `0`, etc.
- Case-sensitive!

### I Still Have Problems

If you've tried everything and still have issues:

1. **Check the error messages** - They're very detailed
2. **Verify your CSV format** - Open it in Excel or Google Sheets to check
3. **Start with a small test file** - Import just a few rows to test
4. **Check the import order** - Make sure you're importing in the right sequence
5. **Review this guide** - Make sure you're following all the requirements

---

## Quick Reference Checklist

Before importing any CSV file, verify:

- [ ] File has a header row (first row with column names)
- [ ] All required fields are filled in every row
- [ ] All rows have the same number of columns
- [ ] Dates are in YYYY-MM-DD format
- [ ] Boolean fields are TRUE or FALSE (all caps)
- [ ] Numbers use `.` or `,` (not both)
- [ ] Referenced IDs exist in other tables
- [ ] Import order is correct
- [ ] Dry run passes successfully

---

## Summary

Importing CSV data into MealDeal is straightforward when you:

1. ✅ **Prepare your data** - Make sure all required fields are filled
2. ✅ **Follow the import order** - Import tables in the correct sequence
3. ✅ **Use Dry Run first** - Always validate before importing
4. ✅ **Read error messages** - They tell you exactly what to fix
5. ✅ **Be consistent** - Use the same formats throughout

Remember: The system is designed to help you catch errors early. Use the Dry Run feature, read the error messages carefully, and you'll have your data imported successfully in no time!

---

**Need Help?** If you're still having trouble, check the error messages - they're very detailed and will guide you to the solution. Most problems are simple fixes like missing required fields or wrong formats.

Good luck with your imports! 🚀


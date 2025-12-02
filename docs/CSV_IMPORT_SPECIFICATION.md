# CSV Import File Specification

Complete specification for CSV files used with the Admin Dashboard CSV Import feature.

## Table of Contents

1. [General Requirements](#general-requirements)
2. [File Format](#file-format)
3. [Supported Table Types](#supported-table-types)
4. [Detailed Specifications](#detailed-specifications)
5. [Import Order](#import-order)
6. [Validation Rules](#validation-rules)
7. [Common Errors](#common-errors)

---

## General Requirements

### File Format
- **Encoding**: UTF-8
- **Delimiter**: Comma (`,`)
- **Line Endings**: Unix (`\n`) or Windows (`\r\n`)
- **Quoting**: Use double quotes (`"`) for fields containing commas, newlines, or quotes
- **Header Row**: Required - first row must contain column names
- **Empty Values**: Leave blank or use `NULL` (case-insensitive)

### Data Types
- **Text**: Plain text, no special encoding required
- **Numbers**: Use dot (`.`) or comma (`,`) as decimal separator (both accepted)
- **Booleans**: `TRUE` or `FALSE` (case-insensitive, but uppercase recommended)
- **Dates**: `YYYY-MM-DD` format (e.g., `2025-01-13`)
- **Arrays**: Comma-separated values (e.g., `tk,gluten`)

---

## File Format

### CSV Structure
```csv
column1,column2,column3
value1,value2,value3
value1,value2,value3
```

### Special Characters
- **Commas in text**: Wrap in quotes: `"Tomaten (stückig, Dose)"`
- **Quotes in text**: Escape with double quotes: `"He said ""Hello"""`
- **Newlines in text**: Wrap in quotes

---

## Supported Table Types

The following table types can be imported via CSV:

1. `lookups_categories` - Dish categories
2. `lookups_units` - Measurement units
3. `chains` - Supermarket chains
4. `ad_regions` - Advertising regions
5. `stores` - Store locations
6. `store_region_map` - Store to region mapping
7. `ingredients` - Ingredient master data
8. `dishes` - Dish master data
9. `dish_ingredients` - Dish to ingredient relationships
10. `offers` - Current supermarket offers

---

## Detailed Specifications

### 1. lookups_categories

**Purpose**: Dish categories (Hauptgericht, Dessert, etc.)

**Required Columns**:
- `category` (TEXT, PRIMARY KEY) - Category name

**Example**:
```csv
category
Hauptgericht
Dessert
Snack
```

**Validation**:
- `category` must be unique
- Cannot be empty

**Conflict Resolution**: Updates existing if category exists

---

### 2. lookups_units

**Purpose**: Measurement units (kg, l, g, ml, etc.)

**Required Columns**:
- `unit` (TEXT, PRIMARY KEY) - Unit abbreviation
- `description` (TEXT, optional) - Unit description

**Example**:
```csv
unit,description
kg,Kilogram
l,Liter
g,Gram
ml,Milliliter
Stück,Piece
```

**Validation**:
- `unit` must be unique
- Cannot be empty

**Conflict Resolution**: Updates existing if unit exists

---

### 3. chains

**Purpose**: Supermarket chains (REWE, Lidl, ALDI, etc.)

**Required Columns**:
- `chain_id` (INTEGER, PRIMARY KEY) - Unique chain identifier
- `chain_name` (TEXT) - Chain name

**Example**:
```csv
chain_id,chain_name
10,REWE
11,Lidl
12,ALDI
```

**Validation**:
- `chain_id` must be integer
- `chain_name` cannot be empty

**Conflict Resolution**: Updates `chain_name` if `chain_id` exists

---

### 4. ad_regions

**Purpose**: Advertising regions for chains

**Required Columns**:
- `region_id` (INTEGER, PRIMARY KEY) - Unique region identifier
- `chain_id` (INTEGER) - Foreign key to `chains.chain_id`
- `label` (TEXT) - Region label (e.g., `REWE_H_NORD`)

**Example**:
```csv
region_id,chain_id,label
500,10,REWE_H_NORD
501,10,REWE_H_SUED
510,11,LIDL_H_WEST
```

**Validation**:
- `region_id` must be integer
- `chain_id` must exist in `chains` table
- `label` cannot be empty

**Conflict Resolution**: Updates `chain_id` and `label` if `region_id` exists

---

### 5. stores

**Purpose**: Store locations

**Required Columns**:
- `store_id` (INTEGER, PRIMARY KEY) - Unique store identifier
- `chain_id` (INTEGER) - Foreign key to `chains.chain_id`
- `store_name` (TEXT) - Store name
- `plz` (TEXT, optional) - Postal code
- `city` (TEXT, optional) - City name
- `street` (TEXT, optional) - Street address
- `lat` (DECIMAL, optional) - Latitude
- `lon` (DECIMAL, optional) - Longitude

**Example**:
```csv
store_id,chain_id,store_name,plz,city,street,lat,lon
1000,10,REWE Hannover Nord,30165,Hannover,,,
1001,10,REWE Hannover Südstadt,30171,Hannover,,,
```

**Validation**:
- `store_id` must be integer
- `chain_id` must exist in `chains` table
- `store_name` cannot be empty

**Conflict Resolution**: Updates all fields if `store_id` exists

---

### 6. store_region_map

**Purpose**: Maps stores to advertising regions

**Required Columns**:
- `store_id` (INTEGER) - Foreign key to `stores.store_id`
- `region_id` (INTEGER) - Foreign key to `ad_regions.region_id`

**Example**:
```csv
store_id,region_id
1000,500
1001,501
```

**Validation**:
- `store_id` must exist in `stores` table
- `region_id` must exist in `ad_regions` table
- Composite primary key: (`store_id`, `region_id`)

**Conflict Resolution**: Skips if combination exists

---

### 7. ingredients

**Purpose**: Ingredient master data with baseline prices

**Required Columns**:
- `ingredient_id` (TEXT, PRIMARY KEY) - Unique ingredient ID (e.g., `I001`, `I020`)
- `name_canonical` (TEXT) - Ingredient name
- `unit_default` (TEXT) - Default unit (must exist in `lookups_units`)
- `price_baseline_per_unit` (DECIMAL, optional) - Baseline price per unit
- `allergen_tags` (TEXT[], optional) - Comma-separated allergen tags
- `notes` (TEXT, optional) - Additional notes

**Example**:
```csv
ingredient_id,name_canonical,unit_default,price_baseline_per_unit,allergen_tags,notes
I020,Rinderhackfleisch,kg,15.73,,
I003,Eier,st,1.99,,
I045,Brokkoli,kg,2.39,tk,
```

**Validation**:
- `ingredient_id` must be unique
- `name_canonical` cannot be empty
- `unit_default` must exist in `lookups_units` table
- `price_baseline_per_unit` must be numeric (can be 0 or empty)
- `allergen_tags` format: comma-separated (e.g., `tk,gluten`)

**Data Type Conversions**:
- `price_baseline_per_unit`: Accepts both `.` and `,` as decimal separator
- `allergen_tags`: Comma-separated string converted to array

**Conflict Resolution**: Updates all fields if `ingredient_id` exists

---

### 8. dishes

**Purpose**: Dish master data

**Required Columns**:
- `dish_id` (TEXT, PRIMARY KEY) - Unique dish ID (e.g., `D001`, `D115`)
- `name` (TEXT) - Dish name
- `category` (TEXT) - Category (must exist in `lookups_categories`)
- `is_quick` (BOOLEAN, optional) - Quick meal flag
- `is_meal_prep` (BOOLEAN, optional) - Meal prep flag
- `season` (TEXT, optional) - Season
- `cuisine` (TEXT, optional) - Cuisine type
- `notes` (TEXT, optional) - Additional notes

**Example**:
```csv
dish_id,name,category,is_quick,is_meal_prep,season,cuisine,notes
D115,Chili con Carne,Hauptgericht,TRUE,TRUE,,,
D116,Carbonara (klassisch),Hauptgericht,TRUE,FALSE,,,
```

**Validation**:
- `dish_id` must be unique
- `name` cannot be empty
- `category` must exist in `lookups_categories` table
- `is_quick` and `is_meal_prep`: `TRUE` or `FALSE` (case-insensitive)

**Boolean Format**:
- Accepts: `TRUE`, `true`, `FALSE`, `false`
- Recommended: `TRUE` or `FALSE` (uppercase)

**Conflict Resolution**: Updates all fields if `dish_id` exists

---

### 9. dish_ingredients

**Purpose**: Links dishes to ingredients with quantities

**Required Columns**:
- `dish_id` (TEXT) - Foreign key to `dishes.dish_id`
- `ingredient_id` (TEXT) - Foreign key to `ingredients.ingredient_id`
- `qty` (DECIMAL) - Quantity
- `unit` (TEXT) - Unit (must exist in `lookups_units`)
- `optional` (BOOLEAN, optional) - Whether ingredient is optional
- `role` (TEXT, optional) - Role (e.g., `main`, `side`)

**Example**:
```csv
dish_id,ingredient_id,qty,unit,optional,role
D115,I020,400,g,FALSE,main
D115,I022,400,g,FALSE,main
D115,I023,1,Stück,FALSE,main
D115,I195,300,g,TRUE,side
```

**Validation**:
- `dish_id` must exist in `dishes` table
- `ingredient_id` must exist in `ingredients` table
- `qty` must be numeric (accepts `.` or `,` as decimal separator)
- `unit` must exist in `lookups_units` table
- `optional`: `TRUE` or `FALSE` (default: `FALSE`)
- Composite primary key: (`dish_id`, `ingredient_id`)

**Data Type Conversions**:
- `qty`: Accepts both `.` and `,` as decimal separator (e.g., `0.5` or `0,5`)
- `optional`: `TRUE` or `FALSE` (case-insensitive)

**Conflict Resolution**: Skips if combination exists

---

### 10. offers

**Purpose**: Current supermarket offers

**Required Columns**:
- `region_id` (INTEGER) - Foreign key to `ad_regions.region_id`
- `ingredient_id` (TEXT) - Foreign key to `ingredients.ingredient_id`
- `price_total` (DECIMAL) - Total price for the pack
- `pack_size` (DECIMAL) - Pack size
- `unit_base` (TEXT) - Base unit (must exist in `lookups_units`)
- `valid_from` (DATE) - Offer start date (YYYY-MM-DD)
- `valid_to` (DATE) - Offer end date (YYYY-MM-DD)
- `source` (TEXT, optional) - Source (e.g., "REWE Prospekt")
- `source_ref_id` (TEXT, optional) - Source reference ID

**Example**:
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source,source_ref_id
500,I051,0.99,0.5,kg,2025-01-13,2025-01-19,REWE Prospekt,rewe_spaghetti_500g
500,I020,6.99,1.0,kg,2025-01-13,2025-01-19,REWE Prospekt,rewe_hack_1kg
```

**Validation**:
- `region_id` must be integer and exist in `ad_regions` table
- `ingredient_id`:
  - Can be numeric (e.g., `1`, `2`) - automatically converted to `I001`, `I002`
  - Or text format (e.g., `I051`) - used as-is
- `price_total` must be numeric (accepts `.` or `,`)
- `pack_size` must be numeric (accepts `.` or `,`)
- `unit_base` must exist in `lookups_units` table
- `valid_from` and `valid_to` must be valid dates in `YYYY-MM-DD` format
- `valid_from` should be <= `valid_to`

**Special Features**:
- **Auto-generated `offer_hash`**: Automatically generated for deduplication
- **Ingredient ID conversion**: Numeric IDs (e.g., `1`) converted to text format (`I001`)

**Conflict Resolution**: Skips if `offer_hash` already exists

---

## Import Order

Import files in this exact order to avoid foreign key constraint errors:

### Phase 1: Lookup Tables (No Dependencies)
1. ✅ `lookups_categories`
2. ✅ `lookups_units`

### Phase 2: Chains & Regions
3. ✅ `chains`
4. ✅ `ad_regions` (depends on `chains`)
5. ✅ `stores` (depends on `chains`)
6. ✅ `store_region_map` (depends on `stores` and `ad_regions`)

### Phase 3: Core Data
7. ✅ `ingredients` (depends on `lookups_units`)
8. ✅ `dishes` (depends on `lookups_categories`)
9. ✅ `dish_ingredients` (depends on `dishes` and `ingredients`)

### Phase 4: Offers
10. ✅ `offers` (depends on `ad_regions`, `ingredients`, `lookups_units`)

---

## Validation Rules

### General Rules
1. **Header Row Required**: First row must contain column names
2. **Column Count**: Each row must have the same number of columns as header
3. **Empty Values**: Can be blank or `NULL` (case-insensitive)
4. **Primary Keys**: Must be unique within the file

### Type-Specific Rules

#### Numbers
- Accepts both `.` and `,` as decimal separator
- Examples: `3.75`, `3,75` (both valid)
- Empty values become `NULL`

#### Booleans
- Accepts: `TRUE`, `true`, `FALSE`, `false`
- Recommended: `TRUE` or `FALSE` (uppercase)
- Empty values become `FALSE` (for optional fields)

#### Dates
- Format: `YYYY-MM-DD` (e.g., `2025-01-13`)
- Must be valid dates
- `valid_from` should be <= `valid_to`

#### Arrays (allergen_tags)
- Format: Comma-separated values
- Example: `tk,gluten`
- Empty values become `NULL`

#### Foreign Keys
- Referenced IDs must exist in parent tables
- Import in correct order to satisfy dependencies

---

## Common Errors

### Error: "Row has X columns, expected Y"
**Cause**: Row has different number of columns than header
**Fix**: Ensure all rows have the same number of columns as header

### Error: "Invalid region_id: X"
**Cause**: `region_id` is not a valid integer
**Fix**: Use integer values (e.g., `500`, not `500.0` or `"500"`)

### Error: "Invalid qty: X"
**Cause**: `qty` is not a valid number
**Fix**: Use numeric values with `.` or `,` as decimal separator

### Error: "Foreign key constraint violation"
**Cause**: Referenced ID doesn't exist in parent table
**Fix**: 
- Import in correct order (see Import Order section)
- Ensure referenced IDs exist before importing dependent data

### Error: "new row violates row-level security policy"
**Cause**: RLS policy blocking insert
**Fix**: Edge function uses service role key, should not occur. If it does, check RLS policies.

### Error: "Could not choose the best candidate function"
**Cause**: Function overloading conflict
**Fix**: Run migration `009_fix_function_overload.sql` to resolve

### Offers Not Showing
**Causes**:
- Dates are in the past (`valid_to < CURRENT_DATE`)
- Region ID doesn't match user's PLZ
- Ingredient ID format mismatch

**Fix**:
- Update `valid_from` and `valid_to` to current week
- Verify PLZ maps to correct `region_id`
- Check ingredient IDs match between offers and ingredients

---

## Examples

### Complete Example: Ingredients
```csv
ingredient_id,name_canonical,unit_default,price_baseline_per_unit,allergen_tags,notes
I020,Rinderhackfleisch,kg,15.73,,
I003,Eier,st,1.99,,
I045,Brokkoli,kg,2.39,tk,
I022,"Tomaten (stückig, Dose)",kg,1.48,,
```

### Complete Example: Dishes
```csv
dish_id,name,category,is_quick,is_meal_prep,season,cuisine,notes
D115,Chili con Carne,Hauptgericht,TRUE,TRUE,,,
D116,Carbonara (klassisch),Hauptgericht,TRUE,FALSE,,,
```

### Complete Example: Dish Ingredients
```csv
dish_id,ingredient_id,qty,unit,optional,role
D115,I020,400,g,FALSE,main
D115,I022,400,g,FALSE,main
D115,I023,1,Stück,FALSE,main
D115,I195,300,g,TRUE,side
```

### Complete Example: Offers
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source,source_ref_id
500,I051,0.99,0.5,kg,2025-01-13,2025-01-19,REWE Prospekt,rewe_spaghetti_500g
500,I020,6.99,1.0,kg,2025-01-13,2025-01-19,REWE Prospekt,rewe_hack_1kg
```

---

## Best Practices

1. **Always use Dry Run first**: Validate data before importing
2. **Check foreign keys**: Ensure referenced IDs exist
3. **Update offer dates**: Keep `valid_from` and `valid_to` current
4. **Use consistent IDs**: Stick to one format (e.g., `I001` not `1`)
5. **Validate data types**: Ensure numbers are numeric, booleans are TRUE/FALSE
6. **Handle special characters**: Quote fields with commas or quotes
7. **Import in order**: Follow the import order to avoid foreign key errors

---

## Quick Reference

| Table | Primary Key | Required Fields | Foreign Keys |
|-------|-------------|----------------|--------------|
| `lookups_categories` | `category` | `category` | None |
| `lookups_units` | `unit` | `unit` | None |
| `chains` | `chain_id` | `chain_id`, `chain_name` | None |
| `ad_regions` | `region_id` | `region_id`, `chain_id`, `label` | `chain_id` → `chains` |
| `stores` | `store_id` | `store_id`, `chain_id`, `store_name` | `chain_id` → `chains` |
| `store_region_map` | `(store_id, region_id)` | `store_id`, `region_id` | `store_id` → `stores`, `region_id` → `ad_regions` |
| `ingredients` | `ingredient_id` | `ingredient_id`, `name_canonical`, `unit_default` | `unit_default` → `lookups_units` |
| `dishes` | `dish_id` | `dish_id`, `name`, `category` | `category` → `lookups_categories` |
| `dish_ingredients` | `(dish_id, ingredient_id)` | `dish_id`, `ingredient_id`, `qty`, `unit` | `dish_id` → `dishes`, `ingredient_id` → `ingredients`, `unit` → `lookups_units` |
| `offers` | `offer_hash` (auto) | `region_id`, `ingredient_id`, `price_total`, `pack_size`, `unit_base`, `valid_from`, `valid_to` | `region_id` → `ad_regions`, `ingredient_id` → `ingredients`, `unit_base` → `lookups_units` |

---

## Support

For issues or questions:
1. Check validation errors in dry run results
2. Verify import order
3. Check foreign key dependencies
4. Review browser console for detailed error messages





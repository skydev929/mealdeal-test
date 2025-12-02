# CSV Import Quick Reference Card

Quick reference for CSV file formats and requirements.

## Import Order (Critical!)

1. `lookups_categories` → 2. `lookups_units` → 3. `chains` → 4. `ad_regions` → 5. `stores` → 6. `store_region_map` → 7. `ingredients` → 8. `dishes` → 9. `dish_ingredients` → 10. `offers`

## File Format

- **Encoding**: UTF-8
- **Delimiter**: Comma (`,`)
- **Header Row**: Required (first row)
- **Quoting**: Use `"` for fields with commas
- **Empty Values**: Leave blank

## Column Specifications

### lookups_categories
```csv
category
Hauptgericht
Dessert
```

### lookups_units
```csv
unit,description
kg,Kilogram
l,Liter
```

### chains
```csv
chain_id,chain_name
10,REWE
11,Lidl
```

### ad_regions
```csv
region_id,chain_id,label
500,10,REWE_H_NORD
```

### stores
```csv
store_id,chain_id,store_name,plz,city,street,lat,lon
1000,10,REWE Hannover Nord,30165,Hannover,,,
```

### store_region_map
```csv
store_id,region_id
1000,500
```

### ingredients
```csv
ingredient_id,name_canonical,unit_default,price_baseline_per_unit,allergen_tags,notes
I020,Rinderhackfleisch,kg,15.73,,
I003,Eier,st,1.99,,
```
- `ingredient_id`: Text format (e.g., `I001`, `I020`)
- `price_baseline_per_unit`: Number (`.` or `,` accepted)
- `allergen_tags`: Comma-separated (e.g., `tk,gluten`)

### dishes
```csv
dish_id,name,category,is_quick,is_meal_prep,season,cuisine,notes
D115,Chili con Carne,Hauptgericht,TRUE,TRUE,,,
```
- `is_quick`, `is_meal_prep`: `TRUE` or `FALSE`
- `category`: Must exist in `lookups_categories`

### dish_ingredients
```csv
dish_id,ingredient_id,qty,unit,optional,role
D115,I020,400,g,FALSE,main
```
- `qty`: Number (`.` or `,` accepted, e.g., `0.5` or `0,5`)
- `optional`: `TRUE` or `FALSE`
- `unit`: Must exist in `lookups_units`

### offers
```csv
region_id,ingredient_id,price_total,pack_size,unit_base,valid_from,valid_to,source,source_ref_id
500,I051,0.99,0.5,kg,2025-01-13,2025-01-19,REWE Prospekt,rewe_spaghetti_500g
```
- `region_id`: Integer
- `ingredient_id`: Can be numeric (`1`) or text (`I001`) - auto-converted
- `price_total`, `pack_size`: Numbers (`.` or `,` accepted)
- `valid_from`, `valid_to`: Date format `YYYY-MM-DD`
- **⚠️ Update dates to current week!**

## Data Types

| Type | Format | Examples |
|------|--------|----------|
| **Text** | Plain text | `Spaghetti`, `"Tomaten (stückig, Dose)"` |
| **Integer** | Whole number | `500`, `10` |
| **Decimal** | Number with `.` or `,` | `15.73`, `15,73` |
| **Boolean** | `TRUE` or `FALSE` | `TRUE`, `FALSE` |
| **Date** | `YYYY-MM-DD` | `2025-01-13` |
| **Array** | Comma-separated | `tk,gluten` |

## Common Mistakes

❌ **Wrong**: Missing header row
✅ **Right**: First row contains column names

❌ **Wrong**: `is_quick: yes`
✅ **Right**: `is_quick: TRUE`

❌ **Wrong**: `price: 15,73` (with space)
✅ **Right**: `price: 15.73` or `15,73`

❌ **Wrong**: `valid_from: 13-01-2025`
✅ **Right**: `valid_from: 2025-01-13`

❌ **Wrong**: Importing `offers` before `ingredients`
✅ **Right**: Import `ingredients` first, then `offers`

## Validation Checklist

Before importing, verify:
- [ ] Header row matches expected columns
- [ ] All rows have same number of columns
- [ ] Foreign keys exist (IDs referenced in other tables)
- [ ] Dates are in `YYYY-MM-DD` format
- [ ] Booleans are `TRUE` or `FALSE`
- [ ] Numbers use `.` or `,` (not both in same file)
- [ ] Import order is correct

## Quick Tips

1. **Always use Dry Run first** - catches errors before import
2. **Check foreign keys** - referenced IDs must exist
3. **Update offer dates** - keep `valid_from` and `valid_to` current
4. **Use consistent IDs** - stick to one format (e.g., `I001` not `1`)

---

See `docs/CSV_IMPORT_SPECIFICATION.md` for complete documentation.





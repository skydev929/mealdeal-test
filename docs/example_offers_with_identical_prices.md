# Example: Multiple Offers with Identical Prices

This document shows example data for the scenario where multiple offers from different chains have identical prices for the same ingredient.

## Scenario
An ingredient "Tomaten" (Tomatoes) has 3 offers from different chains, all with the same price:

## 1. Database Query Results (from `offers` table)

```javascript
// Raw offers data fetched from database
const offersData = [
  {
    offer_id: 101,
    ingredient_id: "tomaten",
    chain_id: "aldi",
    price_total: 2.99,
    pack_size: 1.0,
    unit_base: "kg",
    source: "aldi_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "ALDI-12345",
    region_id: "region_1"
  },
  {
    offer_id: 102,
    ingredient_id: "tomaten",
    chain_id: "lidl",
    price_total: 2.99,  // Same price as Aldi
    pack_size: 1.0,
    unit_base: "kg",
    source: "lidl_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "LIDL-67890",
    region_id: "region_1"
  },
  {
    offer_id: 103,
    ingredient_id: "tomaten",
    chain_id: "rewe",
    price_total: 2.99,  // Same price as Aldi and Lidl
    pack_size: 1.0,
    unit_base: "kg",
    source: "rewe_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "REWE-11111",
    region_id: "region_1"
  },
  {
    offer_id: 104,
    ingredient_id: "tomaten",
    chain_id: "edeka",
    price_total: 3.49,  // Different (higher) price
    pack_size: 1.0,
    unit_base: "kg",
    source: "edeka_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "EDEKA-22222",
    region_id: "region_1"
  }
];
```

## 2. After Adding Chain Names

```javascript
// After fetching chain names and mapping them
const allOffersByIngredient = new Map([
  ["tomaten", [
    {
      offer_id: 101,
      ingredient_id: "tomaten",
      chain_id: "aldi",
      chain_name: "Aldi",  // Added from chains table
      price_total: 2.99,
      pack_size: 1.0,
      unit_base: "kg",
      source: "aldi_de",
      valid_from: "2025-01-01",
      valid_to: "2025-01-31",
      source_ref_id: "ALDI-12345"
    },
    {
      offer_id: 102,
      ingredient_id: "tomaten",
      chain_id: "lidl",
      chain_name: "Lidl",  // Added from chains table
      price_total: 2.99,
      pack_size: 1.0,
      unit_base: "kg",
      source: "lidl_de",
      valid_from: "2025-01-01",
      valid_to: "2025-01-31",
      source_ref_id: "LIDL-67890"
    },
    {
      offer_id: 103,
      ingredient_id: "tomaten",
      chain_id: "rewe",
      chain_name: "Rewe",  // Added from chains table
      price_total: 2.99,
      pack_size: 1.0,
      unit_base: "kg",
      source: "rewe_de",
      valid_from: "2025-01-01",
      valid_to: "2025-01-31",
      source_ref_id: "REWE-11111"
    },
    {
      offer_id: 104,
      ingredient_id: "tomaten",
      chain_id: "edeka",
      chain_name: "Edeka",  // Added from chains table
      price_total: 3.49,
      pack_size: 1.0,
      unit_base: "kg",
      source: "edeka_de",
      valid_from: "2025-01-01",
      valid_to: "2025-01-31",
      source_ref_id: "EDEKA-22222"
    }
  ]]
]);
```

## 3. After Sorting (No Chain Selected)

With the improved sorting logic, when no chain is selected, offers are sorted by:
1. `price_total` (ascending)
2. `chain_name` (alphabetically) when prices are equal
3. `offer_id` when both price and chain_name are equal

```javascript
const sortedOffers = [
  {
    offer_id: 101,
    chain_id: "aldi",
    chain_name: "Aldi",
    price_total: 2.99,  // Lowest price
    price_per_unit: 2.99  // Will be calculated: 2.99 / 1.0
  },
  {
    offer_id: 102,
    chain_id: "lidl",
    chain_name: "Lidl",
    price_total: 2.99,  // Same price as Aldi
    price_per_unit: 2.99
  },
  {
    offer_id: 103,
    chain_id: "rewe",
    chain_name: "Rewe",
    price_total: 2.99,  // Same price as Aldi and Lidl
    price_per_unit: 2.99
  },
  {
    offer_id: 104,
    chain_id: "edeka",
    chain_name: "Edeka",
    price_total: 3.49,  // Higher price
    price_per_unit: 3.49
  }
];
// All three offers with price 2.99 are included and sorted alphabetically by chain name
```

## 4. After Processing (Final Output)

```javascript
const processedOffers = [
  {
    offer_id: 101,
    price_total: 2.99,
    pack_size: 1.0,
    unit_base: "kg",
    source: "aldi_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "ALDI-12345",
    chain_id: "aldi",
    chain_name: "Aldi",
    price_per_unit: 2.99,
    is_lowest_price: true  // Marked as best price (lowest overall)
  },
  {
    offer_id: 102,
    price_total: 2.99,
    pack_size: 1.0,
    unit_base: "kg",
    source: "lidl_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "LIDL-67890",
    chain_id: "lidl",
    chain_name: "Lidl",
    price_per_unit: 2.99,
    is_lowest_price: false  // Not marked as best (only first lowest is marked)
  },
  {
    offer_id: 103,
    price_total: 2.99,
    pack_size: 1.0,
    unit_base: "kg",
    source: "rewe_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "REWE-11111",
    chain_id: "rewe",
    chain_name: "Rewe",
    price_per_unit: 2.99,
    is_lowest_price: false  // Not marked as best (only first lowest is marked)
  },
  {
    offer_id: 104,
    price_total: 3.49,
    pack_size: 1.0,
    unit_base: "kg",
    source: "edeka_de",
    valid_from: "2025-01-01",
    valid_to: "2025-01-31",
    source_ref_id: "EDEKA-22222",
    chain_id: "edeka",
    chain_name: "Edeka",
    price_per_unit: 3.49,
    is_lowest_price: false
  }
];
```

## 5. Final DishIngredient Object

```javascript
const dishIngredient = {
  dish_id: "pasta_with_tomatoes",
  ingredient_id: "tomaten",
  ingredient_name: "Tomaten",
  unit_default: "kg",
  price_baseline_per_unit: 3.99,  // Base price (no offer)
  offer_price_per_unit: 2.99,      // Lowest offer price (from offer_id: 101)
  savings_per_unit: 1.00,          // 3.99 - 2.99 = 1.00
  has_offer: true,
  all_offers: processedOffers  // All 4 offers included above
};
```

## 6. UI Display (in DishDetail page)

The UI will display all offers like this:

```
Available Offers (4):

┌─────────────────────────────────────┐
│ Aldi                                │ €2.99/kg
│ Per kg: €2.99 (was €3.99/kg)       │ [Highlighted in green - Best Price]
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Lidl                                │ €2.99/kg
│ Per kg: €2.99 (was €3.99/kg)       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Rewe                                │ €2.99/kg
│ Per kg: €2.99 (was €3.99/kg)       │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Edeka                               │ €3.49/kg
│ Per kg: €3.49 (was €3.99/kg)       │
└─────────────────────────────────────┘
```

**Key Points:**
- All 3 offers with identical price (€2.99) are displayed
- They are sorted alphabetically by chain name (Aldi, Lidl, Rewe)
- The first one (Aldi) is marked as "best price" and highlighted
- The higher-priced offer (Edeka €3.49) is shown last

## 7. With Chain Filter Selected (e.g., "Lidl")

If user selects "Lidl" as the chain filter:

```javascript
// Sorting with chainId = "lidl"
const sortedOffers = [
  {
    offer_id: 102,
    chain_id: "lidl",
    chain_name: "Lidl",
    price_total: 2.99,
    is_lowest_price: true  // Marked as best because it's from selected chain
  },
  {
    offer_id: 101,
    chain_id: "aldi",
    chain_name: "Aldi",
    price_total: 2.99,
    is_lowest_price: false
  },
  {
    offer_id: 103,
    chain_id: "rewe",
    chain_name: "Rewe",
    price_total: 2.99,
    is_lowest_price: false
  },
  {
    offer_id: 104,
    chain_id: "edeka",
    chain_name: "Edeka",
    price_total: 3.49,
    is_lowest_price: false
  }
];
// Lidl offer appears first (selected chain), then others sorted by price/name
```

## Edge Case: Same Price AND Same Chain Name

If somehow two offers have the same price AND same chain_name, they will be sorted by `offer_id`:

```javascript
// Hypothetical case (shouldn't happen in practice)
{
  offer_id: 105,  // Lower ID comes first
  chain_name: "Aldi",
  price_total: 2.99
},
{
  offer_id: 106,  // Higher ID comes second
  chain_name: "Aldi",
  price_total: 2.99
}
```

This ensures a completely stable sort where every offer is guaranteed a consistent position.


# Product Variation Grouping - Implementation Guide

## Overview
This implementation allows you to group product variations (like "Hot Wings 3pcs", "Hot Wings 5pcs", "Hot Wings 7pcs") into a single card in the menu. When users tap on the grouped card, a bottom sheet appears showing all available variations.

## Files Created/Modified

### New Files:
1. **`lib/models/product_group.dart`** - Model for grouped products
2. **`lib/widget/variation_selector_sheet.dart`** - Bottom sheet UI for selecting variations
3. **`PRODUCT_VARIATION_GUIDE.md`** - This guide

### Modified Files:
1. **`lib/services/menu_service.dart`** - Added grouping logic and configuration
2. **`lib/pages/homenew.dart`** - Updated UI to display grouped products

## How to Use

### Step 1: Find Product UUIDs

First, you need to find the UUIDs of the products you want to group. You can:

1. **Check the API response** - Look at your menu API response
2. **Check the logs** - Run the app and look for product logs in the console
3. **Use the existing product data** - Each product has a `uuid` field

Example product structure:
```dart
Product(
  id: 123,
  uuid: "550e8400-e29b-41d4-a716-446655440000",  // This is what you need
  name: "Hot Wings 3pcs",
  price: 15000,
  ...
)
```

### Step 2: Configure Product Groups

Open `lib/services/menu_service.dart` and find the `productVariationGroups` map (around line 46):

```dart
final Map<String, List<String>> productVariationGroups = {
  // TODO: Add your product variation groups here
  // Example:
  // 'Hot Wings': ['uuid-3pcs', 'uuid-5pcs', 'uuid-7pcs'],
  // 'Combo M': ['uuid-combo-1', 'uuid-combo-2'],
};
```

Add your product groups like this:

```dart
final Map<String, List<String>> productVariationGroups = {
  'Hot Wings': [
    '550e8400-e29b-41d4-a716-446655440000',  // Hot Wings 3pcs
    '550e8400-e29b-41d4-a716-446655440001',  // Hot Wings 5pcs
    '550e8400-e29b-41d4-a716-446655440002',  // Hot Wings 7pcs
  ],
  'Combo M': [
    '660e8400-e29b-41d4-a716-446655440000',  // Combo M 1
    '660e8400-e29b-41d4-a716-446655440001',  // Combo M 2
  ],
  'Pizza': [
    '770e8400-e29b-41d4-a716-446655440000',  // Pizza Small
    '770e8400-e29b-41d4-a716-446655440001',  // Pizza Medium
    '770e8400-e29b-41d4-a716-446655440002',  // Pizza Large
  ],
};
```

### Step 3: Test the Implementation

1. **Run the app**: `flutter run`
2. **Navigate to the home page**
3. **Look for grouped products** - They will have:
   - A badge showing the number of variations (e.g., "3")
   - An arrow icon (→) on the right
   - Price range (e.g., "15 000 - 25 000 UZS")
4. **Tap on a grouped product** - A bottom sheet will appear
5. **Select a variation** - It will open the details page

## Features

### Visual Indicators for Grouped Products:
- **Badge** on product image showing number of variations
- **Arrow icon** (→) indicating more options available
- **Price range** instead of single price
- **Group name** as the main title

### Variation Selector Bottom Sheet:
- Shows all variations with images
- Displays individual prices
- Shows descriptions for each variation
- Taps on variation opens the details page

### Behavior:
- **Grouped products** appear as single cards in the menu
- **Ungrouped products** appear normally
- **Products with only 1 variation** are NOT grouped (appear as regular products)
- **Groups are sorted by price** (cheapest variation shown first)
- **All existing functionality preserved** (cart, modifiers, ordering)

## Important Notes

### UUID Requirements:
- Each product MUST have a unique UUID
- UUIDs should never change (they're used for ordering)
- Use the exact UUID strings from your API

### Grouping Rules:
- Minimum 2 products required to create a group
- Products must be in the same category
- Products with 0 or invalid UUIDs are skipped
- Groups are created after product sorting

### Display Order:
1. Product groups appear first
2. Ungrouped products appear after groups
3. Within groups, variations are sorted by price (ascending)

## Troubleshooting

### Products not grouping?
1. Check that UUIDs are correct (exact match)
2. Verify products exist in the menu
3. Check console logs for warnings:
   - "Group X only has 1 product, skipping grouping"
   - "Group X has no matching products"

### Group not showing?
1. Ensure at least 2 products with matching UUIDs exist
2. Check that products are in the same category
3. Look for logs: "Created group X with Y variations"

### Wrong products grouped?
1. Verify UUID strings are correct
2. Check for typos in the configuration map
3. Ensure UUIDs are unique across products

## Console Logs

When the app runs, you'll see logs like:
```
MenuService: Starting product variation grouping
MenuService: Created group "Hot Wings" with 3 variations
MenuService: Created 5 product groups
MenuService: Grouped 15 products
```

## Example Configuration

Here's a complete example for a restaurant menu:

```dart
final Map<String, List<String>> productVariationGroups = {
  // Chicken variations
  'Hot Wings': [
    'uuid-hot-wings-3pcs',
    'uuid-hot-wings-5pcs',
    'uuid-hot-wings-7pcs',
  ],
  'Chicken Strips': [
    'uuid-strips-3pcs',
    'uuid-strips-5pcs',
  ],
  
  // Combo variations
  'Combo M': [
    'uuid-combo-m-1',
    'uuid-combo-m-2',
    'uuid-combo-m-3',
  ],
  
  // Pizza sizes
  'Margherita Pizza': [
    'uuid-margherita-small',
    'uuid-margherita-medium',
    'uuid-margherita-large',
  ],
  
  // Drinks
  'Coca Cola': [
    'uuid-coke-250ml',
    'uuid-coke-500ml',
    'uuid-coke-1l',
  ],
};
```

## Future Enhancements

Possible improvements:
1. Auto-detect variations by name patterns
2. Backend configuration instead of hardcoded map
3. Custom sorting within groups
4. Different UI styles for groups
5. Quick add to cart from variation selector

## Support

If you encounter issues:
1. Check console logs for errors
2. Verify UUID configuration
3. Test with a simple 2-product group first
4. Ensure all imports are correct

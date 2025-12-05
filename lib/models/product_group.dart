import 'package:apploook/pages/homenew.dart';

/// Represents a group of product variations (e.g., Hot Wings 3pcs, 5pcs, 7pcs)
class ProductGroup {
  final String groupName;
  final List<Product> variations;
  final Product primaryVariation; // The main product to display in the list

  ProductGroup({
    required this.groupName,
    required this.variations,
    required this.primaryVariation,
  });

  /// Get the category ID from the primary variation
  int get categoryId => primaryVariation.categoryId;

  /// Get the category title from the primary variation
  String get categoryTitle => primaryVariation.categoryTitle;

  /// Get the image path from the primary variation
  String? get imagePath => primaryVariation.imagePath;

  /// Get the description from the primary variation
  dynamic get description => primaryVariation.description;

  /// Get the price range (min - max) for display
  String getPriceRange() {
    if (variations.isEmpty) return '0';
    
    double minPrice = variations.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    double maxPrice = variations.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    
    if (minPrice == maxPrice) {
      return minPrice.toStringAsFixed(0);
    }
    
    return '${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}';
  }

  /// Check if this group has multiple variations
  bool get hasMultipleVariations => variations.length > 1;

  /// Get variation label (e.g., "3 variations available")
  String getVariationLabel() {
    return '${variations.length} variations';
  }

  /// Check if all variations are out of stock
  bool get allOutOfStock => variations.every((p) => p.outOfStock);

  /// Check if any variation is out of stock
  bool get anyOutOfStock => variations.any((p) => p.outOfStock);
}

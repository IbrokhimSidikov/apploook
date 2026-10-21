import 'dart:math' as math;

import '../pages/homenew.dart' show Product;

/// How many crystals a product earns when ordered.
///
/// The figure comes from the backend (`crystal_points` on each v3 branch
/// menu item). Products without one earn nothing, and callers hide the
/// promo when the result is zero. The rule lives here, in one place, so the
/// menu card, the details page and the cart row always agree.
abstract class CrystalReward {
  /// Crystals for one unit of [product].
  static int perUnit(Product product) {
    final points = product.crystalPoints;
    if (points == null || points < 0) return 0;
    return points;
  }

  /// Crystals for [quantity] units of [product].
  static int forQuantity(Product product, int quantity) =>
      perUnit(product) * math.max(1, quantity);
}

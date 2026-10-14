import 'dart:math' as math;

import '../pages/homenew.dart' show Product;

/// How many crystals a product earns when ordered.
///
/// The backend can set the figure per product (`crystal_reward`). When it
/// does not, the fallback is price-based: one crystal per
/// [uzsPerCrystal] UZS of the product's base price, never below [minimum].
/// The rule lives here, in one place, so the details page and the cart row
/// always agree.
abstract class CrystalReward {
  static const int uzsPerCrystal = 5000;
  static const int minimum = 1;

  /// Crystals for one unit of [product].
  static int perUnit(Product product) {
    final backend = product.crystalReward;
    if (backend != null && backend >= 0) return backend;
    return math.max(minimum, product.price ~/ uzsPerCrystal);
  }

  /// Crystals for [quantity] units of [product].
  static int forQuantity(Product product, int quantity) =>
      perUnit(product) * math.max(1, quantity);
}

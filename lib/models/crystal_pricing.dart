import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/pages/homenew.dart' show Product;

/// Client-side mirror of the server's crystal pricing rule, for display.
///
/// The figures shown on the menu, the details page and the cart come from
/// here so they always agree with each other. They are never the price the
/// customer is charged: `/loyalty/quote` re-prices every line from the
/// inventory at the customer's tier, and the hold is reserved on those
/// figures. If the two ever disagree, the server wins and the checkout
/// re-renders with its numbers.
///
/// The rule, per line:
///
///   crystal price  = sum over product + selected modifiers of
///                    crystal_price_<tier> x quantity, times the line quantity.
///                    A component with no tier price makes the line
///                    unsellable for crystals - unless it costs nothing in
///                    money (a sauce choice), which stays free in crystals.
///   crystal points = sum of crystal_points x quantity, times line quantity,
///                    earned only when the line is paid with money.
abstract class CrystalPricing {
  /// Crystal price of one unit of [product] alone at [tier], or null.
  static int? productPrice(Product product, LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.c:
        return product.crystalPriceC;
      case LoyaltyTier.b:
        return product.crystalPriceB;
      case LoyaltyTier.a:
        return product.crystalPriceA;
    }
  }

  static int? modifierPrice(Modifier modifier, LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.c:
        return modifier.crystalPriceC;
      case LoyaltyTier.b:
        return modifier.crystalPriceB;
      case LoyaltyTier.a:
        return modifier.crystalPriceA;
    }
  }

  /// Crystal price of one configured unit (product + modifiers), or null
  /// when the configuration is not sold for crystals at [tier].
  static int? unitPrice(
    Product product,
    List<SelectedModifier> modifiers,
    LoyaltyTier tier,
  ) {
    final base = productPrice(product, tier);
    // A product with no tier price of its own is still sellable when it is
    // a Delever "main product" whose variant modifier carries the price -
    // the same shape the POS mapping uses. Only a priced-in-money product
    // without a crystal price blocks the line.
    if (base == null && product.price > 0 && product.sievesId != null) {
      return null;
    }
    var total = base ?? 0;
    var priced = base != null;
    for (final selected in modifiers) {
      final price = modifierPrice(selected.modifier, tier);
      if (price == null) {
        if (selected.modifier.price > 0) return null;
        continue;
      }
      priced = true;
      total += price * selected.quantity;
    }
    return priced ? total : null;
  }

  /// Crystal price of the whole [line] at [tier], or null.
  static int? linePrice(CartItem line, LoyaltyTier tier) {
    final product = line.product;
    if (product is! Product) return null;
    final unit = unitPrice(product, line.selectedModifiers, tier);
    return unit == null ? null : unit * line.quantity;
  }

  /// Crystals one configured unit earns when paid with money.
  static int unitPoints(Product product, List<SelectedModifier> modifiers) {
    var points = (product.crystalPoints ?? 0).clamp(0, 1 << 30);
    for (final selected in modifiers) {
      points += (selected.modifier.crystalPoints ?? 0).clamp(0, 1 << 30) *
          selected.quantity;
    }
    return points;
  }

  /// Crystals the whole [line] earns when paid with money.
  static int linePoints(CartItem line) {
    final product = line.product;
    if (product is! Product) return 0;
    return unitPoints(product, line.selectedModifiers) * line.quantity;
  }

  /// True when the product or any selected modifier is crystal-only.
  static bool isCrystalOnly(Product product, List<SelectedModifier> modifiers) {
    if (product.isCrystalOnly) return true;
    for (final selected in modifiers) {
      if (selected.modifier.isCrystalOnly) return true;
    }
    return false;
  }

  static bool lineIsCrystalOnly(CartItem line) {
    final product = line.product;
    if (product is! Product) return false;
    return isCrystalOnly(product, line.selectedModifiers);
  }

  /// Whether the cart line may be offered the "pay with crystals" toggle.
  static bool lineSellableForCrystals(CartItem line, LoyaltyTier tier) =>
      linePrice(line, tier) != null;
}

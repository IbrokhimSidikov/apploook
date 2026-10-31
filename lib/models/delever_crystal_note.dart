import 'package:apploook/models/cart_item.dart';

/// The Delever order comment for a delivery order paid partly with crystals.
///
/// Delever drops per-line flags, so the comment is the only thing that tells
/// the server which lines crystals paid for when the order comes back:
///
///     crystal_items:<product_id>:<quantity>,<product_id>:<quantity>;
///     loyalty_ref:<hold_id>;
///     <customer comment>
///
/// The server removes crystal_items and keeps loyalty_ref in the saved note.
/// A product id it cannot match does not fail the order: that line is simply
/// charged as money.
class DeleverCrystalNote {
  // Customers type into the same field, so these never survive from their text.
  static final RegExp _reservedKeys = RegExp(
    r'crystal_items:[\w:.,-]+;?|loyalty_ref:\d+;?',
    caseSensitive: false,
  );

  /// `crystal_items:` naming each main product's crystal-paid quantity, or an
  /// empty string when there is none. Lines differing only in modifiers share
  /// a product id, so they add up into one entry.
  static String crystalItemsKey(Iterable<CartItem> crystalLines) {
    final quantities = <String, int>{};
    for (final line in crystalLines) {
      final productId = '${line.product.uuid ?? ''}';
      if (productId.isEmpty) continue;
      quantities[productId] = (quantities[productId] ?? 0) + line.quantity;
    }
    if (quantities.isEmpty) return '';
    final entries =
        quantities.entries.map((entry) => '${entry.key}:${entry.value}');
    return 'crystal_items:${entries.join(',')};';
  }

  /// The full comment: the keys first, then what the customer wrote.
  ///
  /// crystal_items only goes out next to a hold, because the server ignores
  /// it without one and would charge those lines as money.
  static String compose({
    required Iterable<CartItem> crystalLines,
    required String? holdRef,
    required String comment,
  }) {
    final hasHold = holdRef != null && holdRef.isNotEmpty;
    final customerText = comment.replaceAll(_reservedKeys, '').trim();
    return [
      if (hasHold) crystalItemsKey(crystalLines),
      if (hasHold) holdRef,
      customerText,
    ].where((part) => part.isNotEmpty).join('\n');
  }

  /// Delever can merge equal lines and the server takes the crystal quantity
  /// from the first ones it meets, so a product paid both ways needs its
  /// crystal line ahead of its money line.
  static List<CartItem> crystalLinesFirst(List<CartItem> items) => [
        ...items.where((item) => item.payWithCrystals),
        ...items.where((item) => !item.payWithCrystals),
      ];
}

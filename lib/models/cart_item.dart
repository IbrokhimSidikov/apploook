import '../models/modifier_models.dart';
import '../models/product_configuration.dart';

class CartItem {
  static int _nextId = 0;

  /// Unique per cart line; two lines with the same product but different
  /// modifier configurations get different IDs.
  final int id;
  final product;
  int quantity;
  final List<SelectedModifier> selectedModifiers;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedModifiers = const [],
  }) : id = ++_nextId;

  /// Identity of the product regardless of configuration.
  String get productKey {
    final uuid = '${product.uuid ?? ''}';
    return uuid.isNotEmpty ? '${product.id}:$uuid' : '${product.id}';
  }

  /// Deterministic key of product + modifier configuration; equal keys mean
  /// the lines can be merged. See [CartConfigurationKey].
  String get configurationKey => CartConfigurationKey.build(
        productKey: productKey,
        modifiers: selectedModifiers,
      );

  bool hasSameConfiguration(CartItem other) =>
      configurationKey == other.configurationKey;

  // Price of one configured unit (base + modifiers)
  double get unitPrice =>
      ProductPriceCalculator.unitPrice(product.price, selectedModifiers);

  // Calculate total price including modifiers
  double get totalPrice =>
      ProductPriceCalculator.totalPrice(product.price, selectedModifiers, quantity);

  // Get display name with modifiers
  String get displayName {
    if (selectedModifiers.isEmpty) {
      return product.name;
    }

    String modifierNames = selectedModifiers
        .map((modifier) => modifier.quantity > 1
            ? '${modifier.modifier.name} ×${modifier.quantity}'
            : modifier.modifier.name)
        .join(', ');
    return '${product.name} ($modifierNames)';
  }

  // Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'product': {
        'id': product.id,
        'uuid': product.uuid,
        'name': product.name,
        'price': product.price,
      },
      'quantity': quantity,
      'selectedModifiers': selectedModifiers.map((modifier) => {
        'groupId': modifier.groupId,
        'modifierId': modifier.modifier.id, // This is the ID you want: 928a551b-914b-4154-ae48-4485f334ef25
        'modifierName': modifier.modifier.name,
        'modifierPrice': modifier.modifier.price,
        'quantity': modifier.quantity,
        'serviceCodesUz': modifier.modifier.serviceCodesUz,
      }).toList(),
      'totalPrice': totalPrice,
    };
  }
}

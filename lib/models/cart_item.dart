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

  /// Can this line be sent to the Sieves POS (self-pickup, carhop,
  /// in-restaurant)? Mirrors the server rule: the product itself is linked
  /// to inventory, or - for a Delever "main product" whose variants are
  /// modifiers - at least one selected modifier is, and every selected
  /// modifier is linked. Delivery orders never consult this.
  ///
  /// Only blocks on facts the backend actually sent. Products or modifiers
  /// without mapping info (older backend, direct Delever menu, stale cache)
  /// are left for the server to judge, so the app never refuses an order
  /// the server would accept.
  bool get isPosOrderable {
    final dynamic p = product;
    bool hasMapping;
    int? productSievesId;
    bool? backendVerdict;
    try {
      hasMapping = p.hasPosMapping == true;
      productSievesId = p.sievesId as int?;
      backendVerdict = p.posOrderable as bool?;
    } catch (_) {
      return true;
    }
    if (!hasMapping) return true;

    final known = selectedModifiers
        .where((selected) => selected.modifier.hasPosMapping)
        .toList();

    // A modifier the server knows and could not link: the order will fail.
    if (known.any((selected) => selected.modifier.sievesId == null)) {
      return false;
    }
    if (backendVerdict != null) return backendVerdict;
    if (productSievesId != null) return true;

    // Main product unlinked. A linked variant modifier can stand in for it.
    if (known.any((selected) => selected.modifier.sievesId != null)) {
      return true;
    }
    // No modifier info from the backend: cannot judge, let the server decide.
    if (known.isEmpty && selectedModifiers.isNotEmpty) return true;
    return false;
  }

  /// A Delever "variant" modifier names a concrete version of the product
  /// ("Хот шотс мини." under "Хот шотс.", "Острые крылышки 3шт" under
  /// "Острые крылышки"). The POS has a row for the variant, not for the
  /// parent, so the variant has to become the POS line. Detected by the
  /// variant name containing the product name; a drink inside a combo does
  /// not match and stays a child line.
  bool isVariantModifier(SelectedModifier selected) {
    final String productName = normalizeName('${product.name}');
    final String modifierName = normalizeName(selected.modifier.name);
    if (productName.isEmpty || modifierName.isEmpty) return false;
    return modifierName.contains(productName);
  }

  /// Lower-case, letters and digits only, single spaces. Same rule as the
  /// server side so both agree on what is a variant.
  static String normalizeName(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ё', 'е')
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

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

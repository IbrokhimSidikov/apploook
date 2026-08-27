/// Represents a single modifier option within a modifier group
class Modifier {
  final String id;
  final String name;
  final double price;
  final int minAmount;
  final int maxAmount;
  final Map<String, dynamic>? serviceCodesUz;

  Modifier({
    required this.id,
    required this.name,
    required this.price,
    required this.minAmount,
    required this.maxAmount,
    this.serviceCodesUz,
  });

  /// Smallest quantity a selected modifier can have. `minAmount` of 0 means
  /// "not selected", so once selected the quantity is at least 1.
  int get minSelectedQuantity => minAmount < 1 ? 1 : minAmount;

  /// Largest quantity this modifier can be selected with.
  int get maxSelectedQuantity =>
      maxAmount < minSelectedQuantity ? minSelectedQuantity : maxAmount;

  /// Whether the UI should offer a quantity stepper for this modifier.
  bool get supportsQuantity => maxSelectedQuantity > 1;

  factory Modifier.fromJson(Map<String, dynamic> json) {
    return Modifier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      minAmount: json['minAmount'] ?? 0,
      maxAmount: json['maxAmount'] ?? 1,
      serviceCodesUz: json['serviceCodesUz'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'serviceCodesUz': serviceCodesUz,
    };
  }
}

/// Represents a group of modifiers (e.g., "Choose one", "Add extras")
class ModifierGroup {
  final String id;
  final String name;
  final List<Modifier> modifiers;
  final int minSelectedModifiers;
  final int maxSelectedModifiers;
  final int sortOrder;

  ModifierGroup({
    required this.id,
    required this.name,
    required this.modifiers,
    required this.minSelectedModifiers,
    required this.maxSelectedModifiers,
    this.sortOrder = 0,
  });

  /// The user must pick at least one modifier from this group.
  bool get isRequired => minSelectedModifiers > 0;

  /// More than one distinct modifier can be selected at once.
  bool get allowsMultiple => maxSelectedModifiers > 1;

  /// Effective upper bound: a max of 0 (or below min) from the API is treated
  /// as "no limit beyond the number of options".
  int get effectiveMaxSelected {
    if (maxSelectedModifiers < 1 || maxSelectedModifiers < minSelectedModifiers) {
      return modifiers.length < minSelectedModifiers
          ? minSelectedModifiers
          : modifiers.length;
    }
    return maxSelectedModifiers;
  }

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    List<Modifier> modifiers = [];
    if (json['modifiers'] != null) {
      modifiers = (json['modifiers'] as List)
          .map((modifier) => Modifier.fromJson(modifier))
          .toList();
    }

    return ModifierGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modifiers: modifiers,
      minSelectedModifiers: json['minSelectedModifiers'] ?? 0,
      maxSelectedModifiers: json['maxSelectedModifiers'] ?? 1,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'minSelectedModifiers': minSelectedModifiers,
      'maxSelectedModifiers': maxSelectedModifiers,
      'sortOrder': sortOrder,
    };
  }

  /// Groups ordered by `sortOrder` ascending (stable for equal values).
  static List<ModifierGroup> sorted(Iterable<ModifierGroup> groups) {
    final list = groups.toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }
}

/// Represents a selected modifier with quantity
class SelectedModifier {
  final Modifier modifier;
  final int quantity;

  /// ID of the [ModifierGroup] this selection was made in. Empty when unknown
  /// (e.g. legacy cart items built before groups were tracked).
  final String groupId;

  SelectedModifier({
    required this.modifier,
    required this.quantity,
    this.groupId = '',
  });

  double get totalPrice => modifier.price * quantity;

  SelectedModifier copyWith({int? quantity}) {
    return SelectedModifier(
      modifier: modifier,
      quantity: quantity ?? this.quantity,
      groupId: groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modifier': modifier.toJson(),
      'quantity': quantity,
      'groupId': groupId,
    };
  }

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      modifier: Modifier.fromJson(json['modifier']),
      quantity: json['quantity'] ?? 1,
      groupId: json['groupId'] ?? '',
    );
  }
}

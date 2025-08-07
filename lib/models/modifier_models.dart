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

  ModifierGroup({
    required this.id,
    required this.name,
    required this.modifiers,
    required this.minSelectedModifiers,
    required this.maxSelectedModifiers,
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'minSelectedModifiers': minSelectedModifiers,
      'maxSelectedModifiers': maxSelectedModifiers,
    };
  }
}

/// Represents a selected modifier with quantity
class SelectedModifier {
  final Modifier modifier;
  final int quantity;

  SelectedModifier({
    required this.modifier,
    required this.quantity,
  });

  double get totalPrice => modifier.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'modifier': modifier.toJson(),
      'quantity': quantity,
    };
  }

  factory SelectedModifier.fromJson(Map<String, dynamic> json) {
    return SelectedModifier(
      modifier: Modifier.fromJson(json['modifier']),
      quantity: json['quantity'] ?? 1,
    );
  }
}

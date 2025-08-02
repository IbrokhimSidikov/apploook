import '../models/modifier_models.dart';

class CartItem {
  final product;
  int quantity;
  final List<SelectedModifier> selectedModifiers;

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.selectedModifiers = const [],
  });

  // Calculate total price including modifiers
  double get totalPrice {
    double basePrice = product.price * quantity;
    double modifierPrice = selectedModifiers.fold(0.0, (sum, modifier) => sum + modifier.totalPrice);
    return basePrice + (modifierPrice * quantity);
  }

  // Get display name with modifiers
  String get displayName {
    if (selectedModifiers.isEmpty) {
      return product.name;
    }
    
    String modifierNames = selectedModifiers
        .map((modifier) => modifier.modifier.name)
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

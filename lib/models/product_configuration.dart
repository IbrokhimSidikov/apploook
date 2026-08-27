import 'package:apploook/models/modifier_models.dart';

/// Selection state of one product: modifier group ID -> selected modifiers.
typedef ModifierSelections = Map<String, List<SelectedModifier>>;

/// Why a single modifier group failed validation.
class ModifierGroupValidationError {
  final ModifierGroup group;
  final int selectedCount;

  const ModifierGroupValidationError({
    required this.group,
    required this.selectedCount,
  });

  bool get isBelowMinimum => selectedCount < group.minSelectedModifiers;
  bool get isAboveMaximum => selectedCount > group.effectiveMaxSelected;

  /// How many more selections are needed to satisfy the group minimum.
  int get missingCount =>
      isBelowMinimum ? group.minSelectedModifiers - selectedCount : 0;
}

/// Result of validating a whole product configuration.
class ProductConfigurationValidation {
  final List<ModifierGroupValidationError> errors;

  const ProductConfigurationValidation(this.errors);

  static const valid = ProductConfigurationValidation([]);

  bool get isValid => errors.isEmpty;

  Set<String> get invalidGroupIds => errors.map((e) => e.group.id).toSet();

  ModifierGroup? get firstInvalidGroup =>
      errors.isEmpty ? null : errors.first.group;

  ModifierGroupValidationError? errorFor(String groupId) {
    for (final error in errors) {
      if (error.group.id == groupId) return error;
    }
    return null;
  }
}

/// Validates selections against group and modifier limits.
///
/// Group limits (`minSelectedModifiers` / `maxSelectedModifiers`) bound how many
/// distinct modifiers are chosen in a group; modifier limits
/// (`minAmount` / `maxAmount`) bound the quantity of each chosen modifier.
class ProductConfigurationValidator {
  const ProductConfigurationValidator._();

  static ProductConfigurationValidation validate(
    List<ModifierGroup> groups,
    ModifierSelections selections,
  ) {
    if (groups.isEmpty) return ProductConfigurationValidation.valid;

    final errors = <ModifierGroupValidationError>[];
    for (final group in ModifierGroup.sorted(groups)) {
      final selected = selections[group.id] ?? const [];
      final count = selected.length;

      final quantityOutOfRange = selected.any((s) =>
          s.quantity < s.modifier.minSelectedQuantity ||
          s.quantity > s.modifier.maxSelectedQuantity);

      if (count < group.minSelectedModifiers ||
          count > group.effectiveMaxSelected ||
          quantityOutOfRange) {
        errors.add(ModifierGroupValidationError(
          group: group,
          selectedCount: count,
        ));
      }
    }
    return ProductConfigurationValidation(errors);
  }
}

/// Price arithmetic shared by the details page and the cart.
class ProductPriceCalculator {
  const ProductPriceCalculator._();

  static double modifiersPrice(Iterable<SelectedModifier> modifiers) {
    return modifiers.fold(0.0, (sum, m) => sum + m.totalPrice);
  }

  /// Price of a single configured unit: base price + modifiers.
  static double unitPrice(
    double basePrice,
    Iterable<SelectedModifier> modifiers,
  ) {
    return basePrice + modifiersPrice(modifiers);
  }

  static double totalPrice(
    double basePrice,
    Iterable<SelectedModifier> modifiers,
    int quantity,
  ) {
    return unitPrice(basePrice, modifiers) * quantity;
  }
}

/// Deterministic identity of a configured product, used to merge cart lines.
///
/// Format: `productKey|groupId/modifierId:quantity|...` with modifier entries
/// sorted, so UI selection order never affects the key while any difference in
/// modifier IDs or quantities does.
class CartConfigurationKey {
  const CartConfigurationKey._();

  static String build({
    required String productKey,
    required Iterable<SelectedModifier> modifiers,
  }) {
    final entries = modifiers
        .map((m) => '${m.groupId}/${m.modifier.id}:${m.quantity}')
        .toList()
      ..sort();
    return [productKey, ...entries].join('|');
  }
}

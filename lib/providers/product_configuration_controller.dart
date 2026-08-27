import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/models/product_configuration.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/foundation.dart';

/// Page-scoped state for configuring one product before it enters the cart.
///
/// Owns the selection map (group ID -> selected modifiers) and the product
/// quantity; delegates validation, pricing and cart-item construction to the
/// pure helpers in `product_configuration.dart`.
class ProductConfigurationController extends ChangeNotifier {
  final Product product;

  /// Modifier groups ordered by `sortOrder`.
  final List<ModifierGroup> groups;

  final ModifierSelections _selections = {};
  int _quantity;

  /// Populated once the user tries to add an invalid configuration, so the UI
  /// only starts highlighting errors after an explicit attempt.
  ProductConfigurationValidation? _shownValidation;

  ProductConfigurationController({
    required this.product,
    int initialQuantity = 1,
  })  : groups = ModifierGroup.sorted(product.modifierGroups),
        _quantity = initialQuantity < 1 ? 1 : initialQuantity {
    for (final group in groups) {
      _selections[group.id] = [];
    }
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  bool get hasModifiers => groups.isNotEmpty;

  int get quantity => _quantity;

  double get basePrice => product.price;

  List<SelectedModifier> get selectedModifiers =>
      _selections.values.expand((list) => list).toList(growable: false);

  double get unitPrice =>
      ProductPriceCalculator.unitPrice(basePrice, selectedModifiers);

  double get totalPrice =>
      ProductPriceCalculator.totalPrice(basePrice, selectedModifiers, _quantity);

  List<SelectedModifier> selectionsFor(String groupId) =>
      List.unmodifiable(_selections[groupId] ?? const []);

  int selectedCount(String groupId) => _selections[groupId]?.length ?? 0;

  bool isSelected(String groupId, String modifierId) =>
      _find(groupId, modifierId) != null;

  int quantityOf(String groupId, String modifierId) =>
      _find(groupId, modifierId)?.quantity ?? 0;

  /// Whether another distinct modifier may still be selected in [group].
  bool canSelectMore(ModifierGroup group) =>
      selectedCount(group.id) < group.effectiveMaxSelected;

  /// Validation error currently displayed for [groupId], if any.
  ModifierGroupValidationError? shownErrorFor(String groupId) =>
      _shownValidation?.errorFor(groupId);

  bool get isShowingErrors =>
      _shownValidation != null && !_shownValidation!.isValid;

  // ─── Modifier selection ──────────────────────────────────────────────────

  /// Select or deselect [modifier] in [group], honouring the group limits.
  ///
  /// Single-choice groups behave like radio buttons: tapping another option
  /// replaces the current one, and a required group never ends up empty.
  /// Multi-choice groups toggle, refusing new picks once the max is reached.
  void toggleModifier(ModifierGroup group, Modifier modifier) {
    final current = _selections.putIfAbsent(group.id, () => []);
    final existingIndex =
        current.indexWhere((s) => s.modifier.id == modifier.id);

    if (existingIndex >= 0) {
      final isSingleChoice = group.effectiveMaxSelected == 1;
      if (isSingleChoice && group.isRequired) return;
      current.removeAt(existingIndex);
    } else {
      if (group.effectiveMaxSelected == 1) {
        current.clear();
      } else if (current.length >= group.effectiveMaxSelected) {
        return;
      }
      current.add(SelectedModifier(
        modifier: modifier,
        quantity: modifier.minSelectedQuantity,
        groupId: group.id,
      ));
    }
    _afterChange();
  }

  /// Set the quantity of an already-selected modifier, clamped to
  /// [Modifier.minSelectedQuantity]..[Modifier.maxSelectedQuantity].
  /// Dropping below the minimum deselects the modifier.
  void setModifierQuantity(ModifierGroup group, Modifier modifier, int value) {
    final current = _selections[group.id];
    if (current == null) return;
    final index = current.indexWhere((s) => s.modifier.id == modifier.id);
    if (index < 0) return;

    if (value < modifier.minSelectedQuantity) {
      final isSingleChoice = group.effectiveMaxSelected == 1;
      if (isSingleChoice && group.isRequired) {
        current[index] =
            current[index].copyWith(quantity: modifier.minSelectedQuantity);
      } else {
        current.removeAt(index);
      }
    } else {
      final clamped = value > modifier.maxSelectedQuantity
          ? modifier.maxSelectedQuantity
          : value;
      current[index] = current[index].copyWith(quantity: clamped);
    }
    _afterChange();
  }

  void incrementModifier(ModifierGroup group, Modifier modifier) =>
      setModifierQuantity(
          group, modifier, quantityOf(group.id, modifier.id) + 1);

  void decrementModifier(ModifierGroup group, Modifier modifier) =>
      setModifierQuantity(
          group, modifier, quantityOf(group.id, modifier.id) - 1);

  // ─── Product quantity ────────────────────────────────────────────────────

  void incrementQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (_quantity <= 1) return;
    _quantity--;
    notifyListeners();
  }

  // ─── Validation & cart ───────────────────────────────────────────────────

  /// Validate the current configuration and remember the result so the UI can
  /// highlight offending groups. Products without modifiers are always valid.
  ProductConfigurationValidation validate() {
    final result =
        ProductConfigurationValidator.validate(groups, _selections);
    _shownValidation = result;
    notifyListeners();
    return result;
  }

  /// Build the cart line for the current configuration. Callers must run
  /// [validate] first; this does not re-check limits.
  CartItem buildCartItem() {
    return CartItem(
      product: product,
      quantity: _quantity,
      selectedModifiers: selectedModifiers,
    );
  }

  // ─── Internals ───────────────────────────────────────────────────────────

  SelectedModifier? _find(String groupId, String modifierId) {
    final list = _selections[groupId];
    if (list == null) return null;
    for (final s in list) {
      if (s.modifier.id == modifierId) return s;
    }
    return null;
  }

  void _afterChange() {
    // Keep error highlights live: once errors are shown, re-validate on every
    // change so a group clears as soon as the user fixes it.
    if (_shownValidation != null) {
      _shownValidation =
          ProductConfigurationValidator.validate(groups, _selections);
    }
    notifyListeners();
  }
}

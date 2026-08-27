import 'package:apploook/cart_provider.dart';
import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/models/product_configuration.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/product_configuration_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Modifier _mod(String id, {double price = 0, int minAmount = 0, int maxAmount = 1}) =>
    Modifier(id: id, name: id, price: price, minAmount: minAmount, maxAmount: maxAmount);

ModifierGroup _group(
  String id, {
  required List<Modifier> modifiers,
  int min = 1,
  int max = 1,
  int sortOrder = 0,
}) =>
    ModifierGroup(
      id: id,
      name: id,
      modifiers: modifiers,
      minSelectedModifiers: min,
      maxSelectedModifiers: max,
      sortOrder: sortOrder,
    );

/// Mirrors the "Ужин" product from the API: three required single-choice
/// groups, deliberately listed out of sortOrder.
final _dinnerGroups = [
  _group('sauce', sortOrder: 3, modifiers: [
    _mod('salsa', maxAmount: 2),
    _mod('taco', maxAmount: 2),
  ]),
  _group('dish', sortOrder: 1, modifiers: [_mod('mild'), _mod('mix')]),
  _group('drink', sortOrder: 2, modifiers: [_mod('cola'), _mod('fanta')]),
];

Product _product({List<ModifierGroup> groups = const [], double price = 52000}) =>
    Product(
      name: 'Ужин',
      id: 1,
      uuid: '449c233f',
      categoryId: 1,
      categoryTitle: 'Combo',
      price: price,
      description: const {},
      modifierGroups: groups,
    );

void main() {
  group('ProductConfigurationController', () {
    test('orders groups by sortOrder', () {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      expect(c.groups.map((g) => g.id), ['dish', 'drink', 'sauce']);
    });

    test('starts with nothing selected and fails validation for required groups', () {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      final v = c.validate();
      expect(v.isValid, isFalse);
      expect(v.invalidGroupIds, {'dish', 'drink', 'sauce'});
      expect(v.firstInvalidGroup!.id, 'dish');
    });

    test('reports only the groups still missing a selection', () {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      c.toggleModifier(c.groups[1], c.groups[1].modifiers[0]); // drink: cola
      final v = c.validate();
      expect(v.invalidGroupIds, {'dish', 'sauce'});
    });

    test('single-choice group replaces selection and never empties when required', () {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      final dish = c.groups[0];
      c.toggleModifier(dish, dish.modifiers[0]);
      c.toggleModifier(dish, dish.modifiers[1]);
      expect(c.isSelected('dish', 'mix'), isTrue);
      expect(c.isSelected('dish', 'mild'), isFalse);
      c.toggleModifier(dish, dish.modifiers[1]); // tap again → stays
      expect(c.selectedCount('dish'), 1);
    });

    test('optional single-choice group can be deselected', () {
      final g = _group('extra', min: 0, max: 1, modifiers: [_mod('cheese')]);
      final c = ProductConfigurationController(product: _product(groups: [g]));
      c.toggleModifier(g, g.modifiers[0]);
      c.toggleModifier(g, g.modifiers[0]);
      expect(c.selectedCount('extra'), 0);
      expect(c.validate().isValid, isTrue);
    });

    test('multi-choice group enforces maxSelectedModifiers', () {
      final g = _group('toppings', min: 0, max: 2, modifiers: [
        _mod('a'),
        _mod('b'),
        _mod('c'),
      ]);
      final c = ProductConfigurationController(product: _product(groups: [g]));
      c.toggleModifier(g, g.modifiers[0]);
      c.toggleModifier(g, g.modifiers[1]);
      expect(c.canSelectMore(g), isFalse);
      c.toggleModifier(g, g.modifiers[2]);
      expect(c.selectedCount('toppings'), 2);
      expect(c.isSelected('toppings', 'c'), isFalse);
    });

    test('modifier quantity is clamped to maxAmount and drops below min deselects', () {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      final sauce = c.groups[2];
      final salsa = sauce.modifiers[0];
      c.toggleModifier(sauce, salsa);
      expect(c.quantityOf('sauce', 'salsa'), 1);
      c.incrementModifier(sauce, salsa);
      c.incrementModifier(sauce, salsa);
      expect(c.quantityOf('sauce', 'salsa'), 2);

      // Sauce is a required single-choice group: decrementing to zero keeps
      // the minimum quantity rather than emptying the group.
      c.decrementModifier(sauce, salsa);
      c.decrementModifier(sauce, salsa);
      expect(c.quantityOf('sauce', 'salsa'), 1);

      final optional = _group('opt', min: 0, max: 3, modifiers: [_mod('x', maxAmount: 3)]);
      final c2 = ProductConfigurationController(product: _product(groups: [optional]));
      c2.toggleModifier(optional, optional.modifiers[0]);
      c2.decrementModifier(optional, optional.modifiers[0]);
      expect(c2.isSelected('opt', 'x'), isFalse);
    });

    test('price = base + Σ(modifier price × quantity), times product quantity', () {
      final g = _group('extras', min: 0, max: 2, modifiers: [
        _mod('cheese', price: 5000, maxAmount: 3),
        _mod('bacon', price: 7000),
      ]);
      final c = ProductConfigurationController(product: _product(groups: [g]));
      expect(c.totalPrice, 52000);
      c.toggleModifier(g, g.modifiers[0]);
      expect(c.totalPrice, 57000);
      c.incrementModifier(g, g.modifiers[0]);
      expect(c.totalPrice, 62000);
      c.toggleModifier(g, g.modifiers[1]);
      expect(c.unitPrice, 69000);
      c.incrementQuantity();
      expect(c.totalPrice, 138000);
    });

    test('product without modifier groups validates and keeps base price', () {
      final c = ProductConfigurationController(product: _product());
      expect(c.hasModifiers, isFalse);
      expect(c.validate().isValid, isTrue);
      expect(c.totalPrice, 52000);
      final item = c.buildCartItem();
      expect(item.selectedModifiers, isEmpty);
      expect(item.totalPrice, 52000);
    });
  });

  group('CartConfigurationKey', () {
    test('is independent of selection order and sensitive to quantity', () {
      final a = SelectedModifier(modifier: _mod('a'), quantity: 1, groupId: 'g1');
      final b = SelectedModifier(modifier: _mod('b'), quantity: 1, groupId: 'g2');
      final k1 = CartConfigurationKey.build(productKey: 'p', modifiers: [a, b]);
      final k2 = CartConfigurationKey.build(productKey: 'p', modifiers: [b, a]);
      expect(k1, k2);
      expect(k1, 'p|g1/a:1|g2/b:1');

      final a2 = SelectedModifier(modifier: _mod('a'), quantity: 2, groupId: 'g1');
      expect(CartConfigurationKey.build(productKey: 'p', modifiers: [a2, b]), isNot(k1));
    });
  });

  group('CartProvider merging', () {
    CartItem configured(List<String> picks) {
      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      for (final group in c.groups) {
        final pick = group.modifiers.firstWhere((m) => picks.contains(m.id));
        c.toggleModifier(group, pick);
      }
      return c.buildCartItem();
    }

    test('identical configurations merge, different ones stay separate', () {
      final cart = CartProvider();
      cart.addToCartWithModifiers(configured(['mild', 'cola', 'salsa']));
      cart.addToCartWithModifiers(configured(['mild', 'cola', 'salsa']));
      expect(cart.cartItems.length, 1);
      expect(cart.cartItems.first.quantity, 2);

      cart.addToCartWithModifiers(configured(['mix', 'fanta', 'taco']));
      expect(cart.cartItems.length, 2);
      expect(cart.showQuantity(), 3);
    });

    test('same modifiers with different quantities are separate lines', () {
      final cart = CartProvider();
      final one = configured(['mild', 'cola', 'salsa']);
      cart.addToCartWithModifiers(one);

      final c = ProductConfigurationController(product: _product(groups: _dinnerGroups));
      for (final group in c.groups) {
        final pick = group.modifiers
            .firstWhere((m) => ['mild', 'cola', 'salsa'].contains(m.id));
        c.toggleModifier(group, pick);
      }
      c.incrementModifier(c.groups[2], c.groups[2].modifiers[0]); // salsa ×2
      cart.addToCartWithModifiers(c.buildCartItem());
      expect(cart.cartItems.length, 2);
    });

    test('plain products still merge via addToCart and never merge with configured ones', () {
      final cart = CartProvider();
      final plain = _product();
      cart.addToCart(plain, 1);
      cart.addToCart(plain, 2);
      expect(cart.cartItems.length, 1);
      expect(cart.cartItems.first.quantity, 3);

      cart.addToCartWithModifiers(configured(['mild', 'cola', 'salsa']));
      expect(cart.cartItems.length, 2);
    });
  });
}

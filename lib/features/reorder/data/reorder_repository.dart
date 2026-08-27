import 'package:shared_preferences/shared_preferences.dart';

import '../../../cart_provider.dart';
import '../../../models/cart_item.dart';
import '../../../models/modifier_models.dart';
import '../../../pages/homenew.dart';
import '../../../services/menu_service.dart';
import '../../../services/order_history_service.dart';
import '../domain/last_order.dart';

/// Result of materializing a historical order into the current cart.
/// Counts let the UI tell the user when items had to be skipped because
/// the menu changed.
class MaterializeResult {
  final int addedCount;
  final int skippedCount;

  const MaterializeResult({required this.addedCount, required this.skippedCount});

  bool get isEmpty => addedCount == 0;
}

class ReorderRepository {
  ReorderRepository({
    OrderHistoryService? history,
    MenuService? menu,
  })  : _history = history ?? OrderHistoryService(),
        _menu = menu ?? MenuService();

  final OrderHistoryService _history;
  final MenuService _menu;

  /// Cached flag so the FAB can render synchronously on subsequent launches
  /// instead of popping in after the network round-trip.
  static const String _hasHistoryKey = 'reorder_has_history';

  Future<bool> hasHistoryHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasHistoryKey) ?? false;
  }

  Future<void> _setHistoryHint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasHistoryKey, value);
  }

  /// Fetch the user's most recent reorder-eligible order (status Delivered
  /// or Closed). Pending / cancelled orders are skipped so the Reorder
  /// pill never offers an in-flight or aborted order as a template.
  /// Returns null if there's no eligible order, no phone on device, or
  /// the network call fails with no cache.
  Future<LastOrder?> fetchLastOrder({bool forceRefresh = false}) async {
    final orders = await fetchLastOrders(limit: 1, forceRefresh: forceRefresh);
    return orders.isEmpty ? null : orders.first;
  }

  /// Fetch up to [limit] of the user's most recent reorder-eligible orders
  /// (status Delivered or Closed), newest first. Pending / cancelled orders
  /// are skipped so the picker never offers an in-flight or aborted order as
  /// a template. Returns an empty list if there's no eligible order, no phone
  /// on device, or the network call fails with no cache.
  Future<List<LastOrder>> fetchLastOrders({
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _history.fetchOrderHistory(
        page: 1,
        limit: 20,
        forceRefresh: forceRefresh,
      );
      final list = response['data'] as List<dynamic>? ?? const [];
      if (list.isEmpty) {
        await _setHistoryHint(false);
        return const [];
      }
      await _setHistoryHint(true);

      final eligible = <LastOrder>[];
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final order = LastOrder.fromJson(raw);
        if (order.isReorderEligible) {
          eligible.add(order);
          if (eligible.length >= limit) break;
        }
      }
      // History exists but nothing is finished yet → empty list.
      return eligible;
    } catch (e) {
      // Surface as empty — controller decides whether to retry or stay silent.
      print('ReorderRepository: failed to fetch last orders: $e');
      return const [];
    }
  }

  /// Replace the current cart contents with items from [order]. Items whose
  /// product no longer exists in the menu (or is out of stock) are skipped.
  /// Modifiers are best-effort: matched by name within the product's
  /// modifier groups; unmatched modifiers are silently dropped.
  MaterializeResult materializeCart(LastOrder order, CartProvider cart) {
    cart.clearCart();

    int added = 0;
    int skipped = 0;

    for (final item in order.items) {
      final product = _findProduct(item);
      if (product == null || product.outOfStock) {
        skipped++;
        continue;
      }

      final selectedModifiers = _rebuildModifiers(product, item.modifiers);
      final cartItem = CartItem(
        product: product,
        quantity: item.quantity > 0 ? item.quantity : 1,
        selectedModifiers: selectedModifiers,
      );
      cart.addToCartWithModifiers(cartItem);
      added++;
    }

    if (added > 0) {
      cart.ensureMandatoryPackage(_menu.allProducts);
    }

    return MaterializeResult(addedCount: added, skippedCount: skipped);
  }

  Product? _findProduct(LastOrderItem item) {
    final products = _menu.allProducts;
    if (products.isEmpty) return null;

    // One inventory row can map to several Delever menu IDs (different sizes
    // / regional variants). Try every candidate uuid before falling back.
    if (item.productUuids.isNotEmpty) {
      final wanted = item.productUuids.toSet();
      for (final p in products) {
        if (wanted.contains(p.uuid)) return p;
      }
    }

    final rawName = item.name.trim();
    if (rawName.isEmpty) return null;

    // Exact name first.
    for (final p in products) {
      if (p.name == rawName) return p;
    }

    // Normalized fallback. Historical names come from `t_inventory.name` while
    // menu names come from Delever, and they routinely differ by case, stray
    // whitespace, or NBSPs even when they refer to the same product.
    final normTarget = _normalizeName(rawName);
    if (normTarget.isEmpty) return null;
    for (final p in products) {
      if (_normalizeName(p.name) == normTarget) return p;
    }

    print(
        'ReorderRepository: no menu match for "$rawName" (uuids=${item.productUuids})');
    return null;
  }

  static final RegExp _wsRegex = RegExp(r'\s+');
  String _normalizeName(String s) =>
      s.replaceAll(' ', ' ').trim().toLowerCase().replaceAll(_wsRegex, ' ');

  List<SelectedModifier> _rebuildModifiers(
    Product product,
    List<LastOrderItemModifier> historical,
  ) {
    if (historical.isEmpty || product.modifierGroups.isEmpty) return const [];

    final result = <SelectedModifier>[];
    for (final hist in historical) {
      Modifier? match;
      ModifierGroup? matchGroup;

      // Prefer uuid match — one historical modifier inventory row can map
      // to several Delever modifier IDs, so try each.
      if (hist.productUuids.isNotEmpty) {
        final wanted = hist.productUuids.toSet();
        for (final group in product.modifierGroups) {
          for (final modifier in group.modifiers) {
            if (wanted.contains(modifier.id)) {
              match = modifier;
              matchGroup = group;
              break;
            }
          }
          if (match != null) break;
        }
      }

      // Name fallback for orders placed before the backend started shipping
      // modifier uuids.
      if (match == null) {
        for (final group in product.modifierGroups) {
          for (final modifier in group.modifiers) {
            if (modifier.name == hist.name) {
              match = modifier;
              matchGroup = group;
              break;
            }
          }
          if (match != null) break;
        }
      }

      if (match != null) {
        result.add(SelectedModifier(
          modifier: match,
          quantity: hist.quantity,
          groupId: matchGroup?.id ?? '',
        ));
      }
    }
    return result;
  }
}

import 'package:flutter/foundation.dart';

import '../../../cart_provider.dart';
import '../data/reorder_repository.dart';
import '../domain/last_order.dart';
import '../domain/reorder_payload.dart';

enum ReorderLoadState { idle, loading, ready, empty, error }

class ReorderController extends ChangeNotifier {
  ReorderController({ReorderRepository? repository})
      : _repository = repository ?? ReorderRepository();

  final ReorderRepository _repository;

  ReorderLoadState _state = ReorderLoadState.idle;
  LastOrder? _lastOrder;
  bool _hasHistoryHint = false;

  ReorderLoadState get state => _state;
  LastOrder? get lastOrder => _lastOrder;

  /// True once we have any reason to believe the user has previous orders —
  /// either we already fetched one, or a previous session recorded the hint.
  /// Used by the FAB to decide whether to reserve space on first frame.
  bool get hasOrderToShow =>
      _lastOrder != null || (_state == ReorderLoadState.loading && _hasHistoryHint);

  /// Call once at app start (after the user is signed in) to populate state.
  /// Safe to call repeatedly; uses the underlying 5-min cache.
  Future<void> load({bool forceRefresh = false}) async {
    if (_state == ReorderLoadState.loading) return;
    _hasHistoryHint = await _repository.hasHistoryHint();
    _state = ReorderLoadState.loading;
    notifyListeners();

    final order = await _repository.fetchLastOrder(forceRefresh: forceRefresh);
    _lastOrder = order;
    if (order == null) {
      _state = _hasHistoryHint ? ReorderLoadState.error : ReorderLoadState.empty;
    } else {
      _state = ReorderLoadState.ready;
    }
    notifyListeners();
  }

  /// Applies [order] to the cart and returns a payload to hand to Checkout.
  /// Returns null if no items could be added (menu drifted entirely).
  ReorderPayload? applyToCart(LastOrder order, CartProvider cart) {
    final result = _repository.materializeCart(order, cart);
    if (result.isEmpty) return null;

    final parsedNote = _parseNote(order.note);

    return ReorderPayload(
      orderTypeIndex: _checkoutIndexFor(order.orderTypeId),
      deliveryAddressText: order.isDelivery ? order.deliveryAddress : null,
      deliveryLat: order.isDelivery ? order.deliveryLat : null,
      deliveryLng: order.isDelivery ? order.deliveryLng : null,
      branchName: order.branchName,
      comment: parsedNote.comment,
      carDetails: parsedNote.carDetails,
    );
  }

  /// Reverses the `comment + "\nCar Details: $carDetails"` format that the
  /// app writes when placing carhop orders, and strips known order-type
  /// prefixes/suffixes the app adds for non-carhop notes.
  _ParsedNote _parseNote(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _ParsedNote(comment: null, carDetails: null);
    }

    var body = raw;

    // Trailing "Payment Method: …" line is bookkeeping, not user-entered.
    final pmIdx = body.indexOf('\nPayment Method:');
    if (pmIdx >= 0) body = body.substring(0, pmIdx);

    String? carDetails;
    final cdIdx = body.indexOf('\nCar Details: ');
    if (cdIdx >= 0) {
      carDetails = body.substring(cdIdx + '\nCar Details: '.length).trim();
      body = body.substring(0, cdIdx);
    }

    // Strip in-restaurant / self-pickup prefixes the app prepends.
    for (final prefix in const ['В ресторане\n', 'С Сабой\n']) {
      if (body.startsWith(prefix)) {
        body = body.substring(prefix.length);
        break;
      }
    }
    // Bare prefix with no follow-up comment.
    for (final prefix in const ['В ресторане', 'С Сабой']) {
      if (body == prefix) {
        body = '';
        break;
      }
    }

    final comment = body.trim();
    return _ParsedNote(
      comment: comment.isEmpty ? null : comment,
      carDetails: (carDetails == null || carDetails.isEmpty) ? null : carDetails,
    );
  }

  int _checkoutIndexFor(int orderTypeId) {
    switch (orderTypeId) {
      case HistoryOrderType.delivery:
        return CheckoutOrderTypeIndex.delivery;
      case HistoryOrderType.selfPickup:
        return CheckoutOrderTypeIndex.selfPickup;
      case HistoryOrderType.carhop:
        return CheckoutOrderTypeIndex.carhop;
      case HistoryOrderType.dineIn:
        return CheckoutOrderTypeIndex.inRestaurant;
      default:
        return CheckoutOrderTypeIndex.delivery;
    }
  }

  /// Forget cached state, e.g. on logout.
  void clear() {
    _lastOrder = null;
    _state = ReorderLoadState.idle;
    _hasHistoryHint = false;
    notifyListeners();
  }
}

class _ParsedNote {
  final String? comment;
  final String? carDetails;

  const _ParsedNote({required this.comment, required this.carDetails});
}

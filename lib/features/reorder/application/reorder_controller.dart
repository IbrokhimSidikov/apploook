import 'package:flutter/widgets.dart';

import '../../../cart_provider.dart';
import '../data/reorder_repository.dart';
import '../domain/last_order.dart';
import '../domain/reorder_payload.dart';

enum ReorderLoadState { idle, loading, ready, empty, error }

class ReorderController extends ChangeNotifier with WidgetsBindingObserver {
  ReorderController({ReorderRepository? repository})
      : _repository = repository ?? ReorderRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  final ReorderRepository _repository;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Drop any staged reorder prefill when the user leaves the app. A
    // resume an hour later shouldn't silently apply an old prefill the
    // user has long forgotten about. `paused` fires when the app moves
    // to the background; `inactive` (incoming calls, notification
    // shade) is intentionally ignored so a brief interruption doesn't
    // wipe state.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pendingPrefill = null;
    }
  }

  ReorderLoadState _state = ReorderLoadState.idle;
  LastOrder? _lastOrder;
  bool _hasHistoryHint = false;

  /// Payload staged by the reorder bottom sheet so Cart can route the user
  /// through the cart page (recommendation upsell) before Checkout, while
  /// Checkout still receives the prefill once the user proceeds.
  /// Read once via [consumePrefill] — it auto-clears.
  ReorderPayload? _pendingPrefill;

  ReorderLoadState get state => _state;
  LastOrder? get lastOrder => _lastOrder;
  bool get hasPendingPrefill => _pendingPrefill != null;

  void stagePrefill(ReorderPayload payload) {
    _pendingPrefill = payload;
  }

  /// Returns the staged prefill (if any) and clears it. Intended to be
  /// called from Checkout.initState so the prefill fires exactly once.
  ReorderPayload? consumePrefill() {
    final p = _pendingPrefill;
    _pendingPrefill = null;
    return p;
  }

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
    _pendingPrefill = null;
    notifyListeners();
  }
}

class _ParsedNote {
  final String? comment;
  final String? carDetails;

  const _ParsedNote({required this.comment, required this.carDetails});
}

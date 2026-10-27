import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/services/loyalty_service.dart';

/// Checkout-side loyalty state.
///
/// The provider never does the pricing itself. Every figure it exposes came
/// from `/loyalty/quote`, because only the server knows the live balance,
/// the customer's tier and the crystal prices - and it recomputes them again
/// when the hold is created, so a tampered client cannot buy anything cheaper.
class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _service;

  LoyaltyProvider({LoyaltyService? service})
      : _service = service ?? LoyaltyService() {
    _bootstrap();
  }

  /// Answers "is there a session?" from local prefs the moment the provider
  /// exists - milliseconds, at app launch - then fetches the summary. By the
  /// time any screen shows the card, the state is long known, so the board
  /// paints on that screen's first frame instead of popping in after a gap.
  Future<void> _bootstrap() async {
    _hasSession = await _service.hasSession();
    _needsActivation = await _service.needsActivation();
    _sessionKnown = true;
    notifyListeners();
    await refresh(silent: true);
  }

  // Wallet -----------------------------------------------------------------

  LoyaltySummary _summary = LoyaltySummary.empty;
  bool _summaryLoaded = false;
  LoyaltyTierStatus? _tierStatus;
  bool _isLoadingSummary = false;
  bool _hasSession = false;
  bool _needsActivation = false;
  bool _isActivating = false;
  bool _sessionKnown = false;
  String? _error;

  LoyaltySummary get summary => _summary;

  /// Purchase-based level from `/loyalty/tier`, or null until it arrives
  /// (or when the request failed - the card's tier stands in then).
  LoyaltyTierStatus? get tierStatus => _tierStatus;

  /// The level shown to the customer as bronze / gold / diamond. Pricing
  /// keeps using [tier], the price list on the card.
  LoyaltyTier get levelTier => _tierStatus?.tier ?? card.tier;
  LoyaltyCard get card => _summary.card;
  LoyaltyProgram get program => _summary.program;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get hasSession => _hasSession;

  /// Signed in to the app, but no loyalty session yet. The provider resumes
  /// one automatically; the UI shows the card in an activating state meanwhile.
  bool get needsActivation => _needsActivation;

  /// A resume attempt is in flight.
  bool get isActivating => _isActivating;

  /// False only in the first instants after a cold start, before the local
  /// prefs read in [_bootstrap] has answered whether a session exists.
  bool get sessionKnown => _sessionKnown;

  /// True once a summary has actually arrived this session. Until then the
  /// figures in [summary] are the empty placeholder, and showing them would
  /// display a confident-looking 0 that is really "not fetched yet".
  bool get balanceLoaded => _summaryLoaded;

  /// Crystals the customer can spend right now, or null while that is
  /// unknown (no session, summary not loaded yet). Budget checks in the
  /// details page and the cart skip when null; the checkout quote still
  /// refuses an unaffordable basket.
  int? get crystalBudget =>
      _hasSession && _summaryLoaded ? _summary.card.spendable : null;

  /// Set when the last activation attempt failed, rather than the customer
  /// simply never having tried.
  String? get mintError => _service.lastMintError;
  String? get error => _error;

  // Checkout ---------------------------------------------------------------

  LoyaltyQuote? _quote;
  bool _isQuoting = false;
  LoyaltyHold? _hold;
  Timer? _debounce;
  int _quoteGeneration = 0;

  LoyaltyQuote? get quote => _quote;
  bool get isQuoting => _isQuoting;
  LoyaltyHold? get hold => _hold;

  /// The price list this customer buys from. Regular (A) until the card has
  /// loaded, which is also what the server assumes for a new card.
  LoyaltyTier get tier => card.tier;

  /// Soum one crystal is worth on the POS payment line.
  int get crystalRateSoum => program.crystalRateSoum;

  /// Crystals that will actually come off the card for this order.
  int get appliedCrystals => _quote?.appliedPoints ?? 0;

  /// [appliedCrystals] in soum - what the POS books as the crystal payment.
  int get appliedSoum => _quote?.appliedSoum ?? 0;

  /// Kept for the order builders that still speak in "points": the soum the
  /// crystal payment is worth.
  int get appliedPoints => appliedSoum;

  /// Soum still to pay with money for the lines the quote priced.
  int get payable => _quote?.payable ?? 0;

  /// Crystals this order will earn.
  int get projectedEarn => _quote?.projectedEarn ?? 0;

  /// Crystals missing to settle every crystal line; 0 when affordable.
  int get shortfall => _quote?.shortfall ?? 0;

  String? get blockedReason => _quote?.blockedReason;

  /// True when the server refused the basket as configured: not enough
  /// crystals, or a line that cannot be paid the way it is set. The order
  /// must not go out until the customer changes something.
  bool get orderBlocked => _quote?.isBlocked ?? false;

  /// The server's view of one cart line, by [CartItem.id].
  LoyaltyQuoteLine? lineQuote(int cartLineId) => _quote?.line('$cartLineId');

  // -------------------------------------------------------------------
  // Wallet
  // -------------------------------------------------------------------

  /// Establishes a session for a signed-in customer without one.
  ///
  /// This is what makes activation automatic. It runs from refresh() and
  /// beginCheckout(), so the first screen that needs the card obtains it; no
  /// button, no re-login. Returns true when a session exists afterwards.
  Future<bool> ensureSession() async {
    if (await _service.hasSession()) return true;
    if (!await _service.needsActivation()) return false;
    if (_isActivating) return false;

    _isActivating = true;
    notifyListeners();
    try {
      final ok = await _service.resumeSession();
      _hasSession = ok;
      _needsActivation = !ok;
      return ok;
    } finally {
      _isActivating = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool silent = false}) async {
    await ensureSession();
    _hasSession = await _service.hasSession();
    _needsActivation = await _service.needsActivation();
    if (!_hasSession) {
      debugPrint('Loyalty: no session '
          '(needsActivation=$_needsActivation) - nothing will be requested');
      _summary = LoyaltySummary.empty;
      _tierStatus = null;
      // `silent` suppresses the loading flicker, not the result: the profile
      // card switches between its activate and balance states off this, so it
      // must always be told.
      notifyListeners();
      return;
    }

    if (!silent) {
      _isLoadingSummary = true;
      _error = null;
      notifyListeners();
    }

    try {
      // Fetched together so the level and the balance land in the same
      // frame. A failed level request never blocks the card: the card's own
      // tier is shown until the next refresh.
      final tierStatus = _service
          .fetchTierStatus()
          .then<LoyaltyTierStatus?>((status) => status)
          // An expired session surfaces through fetchSummary below, which
          // shares the token, so this one never needs to throw.
          .catchError((Object e) {
        debugPrint('Loyalty: tier status unavailable: $e');
        return null;
      });
      _summary = await _service.fetchSummary();
      _tierStatus = await tierStatus ?? _tierStatus;
      _summaryLoaded = true;
      _error = null;
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      _summary = LoyaltySummary.empty;
      _summaryLoaded = false;
      _tierStatus = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<List<LoyaltyTransaction>> fetchHistory({int page = 1}) async {
    if (!await _service.hasSession()) return const [];
    try {
      return await _service.fetchTransactions(page: page);
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      notifyListeners();
      return const [];
    }
  }

  /// Mints the session right after the SMS code is accepted.
  Future<bool> startSession({
    required String phone,
    required String verificationCode,
  }) async {
    final ok = await _service.createSession(
      phone: phone,
      verificationCode: verificationCode,
    );
    if (ok) await refresh(silent: true);
    _hasSession = ok;
    _needsActivation = !ok;
    debugPrint('Loyalty: session mint ${ok ? "succeeded" : "FAILED"}');
    notifyListeners();
    return ok;
  }

  Future<void> endSession() async {
    await _service.endSession();
    _hasSession = false;
    _summary = LoyaltySummary.empty;
    _tierStatus = null;
    resetCheckout();
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // Checkout
  // -------------------------------------------------------------------

  List<CartItem> _items = const [];
  int _deliveryFee = 0;
  int _orderTypeId = 0;

  /// True unless the chosen order type is outside the programme (delivery).
  bool get orderTypeEligible => _quote?.orderTypeEligible ?? true;

  /// Builds the `lines` payload the quote and hold endpoints take.
  ///
  /// Each cart line becomes its inventory components - the product itself
  /// when it is linked to Sieves inventory, plus every selected modifier
  /// that is - with the line's quantity and payment choice. The bag
  /// ("Пакет") is left out: it is only charged on delivery, which is
  /// outside the programme anyway.
  static List<Map<String, dynamic>> linesFor(List<CartItem> items) {
    final lines = <Map<String, dynamic>>[];
    for (final item in items) {
      final dynamic product = item.product;
      if (product.name == 'Пакет') continue;
      final components = <Map<String, dynamic>>[];
      int? productSievesId;
      try {
        productSievesId = product.sievesId as int?;
      } catch (_) {
        productSievesId = null;
      }
      // Each component says what it is and what it costs in money, so the
      // server applies the same rule as CrystalPricing and the money price:
      // the product plus its paid add-ons; an included option (0 UZS) adds
      // nothing.
      if (productSievesId != null) {
        components.add({
          'inventory_id': productSievesId,
          'quantity': 1,
          'role': 'product',
          'money_price': (product.price as num).round(),
        });
      }
      for (final selected in item.selectedModifiers) {
        final id = selected.modifier.sievesId;
        if (id == null) continue;
        components.add({
          'inventory_id': id,
          'quantity': selected.quantity,
          'role': 'modifier',
          'money_price': selected.modifier.price.round(),
        });
      }
      lines.add({
        'line_id': '${item.id}',
        'quantity': item.quantity,
        'pay_with': item.payWithCrystals
            ? LoyaltyPayWith.crystal.code
            : LoyaltyPayWith.money.code,
        'money_total': item.totalPrice.round(),
        'items': components,
      });
    }
    return lines;
  }

  /// Called when the checkout screen opens, and again whenever the basket,
  /// the order type or the delivery fee changes.
  Future<void> beginCheckout({
    required List<CartItem> items,
    required int orderTypeId,
    int deliveryFee = 0,
  }) async {
    _items = List<CartItem>.from(items);
    _deliveryFee = deliveryFee;
    _orderTypeId = orderTypeId;
    await ensureSession();
    _hasSession = await _service.hasSession();
    _needsActivation = await _service.needsActivation();
    if (!_hasSession) {
      debugPrint('Loyalty: checkout skipped, no session token '
          '(needsActivation=$_needsActivation)');
      _quote = null;
      notifyListeners();
      return;
    }
    await _runQuote();
  }

  /// Flips one line between money and crystals and re-prices. The cart and
  /// the checkout both call this, so the basket is quoted from one place.
  Future<void> setLinePayWithCrystals(CartItem item, bool value) async {
    if (item.payWithCrystals == value) return;
    item.payWithCrystals = value;
    if (!value) {
      item.quotedCrystalPrice = null;
      item.quotedCrystalSoum = null;
    }
    notifyListeners();
    if (_orderTypeId <= 0) return; // not at checkout yet
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runQuote);
  }

  /// Re-prices the current basket, debounced. Call after any cart change.
  void requote() {
    if (_orderTypeId <= 0) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runQuote);
  }

  int get _subtotal =>
      _items.fold<int>(0, (sum, item) => sum + item.totalPrice.round());

  Future<void> _runQuote() async {
    if (!_hasSession || _items.isEmpty || _orderTypeId <= 0) {
      debugPrint('Loyalty: quote skipped '
          '(session=$_hasSession items=${_items.length} type=$_orderTypeId)');
      return;
    }

    final generation = ++_quoteGeneration;
    _isQuoting = true;
    notifyListeners();

    try {
      final result = await _service.quote(
        subtotal: _subtotal,
        orderTypeId: _orderTypeId,
        deliveryFee: _deliveryFee,
        lines: linesFor(_items),
      );
      // A slower earlier request must not overwrite a newer answer.
      if (generation != _quoteGeneration) return;
      _applyQuote(result);
      _error = null;
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      _quote = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (generation == _quoteGeneration) _isQuoting = false;
      notifyListeners();
    }
  }

  /// Stores the quote and copies each line's crystal price back onto the
  /// cart line, which is what the order builders price crystal lines at.
  void _applyQuote(LoyaltyQuote result) {
    _quote = result;
    for (final item in _items) {
      final line = result.line('${item.id}');
      if (line == null) continue;
      if (item.payWithCrystals && line.crystalPrice != null && line.problem == null) {
        item.quotedCrystalPrice = line.crystalPrice;
        item.quotedCrystalSoum = line.crystalPrice! * result.crystalRateSoum;
      } else {
        item.quotedCrystalPrice = null;
        item.quotedCrystalSoum = null;
      }
    }
  }

  /// Reserves the crystals. Run this BEFORE sending the order, and put the
  /// returned [LoyaltyHold.orderNoteRef] in the order comment - it is how
  /// the settlement job recognises the order when it comes back from the POS.
  ///
  /// Returns null when there is nothing to reserve, which is not an error:
  /// the caller should place the order normally.
  Future<LoyaltyHold?> reserve({String? externalOrderId}) async {
    if (!_hasSession || _items.isEmpty || _orderTypeId <= 0) {
      debugPrint('Loyalty: no hold '
          '(session=$_hasSession items=${_items.length} type=$_orderTypeId)');
      return null;
    }
    // Delivery is outside the programme: no hold, so the order goes out at
    // the normal price and books no crystals.
    if (!orderTypeEligible) {
      debugPrint('Loyalty: no hold - order type $_orderTypeId is excluded');
      return null;
    }
    if (appliedCrystals <= 0 && projectedEarn <= 0) {
      debugPrint('Loyalty: no hold - nothing to spend and nothing to earn');
      return null;
    }
    debugPrint(
        'Loyalty: reserving crystals=$appliedCrystals earn=$projectedEarn');

    try {
      _hold = await _service.createHold(
        subtotal: _subtotal,
        orderTypeId: _orderTypeId,
        deliveryFee: _deliveryFee,
        lines: linesFor(_items),
        externalOrderId: externalOrderId,
        idempotencyKey:
            'checkout-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      );
      return _hold;
    } on LoyaltyQuoteStaleException catch (e) {
      // The balance or the prices moved under us. Show the customer the
      // fresh numbers and let them confirm again rather than silently
      // changing the price.
      debugPrint('Loyalty: hold refused ${e.code}: ${e.message} '
          '(blocked=${e.quote?.blockedReason} spendable=${e.quote?.spendable} '
          'shortfall=${e.quote?.shortfall})');
      if (e.quote != null) _applyQuote(e.quote!);
      _error = e.code ?? 'crystals_changed';
      notifyListeners();
      rethrow;
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      notifyListeners();
      return null;
    }
  }

  /// The order was accepted: spend the crystals and book the pending earn.
  Future<void> confirm({String? externalOrderId, int? orderId}) async {
    final hold = _hold;
    if (hold == null) return;
    try {
      await _service.commitHold(
        hold.id,
        externalOrderId: externalOrderId,
        orderId: orderId,
      );
      _hold = null;
      resetCheckout();
      await refresh(silent: true);
    } catch (e) {
      // Leave the hold in place: its TTL releases the crystals automatically,
      // so a failed commit costs the customer nothing.
      debugPrint('LoyaltyProvider: commit failed $e');
      rethrow;
    }
  }

  /// The order failed or the customer backed out - hand the crystals straight
  /// back instead of waiting for the hold to time out.
  Future<void> abandon() async {
    final hold = _hold;
    _hold = null;
    if (hold == null) return;
    try {
      await _service.releaseHold(hold.id);
    } catch (e) {
      debugPrint('LoyaltyProvider: release failed, TTL will cover it: $e');
    }
    await refresh(silent: true);
  }

  void resetCheckout() {
    _debounce?.cancel();
    _quote = null;
    _isQuoting = false;
    _items = const [];
    _deliveryFee = 0;
    _orderTypeId = 0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

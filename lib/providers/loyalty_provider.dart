import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:apploook/models/loyalty.dart';
import 'package:apploook/services/loyalty_service.dart';

/// Checkout-side loyalty state.
///
/// The provider never does the arithmetic itself. Every figure it exposes came
/// from `/loyalty/quote`, because only the server knows the live balance and
/// the program rules - and it recomputes them again when the hold is created,
/// so a tampered client cannot buy anything cheaper.
class LoyaltyProvider extends ChangeNotifier {
  final LoyaltyService _service;

  LoyaltyProvider({LoyaltyService? service})
      : _service = service ?? LoyaltyService();

  // Wallet -----------------------------------------------------------------

  LoyaltySummary _summary = LoyaltySummary.empty;
  bool _isLoadingSummary = false;
  bool _hasSession = false;
  bool _needsActivation = false;
  bool _isActivating = false;
  String? _error;

  LoyaltySummary get summary => _summary;
  LoyaltyCard get card => _summary.card;
  LoyaltyProgram get program => _summary.program;
  bool get isLoadingSummary => _isLoadingSummary;
  bool get hasSession => _hasSession;

  /// Signed in to the app, but no cashback session yet. The provider resumes
  /// one automatically; the UI shows the card in an activating state meanwhile.
  bool get needsActivation => _needsActivation;

  /// A resume attempt is in flight.
  bool get isActivating => _isActivating;

  /// Set when the last activation attempt failed, rather than the customer
  /// simply never having tried.
  String? get mintError => _service.lastMintError;
  String? get error => _error;

  // Checkout ---------------------------------------------------------------

  LoyaltyQuote? _quote;
  int _requestedPoints = 0;
  bool _useCashback = false;
  bool _isQuoting = false;
  LoyaltyHold? _hold;
  Timer? _debounce;
  int _quoteGeneration = 0;

  LoyaltyQuote? get quote => _quote;
  int get requestedPoints => _requestedPoints;
  bool get useCashback => _useCashback;
  bool get isQuoting => _isQuoting;
  LoyaltyHold? get hold => _hold;

  /// Points that will actually come off this order.
  int get appliedPoints => _useCashback ? (_quote?.appliedPoints ?? 0) : 0;

  /// Cashback this order will earn, after the redemption is taken into account.
  int get projectedEarn => _quote?.projectedEarn ?? 0;

  int get maxRedeemable => _quote?.maxRedeemable ?? 0;

  /// True when there is a balance worth offering to spend on this basket.
  bool get canOfferCashback =>
      _hasSession && (_quote?.canRedeem ?? false) && card.isActive;

  String? get blockedReason => _quote?.blockedReason;

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
      _summary = await _service.fetchSummary();
      _error = null;
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      _summary = LoyaltySummary.empty;
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
    resetCheckout();
    notifyListeners();
  }

  // -------------------------------------------------------------------
  // Checkout
  // -------------------------------------------------------------------

  int _subtotal = 0;
  int _deliveryFee = 0;
  int _orderTypeId = 0;

  /// True unless the chosen order type is outside the programme (delivery).
  bool get orderTypeEligible => _quote?.orderTypeEligible ?? true;

  /// Called when the checkout screen opens, and again whenever the basket or
  /// the delivery fee changes.
  Future<void> beginCheckout({
    required int subtotal,
    required int orderTypeId,
    int deliveryFee = 0,
  }) async {
    // Changing order type changes eligibility, so any points the customer had
    // already dialled in must be dropped rather than carried across.
    if (orderTypeId != _orderTypeId) {
      _useCashback = false;
      _requestedPoints = 0;
    }
    _subtotal = subtotal;
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

  /// Toggles the "spend my cashback" switch. Turning it on spends the maximum
  /// by default, which is what customers almost always want.
  Future<void> setUseCashback(bool value) async {
    _useCashback = value;
    _requestedPoints = value ? (_quote?.maxRedeemable ?? 0) : 0;
    notifyListeners();
    await _runQuote();
  }

  /// Debounced so dragging the slider does not fire a request per pixel.
  void requestPoints(int points) {
    _requestedPoints = points.clamp(0, maxRedeemable);
    notifyListeners();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runQuote);
  }

  Future<void> _runQuote() async {
    if (!_hasSession || _subtotal <= 0 || _orderTypeId <= 0) {
      debugPrint('Loyalty: quote skipped '
          '(session=$_hasSession subtotal=$_subtotal type=$_orderTypeId)');
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
        requestedPoints: _useCashback ? _requestedPoints : 0,
      );
      // A slower earlier request must not overwrite a newer answer.
      if (generation != _quoteGeneration) return;

      _quote = result;
      // The server may have clamped us (balance moved, order shrank).
      if (_useCashback) _requestedPoints = result.appliedPoints;
      if (!result.canRedeem) {
        _useCashback = false;
        _requestedPoints = 0;
      }
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

  /// Reserves the points. Run this BEFORE sending the order, and put the
  /// returned [LoyaltyHold.orderNoteRef] in the order comment - it is how the
  /// settlement job recognises the order when it comes back from the POS.
  ///
  /// Returns null when there is nothing to reserve, which is not an error:
  /// the caller should place the order normally.
  Future<LoyaltyHold?> reserve({String? externalOrderId}) async {
    if (!_hasSession || _subtotal <= 0 || _orderTypeId <= 0) {
      debugPrint('Loyalty: no hold '
          '(session=$_hasSession subtotal=$_subtotal type=$_orderTypeId)');
      return null;
    }
    // Delivery is outside the programme: no hold, so the order goes out at the
    // normal price and books no cashback.
    if (!orderTypeEligible) {
      debugPrint('Loyalty: no hold - order type $_orderTypeId is excluded');
      return null;
    }
    if (!_useCashback && projectedEarn <= 0) {
      debugPrint('Loyalty: no hold - nothing to spend and nothing to earn');
      return null;
    }
    debugPrint('Loyalty: reserving points=$appliedPoints earn=$projectedEarn');

    try {
      _hold = await _service.createHold(
        subtotal: _subtotal,
        orderTypeId: _orderTypeId,
        deliveryFee: _deliveryFee,
        requestedPoints: appliedPoints,
        externalOrderId: externalOrderId,
        idempotencyKey:
            'checkout-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      );
      return _hold;
    } on LoyaltyQuoteStaleException catch (e) {
      // The balance moved under us. Show the customer the fresh numbers and
      // let them confirm again rather than silently changing the price.
      if (e.quote != null) {
        _quote = e.quote;
        _requestedPoints = e.quote!.appliedPoints;
      }
      _error = 'cashback_changed';
      notifyListeners();
      rethrow;
    } on LoyaltySessionExpiredException {
      _hasSession = false;
      notifyListeners();
      return null;
    }
  }

  /// The order was accepted: spend the points and book the pending cashback.
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
      // Leave the hold in place: its TTL releases the points automatically, so
      // a failed commit costs the customer nothing.
      debugPrint('LoyaltyProvider: commit failed $e');
      rethrow;
    }
  }

  /// The order failed or the customer backed out - hand the points straight
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
    _requestedPoints = 0;
    _useCashback = false;
    _isQuoting = false;
    _subtotal = 0;
    _deliveryFee = 0;
    _orderTypeId = 0;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

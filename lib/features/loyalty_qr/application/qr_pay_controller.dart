import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:apploook/features/loyalty_qr/data/loyalty_qr_repository.dart';
import 'package:apploook/features/loyalty_qr/domain/loyalty_qr_token.dart';
import 'package:apploook/models/loyalty.dart';

enum QrPayState { loading, showing, error, signedOut }

/// Keeps a live payment code on screen for as long as the page is visible.
///
/// A code only authorizes spending while it is fresh, so the controller
/// re-mints a few seconds before expiry - the cashier must never scan a dead
/// code. Minting stops the moment the app leaves the foreground: a code
/// nobody is showing is pure attack surface, and the backend supersedes the
/// old one on every mint anyway.
class QrPayController extends ChangeNotifier with WidgetsBindingObserver {
  final LoyaltyQrRepository _repository;

  QrPayController({LoyaltyQrRepository? repository})
      : _repository = repository ?? LoyaltyQrRepository();

  /// Re-mint when this few seconds remain, so the swap is invisible.
  static const int _refreshLeadSeconds = 8;

  QrPayState state = QrPayState.loading;
  LoyaltyQrToken? token;

  Timer? _ticker;
  bool _minting = false;
  bool _disposed = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    await _mint();
  }

  Future<void> retry() => _mint();

  Future<void> _mint() async {
    if (_minting) return;
    _minting = true;
    if (token == null || token!.isExpired) {
      state = QrPayState.loading;
      _safeNotify();
    }
    try {
      final fresh = await _repository.mint();
      if (_disposed) return;
      token = fresh;
      state = QrPayState.showing;
      _startTicker();
    } on LoyaltySessionExpiredException {
      if (_disposed) return;
      state = QrPayState.signedOut;
      _stopTicker();
    } catch (_) {
      if (_disposed) return;
      // Whatever is still on screen is stale or absent - show the retry
      // state rather than a code the till will reject.
      token = null;
      state = QrPayState.error;
      _stopTicker();
    } finally {
      _minting = false;
    }
    _safeNotify();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = token;
      if (current == null) return;
      if (current.secondsLeft <= _refreshLeadSeconds) {
        _mint();
      }
      // Every tick repaints the countdown.
      _safeNotify();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  // ignore: avoid_renaming_method_parameters - `state` is taken by the field.
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.paused) {
      _stopTicker();
    } else if (lifecycle == AppLifecycleState.resumed &&
        state != QrPayState.signedOut) {
      // The old code likely died while backgrounded - come back with a live one.
      _mint();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopTicker();
    super.dispose();
  }
}

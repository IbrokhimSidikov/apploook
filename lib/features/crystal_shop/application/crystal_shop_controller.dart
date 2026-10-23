import 'package:flutter/foundation.dart';

import 'package:apploook/models/loyalty.dart';
import 'package:apploook/providers/loyalty_provider.dart';
import '../data/crystal_shop_repository.dart';
import '../domain/crystal_shop_models.dart';

enum CrystalLoadState { idle, loading, ready, error, signedOut }

/// State for the Crystal Shop tab: the catalog and the leaderboard. Each
/// half loads on its own so the rankings tab is never blocked by a slow
/// shop fetch, and vice versa.
///
/// The crystal balance, tier and session come from [LoyaltyProvider], which
/// `main.dart` hands in through [attachLoyalty] (a
/// `ChangeNotifierProxyProvider`) every time the loyalty state changes.
/// The controller never keeps its own copy of the balance.
class CrystalShopController extends ChangeNotifier {
  CrystalShopController({CrystalShopRepository? repository})
      : _repository = repository ?? CrystalShopRepository();

  final CrystalShopRepository _repository;

  // Loyalty ---------------------------------------------------------------

  LoyaltyProvider? _loyalty;
  LoyaltyTier _catalogTier = LoyaltyTier.a;
  bool _hadSession = false;

  /// Called by the proxy provider whenever [LoyaltyProvider] notifies.
  /// Re-prices the catalog when the tier changes and re-fetches the
  /// leaderboard when a session appears or goes away.
  void attachLoyalty(LoyaltyProvider loyalty) {
    _loyalty = loyalty;
    final tierChanged =
        _shopState == CrystalLoadState.ready && loyalty.tier != _catalogTier;
    final sessionChanged = loyalty.hasSession != _hadSession;
    _hadSession = loyalty.hasSession;

    if (tierChanged) {
      _catalogTier = loyalty.tier;
      _sections = _repository.buildCatalog(_catalogTier);
    }
    if (sessionChanged && _rankingsState != CrystalLoadState.idle) {
      // Not awaited: it notifies on its own when the fetch answers.
      loadRankings(silent: true, force: true);
    }
    notifyListeners();
  }

  bool get hasSession => _loyalty?.hasSession ?? false;
  LoyaltyTier get tier => _loyalty?.tier ?? LoyaltyTier.a;

  /// Spendable crystals, or null while unknown (no session, or the summary
  /// has not arrived yet).
  int? get balance {
    final loyalty = _loyalty;
    if (loyalty == null || !loyalty.hasSession || !loyalty.balanceLoaded) {
      return null;
    }
    return loyalty.card.spendable;
  }

  /// True while the balance is genuinely still on its way, as opposed to
  /// unknown because there is no session.
  bool get balanceLoading {
    final loyalty = _loyalty;
    if (loyalty == null || !loyalty.sessionKnown) return true;
    return loyalty.hasSession &&
        !loyalty.balanceLoaded &&
        loyalty.error == null;
  }

  /// [inCart] is what the crystal lines already in the cart spend: the
  /// balance has to cover those and this item together.
  bool canAfford(CrystalShopItem item, {int inCart = 0}) {
    final b = balance;
    return b != null && b - inCart >= item.crystalPrice && item.available;
  }

  int shortfall(CrystalShopItem item, {int inCart = 0}) =>
      (item.crystalPrice - ((balance ?? 0) - inCart))
          .clamp(0, item.crystalPrice);

  // Shop ------------------------------------------------------------------

  CrystalLoadState _shopState = CrystalLoadState.idle;
  List<CrystalShopSection> _sections = const [];
  String? _shopError;

  CrystalLoadState get shopState => _shopState;
  List<CrystalShopSection> get sections => _sections;

  int get itemCount =>
      _sections.fold(0, (sum, section) => sum + section.items.length);
  String? get shopError => _shopError;

  Future<void> loadShop({bool silent = false}) async {
    if (_shopState == CrystalLoadState.loading) return;
    if (!silent || _shopState == CrystalLoadState.idle) {
      _shopState = CrystalLoadState.loading;
      notifyListeners();
    }
    try {
      await _repository.ensureMenuLoaded();
      _catalogTier = tier;
      _sections = _repository.buildCatalog(_catalogTier);
      _shopError = null;
      _shopState = CrystalLoadState.ready;
    } catch (e) {
      debugPrint('CRYSTALS: shop load failed: $e');
      _shopError = e.toString();
      _shopState = CrystalLoadState.error;
    }
    notifyListeners();
  }

  /// Pull-to-refresh: the catalog and, since the balance lives in
  /// [LoyaltyProvider], the wallet summary as well.
  Future<void> refreshShop() => Future.wait([
        loadShop(silent: true),
        if (_loyalty != null) _loyalty!.refresh(silent: true),
      ]);

  // Leaderboard -------------------------------------------------------------

  CrystalLoadState _rankingsState = CrystalLoadState.idle;
  CrystalLeaderboard _leaderboard = CrystalLeaderboard.empty;
  String? _rankingsError;

  CrystalLoadState get rankingsState => _rankingsState;
  List<CrystalRankingEntry> get rankings => _leaderboard.entries;
  String? get rankingsError => _rankingsError;

  /// The customer's own row: from the list when they are in it, else the
  /// separate `me` row the backend sends, else null.
  CrystalRankingEntry? get myRank {
    for (final e in _leaderboard.entries) {
      if (e.isMe) return e;
    }
    return _leaderboard.me;
  }

  Future<void> loadRankings({bool silent = false, bool force = false}) async {
    if (_rankingsState == CrystalLoadState.loading && !force) return;
    if (!hasSession) {
      _leaderboard = CrystalLeaderboard.empty;
      _rankingsError = null;
      _rankingsState = CrystalLoadState.signedOut;
      notifyListeners();
      return;
    }
    if (!silent || _rankingsState != CrystalLoadState.ready) {
      _rankingsState = CrystalLoadState.loading;
      notifyListeners();
    }
    try {
      _leaderboard = await _repository.fetchLeaderboard();
      _rankingsError = null;
      _rankingsState = CrystalLoadState.ready;
    } on LoyaltySessionExpiredException {
      _leaderboard = CrystalLeaderboard.empty;
      _rankingsError = null;
      _rankingsState = CrystalLoadState.signedOut;
    } catch (e) {
      debugPrint('CRYSTALS: leaderboard fetch failed: $e');
      _rankingsError = e.toString();
      _rankingsState = CrystalLoadState.error;
    }
    notifyListeners();
  }
}

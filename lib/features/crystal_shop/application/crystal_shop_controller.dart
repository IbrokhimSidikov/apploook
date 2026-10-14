import 'package:flutter/foundation.dart';

import 'package:apploook/widget/banner_item.dart';
import '../data/crystal_shop_repository.dart';
import '../domain/crystal_shop_models.dart';

enum CrystalLoadState { idle, loading, ready, error }

/// State for the Crystal Shop tab: the catalog, the leaderboard and the
/// customer's crystal balance. Each half loads on its own so the rankings
/// tab is never blocked by a slow shop fetch, and vice versa.
class CrystalShopController extends ChangeNotifier {
  CrystalShopController({CrystalShopRepository? repository})
      : _repository = repository ?? CrystalShopRepository();

  final CrystalShopRepository _repository;

  // Shop ------------------------------------------------------------------

  CrystalLoadState _shopState = CrystalLoadState.idle;
  CrystalShopCatalog _catalog = CrystalShopCatalog.empty;
  List<BannerItem> _banners = const [];
  bool _bannersLoading = true;
  int? _balance;
  String? _shopError;

  CrystalLoadState get shopState => _shopState;
  List<CrystalShopItem> get items => _catalog.items;
  List<BannerItem> get banners => _banners;
  bool get bannersLoading => _bannersLoading;

  /// Null until the backend has told us; the UI shows a shimmer meanwhile.
  int? get balance => _balance;
  String? get shopError => _shopError;

  bool canAfford(CrystalShopItem item) =>
      (_balance ?? 0) >= item.crystalPrice && item.available;

  int shortfall(CrystalShopItem item) =>
      (item.crystalPrice - (_balance ?? 0)).clamp(0, item.crystalPrice);

  Future<void> loadShop({bool silent = false}) async {
    if (_shopState == CrystalLoadState.loading) return;
    if (!silent || _shopState == CrystalLoadState.idle) {
      _shopState = CrystalLoadState.loading;
      notifyListeners();
    }
    try {
      _catalog = await _repository.fetchCatalog();
      _balance = _catalog.balance ?? _balance;
      _shopError = null;
      _shopState = CrystalLoadState.ready;
      notifyListeners();
      // Banners come second so the grid never waits on the promo images.
      _banners = await _repository.bannersFor(_catalog);
    } catch (e) {
      _shopError = e.toString();
      _shopState = CrystalLoadState.error;
    } finally {
      _bannersLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> loadRankings({bool silent = false}) async {
    if (_rankingsState == CrystalLoadState.loading) return;
    if (!silent || _rankingsState == CrystalLoadState.idle) {
      _rankingsState = CrystalLoadState.loading;
      notifyListeners();
    }
    try {
      _leaderboard = await _repository.fetchLeaderboard();
      _rankingsError = null;
      _rankingsState = CrystalLoadState.ready;
    } catch (e) {
      _rankingsError = e.toString();
      _rankingsState = CrystalLoadState.error;
    }
    notifyListeners();
  }

  // Redeem ----------------------------------------------------------------

  bool _isRedeeming = false;
  bool get isRedeeming => _isRedeeming;

  /// Spends crystals on [item]. Returns the redemption on success, null on
  /// failure; the balance shown in the UI is whatever the server answered.
  Future<CrystalRedemption?> redeem(CrystalShopItem item) async {
    if (_isRedeeming) return null;
    _isRedeeming = true;
    notifyListeners();
    try {
      final result = await _repository.redeem(item);
      // A negative balance is the debug stand-in saying "compute it here".
      _balance = result.balance >= 0
          ? result.balance
          : ((_balance ?? 0) - item.crystalPrice).clamp(0, 1 << 30);
      return result;
    } catch (e) {
      debugPrint('CRYSTALS: redeem error $e');
      return null;
    } finally {
      _isRedeeming = false;
      notifyListeners();
    }
  }
}

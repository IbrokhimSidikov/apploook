import 'package:apploook/models/crystal_pricing.dart';
import 'package:apploook/models/loyalty.dart';
import 'package:apploook/services/loyalty_service.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/widget/banner_item.dart';
import '../domain/crystal_shop_models.dart';

/// Data access for the Crystal Shop.
///
/// There is no `/crystals` backend: the catalog is the branch menu already
/// held by [MenuService], filtered to what is sold for crystals at the
/// customer's tier, and the leaderboard is `GET /loyalty/leaderboard` via
/// [LoyaltyService] (needs a loyalty session).
class CrystalShopRepository {
  CrystalShopRepository({LoyaltyService? loyalty, MenuService? menu})
      : _loyalty = loyalty ?? LoyaltyService(),
        _menu = menu ?? MenuService();

  final LoyaltyService _loyalty;
  final MenuService _menu;

  /// Makes sure the menu is in memory. The home tab normally loads it from
  /// `/branch/nearest` at launch; if the shop opens first, fall back to the
  /// cached copy the same way the home tab's `loadData` does. Throws when
  /// there is no menu at all, which the controller shows as an error with
  /// a retry.
  Future<void> ensureMenuLoaded() async {
    if (_menu.allProducts.isNotEmpty) return;
    await _menu.initialize();
    if (_menu.allProducts.isEmpty) {
      throw Exception('Menu is not loaded');
    }
  }

  /// Products sold for crystals at [tier]: crystal-only ones first, then by
  /// crystal price ascending.
  List<CrystalShopItem> buildCatalog(LoyaltyTier tier) {
    final items = <CrystalShopItem>[];
    for (final product in _menu.allProducts) {
      final price = CrystalPricing.productPrice(product, tier);
      if (!product.isCrystalOnly && price == null) continue;
      items.add(CrystalShopItem(product: product, crystalPrice: price ?? 0));
    }
    items.sort((a, b) {
      if (a.isCrystalOnly != b.isCrystalOnly) return a.isCrystalOnly ? -1 : 1;
      return a.crystalPrice.compareTo(b.crystalPrice);
    });
    return items;
  }

  /// Throws [LoyaltySessionExpiredException] without a session.
  Future<CrystalLeaderboard> fetchLeaderboard({int limit = 50}) async =>
      CrystalLeaderboard.fromJson(await _loyalty.fetchLeaderboard(limit: limit));

  /// The same promo set the home screen spins.
  Future<List<BannerItem>> banners() => BannerItem.getBanners();
}

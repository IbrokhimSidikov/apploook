/// Models for the Crystal Shop: rewards that are bought with crystals only,
/// and the global leaderboard of crystal collectors.
///
/// Mirrors the sieves-api-v3 `/crystals` responses. Crystal amounts are
/// whole numbers; nothing here parses a double.
library;

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

/// A reward that can be redeemed for crystals.
class CrystalShopItem {
  final String id;
  final String name;
  final String description;

  /// Either an http(s) URL or a bundled `images/...` asset path.
  final String imagePath;
  final int crystalPrice;

  /// Short label such as "Drinks" or "Combo", used as a tag on the card.
  final String category;
  final bool available;

  const CrystalShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.crystalPrice,
    this.category = '',
    this.available = true,
  });

  factory CrystalShopItem.fromJson(Map<String, dynamic> json) =>
      CrystalShopItem(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imagePath:
            (json['image_url'] ?? json['imageUrl'] ?? json['image'])?.toString() ??
                '',
        crystalPrice: _asInt(json['crystal_price'] ?? json['crystalPrice']),
        category: json['category']?.toString() ?? '',
        available: json['available'] is bool ? json['available'] as bool : true,
      );
}

/// Promotional banner shown in the shop carousel.
class CrystalShopBanner {
  final String name;
  final String imagePath;

  const CrystalShopBanner({required this.name, required this.imagePath});

  factory CrystalShopBanner.fromJson(Map<String, dynamic> json) =>
      CrystalShopBanner(
        name: json['name']?.toString() ?? '',
        imagePath:
            (json['image_url'] ?? json['imageUrl'] ?? json['imagePath'])
                    ?.toString() ??
                '',
      );
}

/// Everything the shop tab needs in one fetch.
class CrystalShopCatalog {
  final List<CrystalShopBanner> banners;
  final List<CrystalShopItem> items;

  /// The signed-in customer's crystal balance, or null when the backend did
  /// not include it (no session).
  final int? balance;

  const CrystalShopCatalog({
    required this.banners,
    required this.items,
    this.balance,
  });

  factory CrystalShopCatalog.fromJson(Map<String, dynamic> json) {
    final banners = (json['banners'] as List? ?? const [])
        .whereType<Map>()
        .map((b) => CrystalShopBanner.fromJson(b.cast<String, dynamic>()))
        .where((b) => b.imagePath.isNotEmpty)
        .toList();
    final items = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((i) => CrystalShopItem.fromJson(i.cast<String, dynamic>()))
        .toList();
    return CrystalShopCatalog(
      banners: banners,
      items: items,
      balance: json['balance'] == null ? null : _asInt(json['balance']),
    );
  }

  static const empty = CrystalShopCatalog(banners: [], items: []);
}

/// One row of the global leaderboard. Names only: the backend never sends a
/// phone number or any other identifier here.
class CrystalRankingEntry {
  final int rank;
  final String name;
  final int crystals;
  final bool isMe;

  const CrystalRankingEntry({
    required this.rank,
    required this.name,
    required this.crystals,
    this.isMe = false,
  });

  factory CrystalRankingEntry.fromJson(Map<String, dynamic> json) =>
      CrystalRankingEntry(
        rank: _asInt(json['rank']),
        name: json['name']?.toString() ?? '',
        crystals: _asInt(json['crystals']),
        isMe: json['is_me'] == true || json['isMe'] == true,
      );
}

class CrystalLeaderboard {
  final List<CrystalRankingEntry> entries;

  /// The customer's own row when they are outside [entries].
  final CrystalRankingEntry? me;

  const CrystalLeaderboard({required this.entries, this.me});

  factory CrystalLeaderboard.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List? ?? json['data'] as List? ?? [])
        .whereType<Map>()
        .map((e) => CrystalRankingEntry.fromJson(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
    final meJson = json['me'];
    return CrystalLeaderboard(
      entries: entries,
      me: meJson is Map
          ? CrystalRankingEntry.fromJson(meJson.cast<String, dynamic>())
          : null,
    );
  }

  static const empty = CrystalLeaderboard(entries: []);
}

/// Result of a successful redemption: the code to show at the counter and
/// the balance that remains.
class CrystalRedemption {
  final String code;
  final int balance;

  const CrystalRedemption({required this.code, required this.balance});

  factory CrystalRedemption.fromJson(Map<String, dynamic> json) =>
      CrystalRedemption(
        code: json['code']?.toString() ?? '',
        balance: _asInt(json['balance']),
      );
}

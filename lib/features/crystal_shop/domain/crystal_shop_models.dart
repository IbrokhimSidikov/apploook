/// Models for the Crystal Shop: menu products that can be bought with
/// crystals, and the global leaderboard of crystal collectors.
///
/// The catalog is derived from the branch menu already in [MenuService];
/// the leaderboard mirrors the sieves-api-v3 `/loyalty/leaderboard`
/// response. Crystal amounts are whole numbers; nothing here parses a double.
library;

import 'dart:convert';

import 'package:apploook/pages/homenew.dart' show Product;

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

/// A menu product offered for crystals, priced at the customer's tier.
class CrystalShopItem {
  final Product product;

  /// Crystal price of one unit at the customer's tier. Zero when the
  /// product is crystal-only but carries no price for that tier; the server
  /// re-prices the line at checkout either way.
  final int crystalPrice;

  const CrystalShopItem({required this.product, required this.crystalPrice});

  String get id => product.uuid.isNotEmpty ? product.uuid : '${product.id}';
  String get name => product.name;
  String get imagePath => product.imagePath ?? '';

  /// Short label such as "Drinks" or "Combo", used as a tag on the card.
  String get category => product.categoryTitle;

  bool get isCrystalOnly => product.isCrystalOnly;
  bool get available => !product.outOfStock;

  /// Products with modifier groups go through the details page so the
  /// customer can configure them before the line lands in the cart.
  bool get needsConfiguration => product.modifierGroups.isNotEmpty;

  /// The description in [languageCode]. The menu sends it either as a map
  /// of language codes, as that map encoded in a JSON string, or as plain
  /// text; same handling as the details page.
  String descriptionFor(String languageCode) {
    final raw = product.description;
    if (raw == null) return '';
    if (raw is Map) return raw[languageCode]?.toString() ?? '';
    final text = raw.toString().trim();
    if (text.startsWith('{')) {
      try {
        final decoded = json.decode(text);
        if (decoded is Map) return decoded[languageCode]?.toString() ?? '';
      } catch (_) {
        // Not JSON after all; fall through to the raw text.
      }
    }
    return text;
  }
}

/// One menu category's worth of [CrystalShopItem]s, shown under its own
/// heading in the shop.
class CrystalShopSection {
  final int categoryId;
  final String title;
  final List<CrystalShopItem> items;

  const CrystalShopSection({
    required this.categoryId,
    required this.title,
    required this.items,
  });
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

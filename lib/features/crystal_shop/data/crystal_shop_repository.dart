import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:http/http.dart' as http;

import 'package:apploook/services/loyalty_service.dart';
import 'package:apploook/widget/banner_item.dart';
import '../domain/crystal_shop_models.dart';

/// HTTP client for the sieves-api-v3 `/crystals` endpoints.
///
/// Contract the app expects (all JSON):
///
/// * `GET  /crystals/shop`        -> `{ balance?, banners: [...], items: [...] }`
/// * `GET  /crystals/leaderboard` -> `{ entries: [{rank, name, crystals, is_me}], me? }`
/// * `POST /crystals/redeem`      -> `{ code, balance }`, body `{ item_id }`
///
/// Public reads send the static client token; anything tied to the customer
/// also sends the loyalty session token, same as the cashback endpoints.
///
/// The backend side of this is not deployed yet. Until it is, debug builds
/// fall back to [_sampleCatalog] / [_sampleLeaderboard] when the request
/// fails so the screens can be reviewed; release builds show the empty
/// states instead.
class CrystalShopRepository {
  CrystalShopRepository({LoyaltyService? loyalty})
      : _loyalty = loyalty ?? LoyaltyService();

  final LoyaltyService _loyalty;

  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const Duration _timeout = Duration(seconds: 15);

  Future<Map<String, String>> _headers() async {
    final token = await _loyalty.currentToken();
    return {
      'Content-Type': 'application/json',
      'x-upload-token': LoyaltyService.staticToken,
      if (token != null) 'x-loyalty-token': token,
    };
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    late http.Response response;
    try {
      response =
          await http.get(uri, headers: await _headers()).timeout(_timeout);
    } on SocketException {
      throw Exception('No connection');
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    late http.Response response;
    try {
      response = await http
          .post(uri, headers: await _headers(), body: json.encode(body))
          .timeout(_timeout);
    } on SocketException {
      throw Exception('No connection');
    }
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message']?.toString() ?? response.body)
          : response.body;
      throw Exception(
          'Crystal request failed (${response.statusCode}): $message');
    }
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{'data': decoded};
  }

  // -------------------------------------------------------------------
  // Endpoints
  // -------------------------------------------------------------------

  Future<CrystalShopCatalog> fetchCatalog() async {
    try {
      return CrystalShopCatalog.fromJson(await _get('/crystals/shop'));
    } catch (e) {
      debugPrint('CRYSTALS: shop fetch failed: $e');
      if (kDebugMode) return _sampleCatalog();
      rethrow;
    }
  }

  Future<CrystalLeaderboard> fetchLeaderboard({int limit = 50}) async {
    try {
      return CrystalLeaderboard.fromJson(
          await _get('/crystals/leaderboard?limit=$limit'));
    } catch (e) {
      debugPrint('CRYSTALS: leaderboard fetch failed: $e');
      if (kDebugMode) return _sampleLeaderboard();
      rethrow;
    }
  }

  Future<CrystalRedemption> redeem(CrystalShopItem item) async {
    try {
      return CrystalRedemption.fromJson(
          await _post('/crystals/redeem', {'item_id': item.id}));
    } catch (e) {
      debugPrint('CRYSTALS: redeem failed: $e');
      if (kDebugMode) {
        // Debug-only stand-in so the success flow can be walked through.
        await Future.delayed(const Duration(milliseconds: 600));
        return CrystalRedemption(
          code: 'LK-${item.id.hashCode.toRadixString(36).toUpperCase()}',
          balance: -1,
        );
      }
      rethrow;
    }
  }

  /// Carousel banners: the shop's own when the backend sends any, otherwise
  /// the same promo set the home screen spins.
  Future<List<BannerItem>> bannersFor(CrystalShopCatalog catalog) async {
    if (catalog.banners.isNotEmpty) {
      return [
        for (final b in catalog.banners)
          BannerItem(name: b.name, imagePath: b.imagePath, boxColor: const Color(0xFFFFFFFF)),
      ];
    }
    return BannerItem.getBanners();
  }

  // -------------------------------------------------------------------
  // Debug samples (never used in release builds)
  // -------------------------------------------------------------------

  CrystalShopCatalog _sampleCatalog() => const CrystalShopCatalog(
        balance: 42,
        banners: [],
        items: [
          CrystalShopItem(
            id: 'sample-latte',
            name: 'Latte',
            description: 'A warm latte on the house. Any size.',
            imagePath: 'images/latte.png',
            crystalPrice: 25,
            category: 'Drinks',
          ),
          CrystalShopItem(
            id: 'sample-vafli',
            name: 'Waffle',
            description: 'Crispy waffle with a topping of your choice.',
            imagePath: 'images/Vafli.png',
            crystalPrice: 30,
            category: 'Dessert',
          ),
          CrystalShopItem(
            id: 'sample-soda',
            name: 'Soda 0.5L',
            description: 'Any cold drink from the fridge.',
            imagePath: 'images/sodass.png',
            crystalPrice: 15,
            category: 'Drinks',
          ),
          CrystalShopItem(
            id: 'sample-combo',
            name: 'Combo',
            description: 'A full combo meal, crystals only.',
            imagePath: 'images/Combo.png',
            crystalPrice: 120,
            category: 'Combo',
          ),
          CrystalShopItem(
            id: 'sample-3in1',
            name: '3 in 1',
            description: 'Three favourites in one box.',
            imagePath: 'images/3in1.png',
            crystalPrice: 90,
            category: 'Combo',
          ),
          CrystalShopItem(
            id: 'sample-smile',
            name: 'Smile Set',
            description: 'The kids set with a surprise inside.',
            imagePath: 'images/Smile Set.png',
            crystalPrice: 60,
            category: 'Kids',
          ),
        ],
      );

  CrystalLeaderboard _sampleLeaderboard() {
    const names = [
      'Aziz', 'Malika', 'Jasur', 'Nilufar', 'Bobur', 'Dilnoza', 'Sardor',
      'Kamola', 'Umid', 'Zarina', 'Temur', 'Sevara', 'Otabek', 'Madina',
      'Shahzod',
    ];
    final entries = <CrystalRankingEntry>[
      for (var i = 0; i < names.length; i++)
        CrystalRankingEntry(
          rank: i + 1,
          name: names[i],
          crystals: 980 - i * 61,
          isMe: i == 6,
        ),
    ];
    return CrystalLeaderboard(entries: entries);
  }
}

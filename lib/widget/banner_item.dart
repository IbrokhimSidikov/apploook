import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BannerItem {
  String name;
  String imagePath;
  Color boxColor;

  static const String _cacheKey = 'cached_banners';
  static const Duration _cacheDuration = Duration(hours: 1);

  BannerItem({
    required this.name,
    required this.imagePath,
    required this.boxColor,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      name: json['name'] ?? '',
      imagePath: json['imagePath'] ?? '',
      boxColor: Color(int.parse(json['boxColor'] ?? 'FFffffff', radix: 16)),
    );
  }

  static Future<List<BannerItem>> getBanners() async {
    try {
      // Try to get cached data first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt('${_cacheKey}_time');

      // Check if cache is valid
      if (cachedData != null && cacheTime != null) {
        final cacheAge = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(cacheTime),
        );
        if (cacheAge < _cacheDuration) {
          final List<dynamic> bannersData = json.decode(cachedData);
          return bannersData.map((data) => BannerItem.fromJson(data)).toList();
        }
      }

      // If no valid cache, fetch from GitHub
      final response = await http.get(
        Uri.parse(
            'https://raw.githubusercontent.com/IbrokhimSidikov/BannerItem/main/main/banners.json'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Apploook-App', // Add your app name here
        },
      );

      if (response.statusCode == 200) {
        // Cache the new data
        await prefs.setString(_cacheKey, response.body);
        await prefs.setInt(
            '${_cacheKey}_time', DateTime.now().millisecondsSinceEpoch);

        List<dynamic> bannersData = json.decode(response.body);
        return bannersData.map((data) => BannerItem.fromJson(data)).toList();
      }

      print(
          'Failed to load banners: ${response.statusCode} - ${response.body}');
      return _getDefaultBanners();
    } catch (e) {
      print('Error loading banners: $e');
      return _getDefaultBanners();
    }
  }

  // Default banners as fallback
  static List<BannerItem> _getDefaultBanners() {
    return [
      BannerItem(
        name: 'banner12',
        imagePath: 'images/DinnerMBanner.png',
        boxColor: Colors.white,
      ),
      BannerItem(
        name: 'banner1',
        imagePath: 'images/SmileSetBanner.png',
        boxColor: Colors.white,
      ),
      BannerItem(
        name: 'banner1',
        imagePath: 'images/Aralash-tovuqlar.png',
        boxColor: Colors.white,
      ),
      BannerItem(
        name: 'banner1',
        imagePath: 'images/ComboBanner.png',
        boxColor: Colors.white,
      ),
      BannerItem(
        name: 'banner1',
        imagePath: 'images/banner3.png',
        boxColor: Colors.white,
      ),
      BannerItem(
        name: 'banner1',
        imagePath: 'images/banner4.png',
        boxColor: Colors.white,
      ),
    ];
  }
}

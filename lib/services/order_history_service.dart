import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryService {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const String _cacheKey = 'order_history_cache';
  static const String _cacheTimestampKey = 'order_history_cache_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  Map<String, dynamic>? _memoryCache;
  DateTime? _memoryCacheTimestamp;

  Future<String?> _getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    var phoneNumber = prefs.getString('phoneNumber');
    if (phoneNumber != null && phoneNumber.startsWith('+')) {
      phoneNumber = phoneNumber.substring(1);
    }
    if (phoneNumber != null && phoneNumber.startsWith('998')) {
      phoneNumber = phoneNumber.substring(3);
    }
    return phoneNumber;
  }

  Future<Map<String, dynamic>> fetchOrderHistory({
    int page = 1,
    int limit = 5,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedData = await _getCachedData();
      if (cachedData != null) {
        print('Returning cached order history: ${cachedData['data']?.length ?? 0} orders');
        return cachedData;
      }
    }

    try {
      final phoneNumber = await _getPhoneNumber();
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number not found. Please log in again.');
      }

      final url = Uri.parse(
        '$_baseUrl/orders/search-by-phone?phone=$phoneNumber&page=$page&limit=$limit',
      );

      print('Fetching order history from: $url');

      final response = await http.get(url);

      print('Order history response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('Order history raw response: $responseBody');
        
        final data = json.decode(responseBody) as Map<String, dynamic>;
        print('Order history parsed data: $data');
        print('Order history fetched successfully: ${data['data']?.length ?? 0} orders');
        
        await _cacheData(data);
        
        return data;
      } else {
        print('Failed to fetch order history: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch order history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order history: $e');
      
      final cachedData = await _getCachedData(ignoreExpiration: true);
      if (cachedData != null) {
        print('Network error, returning stale cache');
        return cachedData;
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getCachedData({bool ignoreExpiration = false}) async {
    if (_memoryCache != null && _memoryCacheTimestamp != null) {
      if (ignoreExpiration || DateTime.now().difference(_memoryCacheTimestamp!) < _cacheDuration) {
        print('Using in-memory cache');
        return _memoryCache;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestampMs = prefs.getInt(_cacheTimestampKey);

      if (cachedJson != null && timestampMs != null) {
        final cacheTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final cacheAge = DateTime.now().difference(cacheTimestamp);

        if (ignoreExpiration || cacheAge < _cacheDuration) {
          final data = json.decode(cachedJson) as Map<String, dynamic>;
          _memoryCache = data;
          _memoryCacheTimestamp = cacheTimestamp;
          print('Using persistent cache (age: ${cacheAge.inMinutes} minutes)');
          return data;
        } else {
          print('Cache expired (age: ${cacheAge.inMinutes} minutes)');
        }
      }
    } catch (e) {
      print('Error reading cache: $e');
    }

    return null;
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    try {
      _memoryCache = data;
      _memoryCacheTimestamp = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
      print('Data cached successfully');
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      _memoryCache = null;
      _memoryCacheTimestamp = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('Cache cleared successfully');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Map<String, dynamic> parseOrder(Map<String, dynamic> orderData) {
    return {
      'id': orderData['id'],
      'delivery_fee': orderData['delivery_fee'],
      'time': orderData['time'],
      'order_type_id': orderData['order_type_id'],
      'status_name': orderData['status_name'],
      'value': orderData['value'],
      'branch_name': orderData['branch_name'],
      'order_items': orderData['order_items'],
    };
  }

  String getOrderTypeName(int orderTypeId) {
    switch (orderTypeId) {
      case 1:
        return 'Delivery';
      case 2:
        return 'Carhop';
      case 3:
        return 'Self-Pickup';
      case 4:
        return 'Dine-In';
      default:
        return 'Unknown';
    }
  }
}

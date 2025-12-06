import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistoryService {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';

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
    int limit = 10,
  }) async {
    try {
      final phoneNumber = await _getPhoneNumber();
      
      if (phoneNumber == null || phoneNumber.isEmpty) {
        throw Exception('Phone number not found. Please log in again.');
      }

      final url = Uri.parse(
        '$_baseUrl/orders/search-by-phone?phone=$phoneNumber&page=$page&limit=10',
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
        
        return data;
      } else {
        print('Failed to fetch order history: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch order history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order history: $e');
      rethrow;
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

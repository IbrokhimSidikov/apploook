import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/services/api_service.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class OrderTrackingService {
  // Singleton instance
  static final OrderTrackingService _instance = OrderTrackingService._internal();
  
  // Track whether there are new unread orders
  bool _hasNewOrders = false;
  
  // API service instance
  late final ApiService _apiService;
  
  // Factory constructor
  factory OrderTrackingService({ApiService? apiService}) {
    if (apiService != null) {
      _instance._apiService = apiService;
    }
    return _instance;
  }
  
  // Private constructor
  OrderTrackingService._internal() {
    _apiService = ApiService(
      clientId: FirebaseRemoteConfig.instance.getString('api_client_id'),
      clientSecret: FirebaseRemoteConfig.instance.getString('api_client_secret'),
    );
  }
  
  // Getter for new orders flag
  bool get hasNewOrders => _hasNewOrders;
  
  // Mark a new order as added
  void markNewOrderAdded() {
    _hasNewOrders = true;
  }
  
  // Mark orders as read when user visits the tracking page
  void markOrdersAsRead() {
    _hasNewOrders = false;
  }

  // Get all saved delivery orders from SharedPreferences
  Future<List<Map<String, dynamic>>> getSavedDeliveryOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedOrders = prefs.getStringList('delivery_orders') ?? [];
      
      return savedOrders
          .map((order) => jsonDecode(order) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error getting saved delivery orders: $e');
      return [];
    }
  }

  // Update the status of a specific order
  Future<Map<String, dynamic>> updateOrderStatus(String orderId) async {
    try {
      print('OrderTrackingService: Updating status for order ID: $orderId');
      
      // Fetch the latest status from the API
      print('OrderTrackingService: Calling API service to get order status');
      final statusResponse = await _apiService.getOrderStatus(orderId);
      print('OrderTrackingService: Raw API response: $statusResponse');
      
      // Extract the status from the response
      String status = 'unknown';
      
      // Parse the API response
      print('OrderTrackingService: Parsing API response for status fields');
      if (statusResponse.containsKey('status')) {
        status = statusResponse['status'];
        print('ORDER TRACKING: OrderTrackingService: Found status field: $status');
      } else if (statusResponse.containsKey('orderStatus')) {
        status = statusResponse['orderStatus'];
        print('ORDER TRACKING: OrderTrackingService: Found orderStatus field: $status');
      } else if (statusResponse.containsKey('state')) {
        status = statusResponse['state'];
        print('ORDER TRACKING: OrderTrackingService: Found state field: $status');
      } else if (statusResponse.containsKey('deliveryStatus')) {
        status = statusResponse['deliveryStatus'];
        print('ORDER TRACKING: OrderTrackingService: Found deliveryStatus field: $status');
      } else if (statusResponse.containsKey('error')) {
        status = 'error';
        print('ORDER TRACKING: OrderTrackingService: Found error field: ${statusResponse['error']}');
      }
      
      // Log all fields in the response for debugging
      print('ORDER TRACKING: OrderTrackingService: All response fields:');
      statusResponse.forEach((key, value) {
        print('ORDER TRACKING: OrderTrackingService: Field $key = $value');
      });
      
      // Update the cached order with the new status
      final prefs = await SharedPreferences.getInstance();
      final savedOrders = prefs.getStringList('delivery_orders') ?? [];
      List<String> updatedOrders = [];
      bool orderFound = false;
      
      print('ORDER TRACKING: OrderTrackingService: Found ${savedOrders.length} cached orders');
      
      for (var orderJson in savedOrders) {
        final order = jsonDecode(orderJson);
        if (order['id'] == orderId) {
          orderFound = true;
          print('ORDER TRACKING: OrderTrackingService: Updating cached order: ${order['id']}');
          print('ORDER TRACKING: OrderTrackingService: Old status: ${order['status']}');
          print('ORDER TRACKING: OrderTrackingService: New status: $status');
          
          // Update the order with new status and timestamp
          order['status'] = status;
          order['statusDetails'] = statusResponse;
          order['lastUpdated'] = DateTime.now().toIso8601String();
          
          updatedOrders.add(jsonEncode(order));
        } else {
          updatedOrders.add(orderJson);
        }
      }
      
      if (orderFound) {
        await prefs.setStringList('delivery_orders', updatedOrders);
        print('ORDER TRACKING: OrderTrackingService: Cache updated with new status');
      } else {
        print('ORDER TRACKING: OrderTrackingService: Order not found in cache: $orderId');
        print('ORDER TRACKING: OrderTrackingService: Available order IDs in cache:');
        for (var orderJson in savedOrders) {
          final order = jsonDecode(orderJson);
          print('ORDER TRACKING: OrderTrackingService: - ${order['id']}');
        }
      }
      
      final result = {
        'status': status,
        'statusDetails': statusResponse,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('ORDER TRACKING: OrderTrackingService: Returning result: $result');
      return result;
    } catch (e) {
      print('ORDER TRACKING: OrderTrackingService: Error updating order status: $e');
      print('ORDER TRACKING: OrderTrackingService: Error type: ${e.runtimeType}');
      print('ORDER TRACKING: OrderTrackingService: Stack trace: ${StackTrace.current}');
      return {'error': e.toString(), 'status': 'unknown'};
    }
  }

  // Get the status of a specific order (first from cache, then update from API)
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      print('OrderTrackingService: Getting status for order ID: $orderId');
      
      // First get the cached order
      final prefs = await SharedPreferences.getInstance();
      final savedOrders = prefs.getStringList('delivery_orders') ?? [];
      
      Map<String, dynamic>? cachedOrder;
      
      for (var orderJson in savedOrders) {
        final order = jsonDecode(orderJson) as Map<String, dynamic>;
        if (order['id'] == orderId) {
          cachedOrder = order;
          print('OrderTrackingService: Found cached order: ${order['id']}');
          print('OrderTrackingService: Current cached status: ${order['status']}');
          break;
        }
      }
      
      if (cachedOrder == null) {
        print('OrderTrackingService: Order $orderId not found in cache');
        throw Exception('Order not found in cache');
      }
      
      // Then update from API
      print('OrderTrackingService: Requesting fresh status from API for order: $orderId');
      final updatedStatus = await updateOrderStatus(orderId);
      print('OrderTrackingService: API returned updated status: $updatedStatus');
      
      // Return the cached order with updated status
      final result = {
        ...cachedOrder,
        'status': updatedStatus['status'] ?? cachedOrder['status'],
        'statusDetails': updatedStatus,
      };
      
      print('OrderTrackingService: Returning final status data: $result');
      return result;
    } catch (e) {
      print('OrderTrackingService: Error getting order status: $e');
      return {'error': e.toString(), 'status': 'unknown'};
    }
  }
  
  // Clear all saved orders from SharedPreferences
  Future<bool> clearAllOrders() async {
    try {
      print('OrderTrackingService: Clearing all saved orders');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('delivery_orders');
      print('OrderTrackingService: All delivery orders cleared successfully');
      return true;
    } catch (e) {
      print('OrderTrackingService: Error clearing orders: $e');
      return false;
    }
  }
}

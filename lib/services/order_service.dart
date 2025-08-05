import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/config/branch_config.dart';
import 'package:apploook/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class OrderService {
  // Singleton pattern
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  /// Send a carhop order to the Sieves API
  Future<void> sendCarhopOrder({
    required String name,
    required String phone,
    required String paymentType,
    required String comment,
    required String carDetails,
    required CartProvider cartProvider,
    required BuildContext context,
  }) async {
    try {
      // Validate cart items
      if (cartProvider.cartItems.isEmpty) {
        throw Exception('Cart is empty');
      }

      // Check for invalid product IDs
      for (var item in cartProvider.cartItems) {
        if (item.product.id == null || item.product.id == 0) {
          throw Exception('Invalid product ID found in cart');
        }
      }

      // Get branch config for API credentials
      final branchConfig = BranchConfigs.getConfig('Test');

      // Calculate total order amount from cart items
      double total = 0;
      for (var item in cartProvider.cartItems) {
        total += item.product.price * item.quantity;
      }

      // Format order items - Using UUID instead of ID for testing
      // This avoids the "inventoryPriceList of non object is absent" error
      final List<Map<String, dynamic>> orderItems =
          cartProvider.cartItems.map((item) {
        // Use UUID for product_id as required by the API
        final String? productUuid = item.product.uuid;
        if (productUuid == null || productUuid.isEmpty) {
          print('WARNING: Missing UUID for product ${item.product.name} (ID: ${item.product.id})');
        }
        final String productIdentifier = productUuid ?? item.product.id.toString();
        print('Using product identifier: $productIdentifier for ${item.product.name}');
        
        return {
          "actual_price": item.product.price,
          "product_id": productIdentifier,
          "quantity": item.quantity,
          "note": null
        };
      }).toList();

      // Build request body following the exact structure from the example payload
      final Map<String, dynamic> requestBody = {
        "customer_quantity": 1,
        "customer_id": null,
        "is_fast": 0,
        "queue_type": "sync",
        "start_time": "now",
        "isSynchronous": "sync",
        "delivery_employee_id": null,
        "employee_id": branchConfig.employeeId,
        "branch_id": branchConfig.branchId,
        "order_type_id": 8, // for carhop - zakas s parkovki
        "orderItems": orderItems,
        "transactions": [
          {
            "account_id": 1,
            "amount": total,
            "payment_type_id": paymentType.toLowerCase() == 'card' ? 1 : 2,
            "type": "deposit"
          }
        ],
        "value": total,
        "note": comment +
            (carDetails.isNotEmpty ? "\nCar Details: $carDetails" : ""),
        "day_session_id": null,
        "pager_number": phone,
        "pos_id": null,
        "pos_session_id": null,
        "delivery_amount": null
      };

      // Debug logging
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      print('\n===== CARHOP ORDER REQUEST =====');
      print(
          'URL: https://app.sievesapp.com/v1/order?code=${branchConfig.sievesApiCode}');
      print('Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${branchConfig.sievesApiToken}',
        'Accept': 'application/json',
      }}');
      print('Request Body: \n${encoder.convert(requestBody)}');

      // Example of working Postman payload for comparison
      final Map<String, dynamic> postmanExample = {
        "customer_quantity": 1,
        "customer_id": null,
        "is_fast": 0,
        "queue_type": "sync",
        "start_time": "now",
        "isSynchronous": "sync",
        "delivery_employee_id": null,
        "employee_id": "1",
        "branch_id": "1",
        "order_type_id": 8,
        "orderItems": [
          {
            "actual_price": 25000,
            "product_id": "307",
            "quantity": 1,
            "note": null
          }
        ],
        "transactions": [
          {
            "account_id": 1,
            "amount": 25000,
            "payment_type_id": 2,
            "type": "deposit"
          }
        ],
        "value": 25000,
        "note": "Test order",
        "day_session_id": null,
        "pager_number": "123456789",
        "pos_id": null,
        "pos_session_id": null,
        "delivery_amount": null
      };

      print('\n===== DIFFERENCES BETWEEN PAYLOADS =====');
      print('Comparing Flutter payload with Postman example:');

      // Compare key fields
      print(
          'employee_id: Flutter=${requestBody["employee_id"]} vs Postman=${postmanExample["employee_id"]}');
      print(
          'branch_id: Flutter=${requestBody["branch_id"]} vs Postman=${postmanExample["branch_id"]}');
      print(
          'orderItems structure: Flutter=${encoder.convert(requestBody["orderItems"].first)} vs Postman=${encoder.convert(postmanExample["orderItems"].first)}');
      print(
          'transactions structure: Flutter=${encoder.convert(requestBody["transactions"].first)} vs Postman=${encoder.convert(postmanExample["transactions"].first)}');
      print('================================\n');

      // Send the request
      final response = await http.post(
        Uri.parse(
            'https://app.sievesapp.com/v1/order?code=${branchConfig.sievesApiCode}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${branchConfig.sievesApiToken}',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Check result
      if (response.statusCode != 200) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send carhop order: ${response.body}');
      }

      print("Carhop order sent successfully! Response: ${response.body}");

      // Parse the response and save order details
      final responseData = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // Get existing orders or initialize empty list
      List<String> savedOrders = prefs.getStringList('carhop_orders') ?? [];

      // Create new order object
      Map<String, dynamic> orderDetails = {
        'id': responseData['id'],
        'paid': responseData['paid'],
        'timestamp': DateTime.now().toIso8601String(),
        'orderItems': cartProvider.cartItems
            .map((item) => {
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.price,
                  'carDetails': carDetails
                })
            .toList(),
      };

      // Add new order to the list
      savedOrders.add(jsonEncode(orderDetails));

      // Keep only the last 5 orders to prevent memory issues
      if (savedOrders.length > 5) {
        savedOrders = savedOrders.sublist(savedOrders.length - 5);
      }

      // Save updated list
      await prefs.setStringList('carhop_orders', savedOrders);

      // Add order notification
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.addOrderNotification(
        title: "New Car-hop Order",
        body: "Your car-hop order has been placed successfully!",
        messageId: responseData['id'].toString(),
      );

      cartProvider.clearCart();
    } catch (e) {
      print('Error sending carhop order: $e');
      rethrow;
    }
  }

  /// Send a regular order via Telegram API
  Future<void> sendRegularOrder({
    required String? address,
    required String branchName,
    required String name,
    required String phone,
    required String paymentType,
    required String comment,
    required List orderItems,
    required double total,
    required double latitude,
    required double longitude,
    required String orderType,
    required String carDetails,
    required CartProvider cartProvider,
  }) async {
    try {
      final orderDetails = "Адрес: $address\n" +
          "Филиал: $branchName\n" +
          "Имя: $name\n" +
          "Тел: $phone\n" +
          "Тип платежа: $paymentType\n\n" +
          "Тип zakaza: $orderType\n\n" +
          "Заметка: ${comment.isEmpty ? 'Нет заметки' : comment}\n\n" +
          "🛒 <b>Корзина:</b>\n${orderItems.join("\n")}\n\n" +
          "<b>Итого:</b> ${NumberFormat('#,##0').format(total).toString()} сум\n\n" +
          "-----------------------\n" +
          "Mashina ma'lumotlari:\n ${carDetails.isEmpty ? 'Ma\'lumot yo\'q' : carDetails}\n\n" +
          "-----------------------\n" +
          "Источник: Mobile App\n";

      final encodedOrderDetails = Uri.encodeQueryComponent(orderDetails);

      String chatId = await getChatId();
      print("Using chatId: $chatId");

      final telegramDebUrl =
          "https://api.sievesapp.com/v1/public/make-post?chat_id=-1002074915184&text=$encodedOrderDetails&latitude=$latitude&longitude=$longitude";

      final response = await http.get(
        Uri.parse(telegramDebUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode != 200) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send order');
      } else {
        print("Order sent successfully! Response: ${response.body}");
        cartProvider.clearCart();
      }
    } catch (e) {
      print('Error sending regular order: $e');
      rethrow;
    }
  }

  /// Get the chat ID for Telegram orders
  Future<String> getChatId() async {
    try {
      // Default chat ID
      String chatId = "-1002074915184";

      // In a real implementation, you might want to get branch-specific chat IDs
      // based on the current branch, but for now we'll use the default

      return chatId;
    } catch (e) {
      print("Error getting chat ID: $e");
      return "-1002074915184"; // Default fallback
    }
  }
}

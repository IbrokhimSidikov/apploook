import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/services/api_service.dart';
import 'package:apploook/services/payme_service.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:provider/provider.dart';
import 'package:apploook/cart_provider.dart';

/// Service to handle Payme payment transactions for both delivery and carhop orders.
/// Manages saving pending orders, checking transaction status, and processing successful payments.
class PaymeTransactionService {
  static const String _pendingOrderKey = 'payme_pending_order';
  static const String _pendingOrderTimestampKey =
      'payme_pending_order_timestamp';
  static const String _pendingCarhopOrderKey = 'payme_pending_carhop_order';
  static const String _pendingCarhopOrderTimestampKey =
      'payme_pending_carhop_order_timestamp';
  static const String _paymentCompletedKey = 'payme_payment_completed';

  // Flags to prevent duplicate processing and popups
  static bool _orderBeingProcessed = false;
  static bool _verificationPopupShowing = false;
  static const int _maxWaitTimeMinutes = 5;

  /// Save pending order details before redirecting to Payme
  static Future<void> savePendingOrder({
    required String orderId,
    required String name,
    required String phone,
    required String? address,
    required String comment,
    required double total,
    required double latitude,
    required double longitude,
    required double deliveryFee,
    required List<Map<String, dynamic>> items,
    required String clientId,
    required String clientSecret,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final orderData = {
      'order_id': orderId,
      'name': name,
      'phone': phone,
      'address': address,
      'comment': comment,
      'total': total,
      'latitude': latitude,
      'longitude': longitude,
      'delivery_fee': deliveryFee,
      'items': items,
      'client_id': clientId,
      'client_secret': clientSecret,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await prefs.setString(_pendingOrderKey, jsonEncode(orderData));
    await prefs.setInt(
        _pendingOrderTimestampKey, orderData['timestamp'] as int);
    print('Saved pending Payme order: $orderId');
  }

  /// Check if there's a pending Payme order
  static Future<Map<String, dynamic>?> getPendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString(_pendingOrderKey);

    if (orderJson == null) {
      return null;
    }

    try {
      return jsonDecode(orderJson) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing pending order: $e');
      await clearPendingOrder();
      return null;
    }
  }

  /// Clear pending order data
  static Future<void> clearPendingOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOrderKey);
    await prefs.remove(_pendingOrderTimestampKey);
    print('Cleared pending Payme order');
  }

  /// Clear all pending payment data including both PaymeService and PaymeTransactionService data
  static Future<void> _clearAllPendingPaymentData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear PaymeTransactionService data
    await prefs.remove(_pendingOrderKey);
    await prefs.remove(_pendingOrderTimestampKey);
    await prefs.remove(_pendingCarhopOrderKey);
    await prefs.remove(_pendingCarhopOrderTimestampKey);

    // Clear PaymeService data
    await prefs.remove('payme_pending_order_id');
    await prefs.remove('payme_pending_amount');
    await prefs.remove('payme_merchant_id');
    await prefs.remove('payme_payment_pending');
    await prefs.remove('payme_payment_timestamp');

    print('🧹 Cleared all pending Payme payment data');
  }

  /// Check transaction status with periodic polling
  static Future<void> startTransactionStatusCheck(
    BuildContext context,
    String orderId,
  ) async {
    // Prevent multiple verification popups
    if (_verificationPopupShowing) {
      print(
          '⚠️ Verification popup is already showing, skipping duplicate popup');
      return;
    }

    _verificationPopupShowing = true;
    print('🔍 Starting payment verification with popup');

    // Timer reference that will be passed to the dialog
    Timer? pollingTimer;

    // Show a dialog with progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: AlertDialog(
          title: const Text('Transaction in Progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Waiting for payment approval...'),
              const SizedBox(height: 8),
              Text('Order ID: $orderId', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
              const Text('Please complete the payment in the Payme app',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Do not close this screen unless you want to cancel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Cancel the timer if it exists
                pollingTimer?.cancel();

                // Clear the pending payment data
                await _clearAllPendingPaymentData();

                // Close the dialog
                Navigator.of(context, rootNavigator: true).pop();

                // Reset verification popup flag
                _verificationPopupShowing = false;
                print('❌ Payment verification cancelled, popup flag reset');

                // Show cancellation message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Payment verification cancelled'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    // Start checking transaction status
    try {
      pollingTimer =
          await _checkTransactionStatusPeriodically(context, orderId);
    } catch (e) {
      // If there was an error starting the timer, reset the flag
      _verificationPopupShowing = false;
      print('⚠️ Error starting timer, resetting popup flag: $e');
    }

    // No need for additional checks here as the try-catch above will handle errors
  }

  /// Check transaction status every 2 seconds for up to 5 minutes
  /// Returns the timer so it can be cancelled if needed
  static Future<Timer> _checkTransactionStatusPeriodically(
    BuildContext context,
    String orderId,
  ) async {
    final startTime = DateTime.now();

    // Create the timer immediately so we can return it
    final timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Check if we've exceeded the maximum wait time
        final currentTime = DateTime.now();
        final elapsedMinutes = currentTime.difference(startTime).inMinutes;
        final elapsedSeconds = currentTime.difference(startTime).inSeconds;
        print(
            '⏱️ Polling attempt: ${timer.tick} - Elapsed time: ${elapsedSeconds}s');

        if (elapsedMinutes >= _maxWaitTimeMinutes) {
          timer.cancel();
          // Close the dialog if context is still valid
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();

            // Reset verification popup flag
            _verificationPopupShowing = false;
            print('⏱️ Payment verification timed out, popup flag reset');

            // Show timeout message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Payment verification timed out. Please try again or contact support.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check payment status
        print('🔍 Checking payment status for order: $orderId');
        final paymentResult = await PaymeService.verifyPayment(orderId);
        print('📊 Payment verification result: ${paymentResult['message']}');

        if (paymentResult['success'] == true) {
          print(
              '✅ Payment successful! Transaction ID: ${paymentResult['transaction_id']}');
          timer.cancel();

          // Clear the cart immediately using Provider
          if (context.mounted) {
            try {
              // Clear the cart through Provider first
              final cartProvider =
                  Provider.of<CartProvider>(context, listen: false);
              cartProvider.clearCart();
              print('🛒 Cart cleared through Provider');
            } catch (e) {
              print('Error clearing cart through Provider: $e');
            }
          }

          // Close the dialog if context is still valid
          if (context.mounted) {
            // Reset verification popup flag
            _verificationPopupShowing = false;
            print('✅ Payment verification successful, popup flag reset');
            Navigator.of(context, rootNavigator: true).pop();

            // Immediately navigate to home page first
            print(
                '🔝 Immediately navigating to home page after successful payment');
            Navigator.of(context).popUntil((route) => route.isFirst);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Processing your order...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Mark this payment as completed to prevent additional verification popups
            _markPaymentAsCompleted(orderId);

            // Process the successful payment in the background only if not already being processed
            if (!_orderBeingProcessed) {
              _processPaymentInBackground(context);
            } else {
              print(
                  '⚠️ Order is already being processed, skipping duplicate processing');
            }
          }
        }
      } catch (e) {
        print('Error in polling cycle: $e');
        // Don't cancel the timer here, let it continue polling
      }
    });

    print('🔄 Starting periodic check for Payme transaction: $orderId');

    // Return the timer immediately so it can be cancelled if needed
    return timer;
  }

  /// Process payment in background after navigation
  /// This method doesn't use the context for UI operations to avoid widget tree issues
  static Future<void> _processPaymentInBackground(BuildContext context) async {
    // Set flag to prevent duplicate processing
    if (_orderBeingProcessed) {
      print('⚠️ Order is already being processed, skipping duplicate call');
      return;
    }

    _orderBeingProcessed = true;
    print('🔒 Order processing started and locked to prevent duplicates');

    try {
      // Process the successful payment without using context for UI operations
      final orderData = await getPendingOrder();
      if (orderData != null) {
        try {
          // Extract necessary data from orderData to avoid context usage
          final String orderId = orderData['order_id'];
          final String clientId = orderData['client_id'];
          final String clientSecret = orderData['client_secret'];
          final String name = orderData['name'];
          final String phone = orderData['phone'];
          final String? address = orderData['address'];
          final String comment = orderData['comment'];
          final double total = orderData['total'];
          final double latitude = orderData['latitude'];
          final double longitude = orderData['longitude'];
          final double deliveryFee = orderData['delivery_fee'];
          final List<Map<String, dynamic>> items =
              List<Map<String, dynamic>>.from(orderData['items']);

          // Create API service
          final apiService =
              ApiService(clientId: clientId, clientSecret: clientSecret);

          print(
              '💰 Processing pre-verified successful payment for order: $orderId');

          // Submit the order with payment type 'Payme'
          final result = await apiService.createOrder(
            clientName: name,
            phoneNumber: phone,
            address: address ?? '',
            comment: comment,
            totalCost: total,
            latitude: latitude,
            longitude: longitude,
            deliveryFee: deliveryFee,
            items: items,
            paymentType: 'Payme',
            paymeOrderId: orderId,
          );

          print('Order submitted successfully: $result');

          // Get the order ID from the API response
          String apiOrderId;
          print('Full API response: ${result.toString()}');

          if (result.containsKey('orderId')) {
            apiOrderId = result['orderId'].toString();
            print('Using orderId from API response: $apiOrderId');
          } else if (result.containsKey('id')) {
            apiOrderId = result['id'].toString();
            print('Using id from API response: $apiOrderId');
          } else if (result.containsKey('eatsId')) {
            apiOrderId = result['eatsId'].toString();
            print('Using eatsId from API response: $apiOrderId');
          } else {
            // Fallback to the Payme order ID if no ID is found in the response
            apiOrderId = orderId;
            print('No order ID found in response, using Payme order ID: $apiOrderId');
          }

          // Log the order status endpoint that will be used for tracking
          print('ORDER TRACKING: Order submitted successfully with ID: $apiOrderId');
          print('ORDER TRACKING: Status endpoint will be: https://integrator.api.delever.uz/v1/order/$apiOrderId/status');

          // Save order to tracking system for display in order tracking UI
          print('ORDER TRACKING: Saving Payme order to tracking system: $apiOrderId');
          await _saveDeliveryOrderToPrefs(
            orderId: apiOrderId,
            address: address ?? 'No address provided',
            paymentType: 'Payme',
            items: items,
            total: total,
            deliveryFee: deliveryFee,
            latitude: latitude,
            longitude: longitude
          );

          // Clear pending order data
          await clearPendingOrder();
          await PaymeService.clearPendingPayment();

          // Reset the processing flag
          _orderBeingProcessed = false;
          print('🔓 Order processing completed and unlocked');
        } catch (e) {
          print('Error processing successful payment: $e');
        }
      } else {
        // Check for carhop order
        final carhopOrderData = await _getPendingCarhopOrder();
        if (carhopOrderData != null) {
          try {
            // Extract data from carhopOrderData
            final String paymeOrderId = carhopOrderData['order_id'];
            final String requestBody = carhopOrderData['request_body'];
            final branchConfigData = carhopOrderData['branch_config'];

            print(
                '💰 Processing pre-verified successful carhop payment for order: $paymeOrderId');

            // Send the order to the Sieves API
            final response = await http.post(
              Uri.parse(
                  'https://app.sievesapp.com/v1/order?code=${branchConfigData['sievesApiCode']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${branchConfigData['sievesApiToken']}',
                'Accept': 'application/json',
              },
              body: requestBody,
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              print('Carhop order submitted successfully: ${response.body}');
            } else {
              print('Request failed with status: ${response.statusCode}');
              print('Error message: ${response.body}');
            }

            // Clear pending order data
            await _clearPendingCarhopOrder();
            await PaymeService.clearPendingPayment();

            // Reset the processing flag
            _orderBeingProcessed = false;
            print('🔓 Order processing completed and unlocked');
          } catch (e) {
            print('Error processing carhop payment: $e');
            // Reset the processing flag in case of error
            _orderBeingProcessed = false;
            print('🔓 Order processing unlocked after error');
          }
        } else {
          // No pending order found
          print('Payment verified but no pending order found');
          _orderBeingProcessed = false;
          print('🔓 Order processing unlocked - no order found');
        }
      }
    } catch (e) {
      print('Error processing payment in background: $e');
      // Reset the processing flag in case of error
      _orderBeingProcessed = false;
      print('🔓 Order processing unlocked after error');
    }
  }

  static Future<Map<String, dynamic>?> _getPendingCarhopOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderString = prefs.getString(_pendingCarhopOrderKey);

    if (orderString == null || orderString.isEmpty) {
      return null;
    }

    try {
      final orderData = jsonDecode(orderString) as Map<String, dynamic>;

      // Check if the order is too old (more than 30 minutes)
      final timestamp = orderData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > 30 * 60 * 1000) {
        // 30 minutes in milliseconds
        await _clearPendingCarhopOrder();
        return null;
      }

      return orderData;
    } catch (e) {
      print('Error parsing pending carhop order: $e');
      await _clearPendingCarhopOrder();
      return null;
    }
  }

  // Clear pending carhop order from SharedPreferences
  static Future<void> _clearPendingCarhopOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingCarhopOrderKey);
  }

  // Save pending carhop order to SharedPreferences
  static Future<void> savePendingCarhopOrder(
      Map<String, dynamic> orderData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingCarhopOrderKey, jsonEncode(orderData));
    await prefs.setInt(
        _pendingCarhopOrderTimestampKey, DateTime.now().millisecondsSinceEpoch);
    print('Saved pending Payme carhop order: ${orderData['order_id']}');
  }

  /// Mark a payment as completed to prevent additional verification
  static Future<void> _markPaymentAsCompleted(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_paymentCompletedKey, orderId);
      await prefs.setInt('${_paymentCompletedKey}_timestamp',
          DateTime.now().millisecondsSinceEpoch);
      print(
          '💯 Payment $orderId marked as completed to prevent additional verification');
    } catch (e) {
      print('Error marking payment as completed: $e');
    }
  }
  
  /// Save delivery order to SharedPreferences for order tracking
  static Future<void> _saveDeliveryOrderToPrefs({
    required String orderId,
    required String address,
    required String paymentType,
    required List<Map<String, dynamic>> items,
    required double total,
    required double deliveryFee,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('ORDER TRACKING: Saving Payme delivery order to SharedPreferences: $orderId');
      final prefs = await SharedPreferences.getInstance();

      // Get existing orders or initialize empty list
      final savedOrders = prefs.getStringList('delivery_orders') ?? [];
      print('ORDER TRACKING: Found ${savedOrders.length} existing saved orders');

      // Create new order object
      final Map<String, dynamic> orderData = {
        'id': orderId,
        'status': 'pending', // Initial status
        'timestamp': DateTime.now().toIso8601String(),
        'address': address,
        'paymentType': paymentType,
        'items': items,
        'total': total,
        'deliveryFee': deliveryFee,
        'latitude': latitude,
        'longitude': longitude,
      };

      // Add new order to the beginning of the list
      savedOrders.insert(0, jsonEncode(orderData));
      
      // Keep only the 10 most recent orders
      if (savedOrders.length > 10) {
        savedOrders.removeRange(10, savedOrders.length);
      }
      
      // Mark that we have a new order for notification
      OrderTrackingService().markNewOrderAdded();
      
      // Save updated list back to SharedPreferences
      await prefs.setStringList('delivery_orders', savedOrders);
      print('ORDER TRACKING: Saved Payme order to tracking system: $orderId');
      print('ORDER TRACKING: Total orders in tracking: ${savedOrders.length}');
      
      // Create OrderTrackingService and update the order status
      final orderTrackingService = OrderTrackingService();
      await orderTrackingService.updateOrderStatus(orderId);
      print('ORDER TRACKING: Initiated status update for order: $orderId');
    } catch (e) {
      print('ORDER TRACKING: Error saving order to tracking: $e');
    }
  }

  /// Check if a payment has been completed recently
  static Future<bool> _isPaymentCompleted(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedOrderId = prefs.getString(_paymentCompletedKey);

      // If we have a completed order ID and it matches the current one
      if (completedOrderId == orderId) {
        // Check if it was completed within the last 5 minutes
        final timestamp =
            prefs.getInt('${_paymentCompletedKey}_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        final isRecent = now - timestamp < 5 * 60 * 1000; // 5 minutes

        if (isRecent) {
          print(
              '💯 Payment $orderId was already completed recently, skipping verification');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if payment is completed: $e');
      return false;
    }
  }

  // Check for pending orders when the app starts or resumes
  static Future<void> checkPendingOrders(BuildContext context) async {
    // Check for regular pending orders
    final pendingOrder = await getPendingOrder();

    if (pendingOrder != null) {
      final orderId = pendingOrder['order_id'];

      // Check if the order is too old (more than 30 minutes)
      final timestamp = pendingOrder['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now - timestamp > 30 * 60 * 1000;

      // Check if this payment was already completed recently
      final isCompleted = await _isPaymentCompleted(orderId);

      if (isExpired) {
        await clearPendingOrder();
      } else if (isCompleted) {
        // Payment was already completed, clear pending data
        print(
            '💯 Payment $orderId was already completed, clearing pending data');
        await clearPendingOrder();
        await PaymeService.clearPendingPayment();
      } else {
        // Automatically start checking the transaction status
        // without asking the user if they completed the payment
        await startTransactionStatusCheck(
          context,
          orderId,
        );
        return; // Return early since we're handling this pending order
      }
    }

    // Check for pending carhop orders if no regular pending order was found
    final carhopOrder = await _getPendingCarhopOrder();
    if (carhopOrder != null) {
      final orderId = carhopOrder['order_id'];

      // Check if the order is too old (more than 30 minutes)
      final timestamp = carhopOrder['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      final isExpired = now - timestamp > 30 * 60 * 1000;

      // Check if this payment was already completed recently
      final isCompleted = await _isPaymentCompleted(orderId);

      if (isExpired) {
        await _clearPendingCarhopOrder();
      } else if (isCompleted) {
        // Payment was already completed, clear pending data
        print(
            '💯 Payment $orderId was already completed, clearing pending data');
        await _clearPendingCarhopOrder();
        await PaymeService.clearPendingPayment();
      } else {
        // Automatically start checking the transaction status
        await startTransactionStatusCheck(
          context,
          orderId,
        );
      }
    }
  }
}

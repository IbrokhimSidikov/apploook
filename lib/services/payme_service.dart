import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class PaymeService {
  // Generate a unique order ID for Payme
  static String generateOrderId() {
    final random = Random();
    // Generate a random 8-digit number between 10000000 and 99999999
    final orderNumber = 10000000 + random.nextInt(90000000);
    return orderNumber.toString();
  }

  // Create the Payme checkout URL
  static String createPaymeCheckoutUrl(
      String merchantId, String orderId, double amount) {
    // Convert amount to integer (amount in tiyins - 100 tiyins = 1 UZS)
    final amountInTiyins = (amount * 100).toInt();

    // Create the parameter string
    final params = 'm=$merchantId;ac.order_id=$orderId;a=$amountInTiyins';

    // Encode to base64
    final base64Params = base64Encode(utf8.encode(params));
    print('Base64 params: https://checkout.paycom.uz/$base64Params');
    // Return the full URL
    return 'https://checkout.paycom.uz/$base64Params';
  }

  // Launch the Payme checkout URL
  static Future<bool> launchPaymeCheckout(
    BuildContext context,
    String merchantId,
    String orderId,
    double amount,
  ) async {
    try {
      print('🚀 Starting Payme checkout launch process...');
      print('📋 Parameters: merchantId=$merchantId, orderId=$orderId, amount=$amount');
      
      // Create the URL first to get the app URL
      final url = createPaymeCheckoutUrl(merchantId, orderId, amount);
      final base64Params = url.substring(url.lastIndexOf('/') + 1);
      final paymeAppUrl = 'payme://payment?payload=$base64Params';
      
      // Check if Payme app can be launched with different schemes
      print('🔍 Checking if Payme app can be launched...');
      List<String> testUrls = [
        paymeAppUrl,
        'payme://checkout?payload=$base64Params',
        'payme://pay?payload=$base64Params',
        'uz.dida.payme://payment?payload=$base64Params',
        'uz.dida.payme://checkout?payload=$base64Params',
      ];
      
      for (String testUrl in testUrls) {
        try {
          bool canLaunch = await canLaunchUrl(Uri.parse(testUrl));
          print('📱 Can launch $testUrl: $canLaunch');
        } catch (e) {
          print('❌ Error checking $testUrl: $e');
        }
      }
      
      // Also check if we can launch the web URL
      bool canLaunchWebUrl = false;
      try {
        canLaunchWebUrl = await canLaunchUrl(Uri.parse(url));
        print('🌐 Can launch web URL: $canLaunchWebUrl');
      } catch (e) {
        print('❌ Error checking if web URL can be launched: $e');
      }
      
      // Save the order ID to SharedPreferences for later verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('payme_pending_order_id', orderId);
      await prefs.setDouble('payme_pending_amount', amount);
      await prefs.setString('payme_merchant_id', merchantId);
      await prefs.setBool('payme_payment_pending', true);
      await prefs.setInt(
          'payme_payment_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('💾 Saved payment details to SharedPreferences');

      print('🔗 Generated web URL: $url');
      print('📱 Generated app URL: $paymeAppUrl');

      bool launched = false;

      // Since user confirmed the web URL works externally, try it first with different modes
      print('🌐 Trying web URL first (user confirmed this works externally)...');
      
      // Try different launch modes for the web URL
      List<LaunchMode> launchModes = [
        LaunchMode.externalApplication, // This should trigger app if available
        LaunchMode.platformDefault,     // Let platform decide
        LaunchMode.externalNonBrowserApplication, // Force app over browser
      ];
      
      for (LaunchMode mode in launchModes) {
        if (launched) break;
        try {
          print('🎯 Trying web URL with mode: $mode');
          launched = await launchUrlString(
            url,
            mode: mode,
          );
          print('✅ Web URL launch result with $mode: $launched');
        } catch (e) {
          print('❌ Error launching web URL with $mode: $e');
        }
      }
      
      // If web URL failed, try custom app schemes as fallback
      if (!launched) {
        print('📱 Web URL failed, trying custom app schemes as fallback...');
        
        List<String> paymeUrls = [
          paymeAppUrl, // payme://payment?payload=...
          'payme://checkout?payload=$base64Params', // Alternative scheme
          'payme://pay?payload=$base64Params', // Alternative scheme
          'uz.dida.payme://payment?payload=$base64Params', // Package-based scheme
          'uz.dida.payme://checkout?payload=$base64Params', // Package-based scheme
        ];
        
        for (String testUrl in paymeUrls) {
          if (launched) break;
          print('🔍 Trying URL scheme: $testUrl');
          try {
            bool canLaunch = await canLaunchUrl(Uri.parse(testUrl));
            print('📱 Can launch $testUrl: $canLaunch');
            
            if (canLaunch) {
              launched = await launchUrlString(
                testUrl,
                mode: LaunchMode.externalNonBrowserApplication,
              );
              print('✅ Launch result for $testUrl: $launched');
            }
          } catch (e) {
            print('❌ Error with $testUrl: $e');
          }
        }
      }

      if (!launched) {
        print('💥 Both launch attempts failed!');
        
        // Try alternative launch modes
        print('🔄 Trying alternative launch modes...');
        
        // Try one more approach: launch web URL in browser mode
        if (!launched) {
          try {
            print('🎯 Final attempt: Launching web URL in browser mode...');
            launched = await launchUrlString(
              url,
              mode: LaunchMode.inAppBrowserView,
            );
            print('✅ Browser mode launch result: $launched');
          } catch (e) {
            print('❌ Browser mode launch error: $e');
          }
        }
        
        if (!launched) {
          throw 'Could not launch Payme URL with any method';
        }
      }

      print('🎉 Payme checkout launched successfully!');
      return true;
    } catch (e) {
      print('💥 Fatal error launching Payme checkout: $e');
      print('📝 Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Check if there's a pending Payme payment
  static Future<Map<String, dynamic>?> getPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPending = prefs.getBool('payme_payment_pending') ?? false;

      if (!isPending) {
        return null;
      }

      return {
        'order_id': prefs.getString('payme_pending_order_id'),
        'amount': prefs.getDouble('payme_pending_amount'),
        'merchant_id': prefs.getString('payme_merchant_id'),
        'timestamp': prefs.getInt('payme_payment_timestamp'),
      };
    } catch (e) {
      print('Error checking pending payment: $e');
      return null;
    }
  }

  // Clear pending payment data
  static Future<void> clearPendingPayment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('payme_payment_pending');
      await prefs.remove('payme_pending_order_id');
      await prefs.remove('payme_pending_amount');
      await prefs.remove('payme_merchant_id');
      await prefs.remove('payme_payment_timestamp');
    } catch (e) {
      print('Error clearing pending payment: $e');
    }
  }

  // Handle payment verification
  // This method should be called to check the status of a Payme transaction
  static Future<Map<String, dynamic>> verifyPayment(String orderId) async {
    try {
      // Check if we have a pending payment for this order ID
      final pendingPayment = await getPendingPayment();
      if (pendingPayment == null || pendingPayment['order_id'] != orderId) {
        print(
            '⚠️ No pending payment found in local storage for order: $orderId');
        print('⚠️ Will still check with API to show response');
        // Continue with API call anyway to see the response
      }

      // Make API call to check transaction status
      final url =
          'https://api.sievesapp.com/v1/public/check-payme-transaction?order_id=$orderId';
      print('🔄 Checking Payme transaction status: $url');

      final response = await http.get(Uri.parse(url));
      print('📥 Payme API response status: ${response.statusCode}');
      print('📥 Payme API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Payme transaction check response: $responseData');

        // If success is true and transaction is paid, payment is successful
        if (responseData['success'] == true &&
            responseData['transaction'] != null &&
            responseData['transaction']['is_paid'] == true) {
          // Clear the pending payment since it's now confirmed
          await clearPendingPayment();

          return {
            'success': true,
            'message': 'Payment verified successfully',
            'transaction_id': responseData['transaction']
                ['payme_transaction_id'],
            'order_id': orderId,
            'transaction_data': responseData['transaction']
          };
        } else if (responseData['success'] == false &&
            responseData['message'] == 'No transaction found for this order') {
          // Payment was cancelled or never completed
          return {
            'success': false,
            'message': 'Payment was cancelled or not completed',
            'order_id': orderId
          };
        } else {
          // Payment is still pending
          return {
            'success': false,
            'message': 'Payment is still pending',
            'order_id': orderId
          };
        }
      } else {
        // API call failed
        return {
          'success': false,
          'message': 'API error: ${response.statusCode}',
          'order_id': orderId
        };
      }
    } catch (e) {
      print('Error verifying payment: $e');
      return {'success': false, 'message': 'Error: $e', 'order_id': orderId};
    }
  }

  // Test function to directly check transaction status without pending payment check
  static Future<Map<String, dynamic>> testCheckTransaction(
      String orderId) async {
    try {
      print(
          '🧪 TEST: Directly checking transaction status for order: $orderId');

      // Make API call to check transaction status
      final url =
          'https://api.sievesapp.com/v1/public/check-payme-transaction?order_id=$orderId';
      print('🔄 TEST: API URL: $url');

      final response = await http.get(Uri.parse(url));
      print('📥 TEST: API response status: ${response.statusCode}');
      print('📥 TEST: API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'response_data': responseData,
          'order_id': orderId
        };
      } else {
        return {
          'success': false,
          'message': 'API error: ${response.statusCode}',
          'order_id': orderId
        };
      }
    } catch (e) {
      print('❌ TEST: Error checking transaction: $e');
      return {'success': false, 'message': 'Error: $e', 'order_id': orderId};
    }
  }
}

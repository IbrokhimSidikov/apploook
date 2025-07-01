import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymeService {
  // Generate a unique order ID for Payme
  static String generateOrderId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${random.nextInt(1000)}$timestamp';
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
      // Save the order ID to SharedPreferences for later verification
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('payme_pending_order_id', orderId);
      await prefs.setDouble('payme_pending_amount', amount);
      await prefs.setString('payme_merchant_id', merchantId);
      await prefs.setBool('payme_payment_pending', true);
      await prefs.setInt(
          'payme_payment_timestamp', DateTime.now().millisecondsSinceEpoch);

      // Create the URL
      final url = createPaymeCheckoutUrl(merchantId, orderId, amount);

      // Launch the URL in external browser
      if (await canLaunch(url)) {
        await launch(
          url,
          forceSafariVC: false, // iOS: Don't use SafariVC
          forceWebView: false, // Android: Don't use WebView
          enableJavaScript: true,
          enableDomStorage: true,
          universalLinksOnly: false, // Don't restrict to universal links
        );
        return true;
      } else {
        throw 'Could not launch Payme URL';
      }
    } catch (e) {
      print('Error launching Payme checkout: $e');
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
  // Note: In a real implementation, you would need to verify the payment status
  // with Payme's server using their API. This is a simplified version.
  static Future<bool> verifyPayment(String orderId) async {
    try {
      final pendingPayment = await getPendingPayment();

      if (pendingPayment != null && pendingPayment['order_id'] == orderId) {
        // In a real implementation, you would verify with Payme's server
        // For now, we'll just clear the pending payment and return true
        await clearPendingPayment();
        return true;
      }

      return false;
    } catch (e) {
      print('Error verifying payment: $e');
      return false;
    }
  }
}

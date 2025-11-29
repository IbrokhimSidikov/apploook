import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/config/branch_config.dart';

class RahmatPayService {
  static const String _baseUrl = 'http://64.23.216.120:3000';
  static const String _createInvoiceEndpoint = '$_baseUrl/rahmat-pay/create-invoice';
  
  // TODO: TESTING ONLY - Replace with actual bearer token
  static const String _testBearerToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IlJqTkRNRGhDTmpoQ01EWTBSalF6TUVFeU9FTTROa0ZDUkVRd1FUSkVOVUUwUkRaRE1qZEVNZyJ9.eyJpc3MiOiJodHRwczovL2V4b2RlbGljYWluYy5ldS5hdXRoMC5jb20vIiwic3ViIjoiYXV0aDB8NjViY2RlMDA5ODMwYTllN2JiY2U3NWQ0IiwiYXVkIjpbImxvY2FsaG9zdDo4MDgwL2xvb29rLWFwaS93ZWIiLCJodHRwczovL2V4b2RlbGljYWluYy5ldS5hdXRoMC5jb20vdXNlcmluZm8iXSwiaWF0IjoxNzY0NDA2NjM2LCJleHAiOjE3NjQ0OTMwMzYsInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwiLCJhenAiOiI1dXBaSkJsSU1pR1Z1SEw2ZGFmOFBvOUZMWFhKMkxHNSJ9.EBu4V_0QUk1H2ble4TGa660wClV1jDSxHHCuu9wIPuI8UZ1bF-xcxr0v4gQIHvnG8fb1ESXoNMF6MPfBpJuAIqtF-yXyU91ThAaKIr4SPdYpDEpwHFvMzErWvzF_PgK5BW64YlE47As0-h6Z6XfHezCbhu1XZ2fd4HI55AmbRpR258uxDhV5Neq7kmxMAR0q_EWhx5YTY5n_uV_YaVEPQcgIzXytqtnzrtvufHXOeQClche1SgeiT1XeLIpzSVMaXFC1htqO7DNG71UEvunSyLP30YuYj6JxA543hIaQB-Yc2rz45CsgjzvvZn0xzdye91H_VVW38ROJZ7oMs6b1-w';

  /// Creates an invoice with Rahmat Pay and returns the payment URL
  /// 
  /// Parameters:
  /// - [branchName]: Name of the branch (used to get branch config)
  /// - [orderTypeId]: Order type ID (2 for delivery, 8 for carhop, etc.)
  /// - [paymentTypeId]: Payment type ID (3 for card)
  /// - [customerQuantity]: Number of customers
  /// - [pagerNumber]: Customer phone number
  /// - [note]: Order note/comment
  /// - [amount]: Total amount in UZS (in tiyin - multiply by 100)
  /// - [lang]: Language code (ru, uz, en)
  /// - [ofdItems]: List of OFD items for fiscal data
  /// - [bearerToken]: Authentication token from Sieves API
  static Future<Map<String, dynamic>> createInvoice({
    required String branchName,
    required int orderTypeId,
    required int paymentTypeId,
    required int customerQuantity,
    required String pagerNumber,
    required String note,
    required int amount,
    required String lang,
    required List<Map<String, dynamic>> ofdItems,
    required String bearerToken,
  }) async {
    try {
      // Get branch configuration
      final branchConfig = BranchConfigs.getConfig(branchName);

      print('\n======== RAHMAT PAY: Creating Invoice ========');
      print('Branch: $branchName');
      print('Branch ID: ${branchConfig.branchId}');
      print('Employee ID: ${branchConfig.employeeId}');
      print('Order Type ID: $orderTypeId');
      print('Payment Type ID: $paymentTypeId');
      print('Amount: $amount UZS');
      print('Pager Number: $pagerNumber');
      print('Note: $note');
      print('Language: $lang');
      print('OFD Items Count: ${ofdItems.length}');
      print('OFD Items: ${json.encode(ofdItems)}');

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        "branch_id": branchConfig.branchId,
        "employee_id": branchConfig.employeeId,
        "order_type_id": orderTypeId,
        "payment_type_id": paymentTypeId,
        "customer_quantity": customerQuantity,
        "pager_number": pagerNumber,
        "note": note,
        "amount": amount,
        "lang": lang,
        "ofd": ofdItems,
      };

      print('Request Body: ${json.encode(requestBody)}');

      // Make POST request
      // TODO: TESTING ONLY - Using _testBearerToken instead of bearerToken parameter
      final response = await http.post(
        Uri.parse(_createInvoiceEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_testBearerToken',
        },
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Invoice created successfully!');
        print('Response Data: $responseData');

        // Extract the short_link from response
        if (responseData['short_link'] != null) {
          print('Payment URL: ${responseData['short_link']}');
          return {
            'success': true,
            'short_link': responseData['short_link'],
            'invoice_id': responseData['invoice_id'],
            'full_response': responseData,
          };
        } else {
          throw Exception('short_link not found in response');
        }
      } else {
        print('Failed to create invoice: ${response.statusCode}');
        print('Error Response: ${response.body}');
        throw Exception('Failed to create invoice: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error in createInvoice: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    } finally {
      print('======== END RAHMAT PAY: Creating Invoice ========\n');
    }
  }

  /// Launches the Rahmat Pay checkout page in browser
  /// Returns true if successfully launched, false otherwise
  static Future<bool> launchPaymentUrl(String paymentUrl) async {
    try {
      print('Launching Rahmat Pay URL: $paymentUrl');
      
      final Uri uri = Uri.parse(paymentUrl);
      
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('Successfully launched Rahmat Pay checkout');
          return true;
        } else {
          print('Failed to launch Rahmat Pay checkout');
          return false;
        }
      } else {
        print('Cannot launch URL: $paymentUrl');
        return false;
      }
    } catch (e) {
      print('Error launching payment URL: $e');
      return false;
    }
  }

  /// Converts cart items to OFD format required by Rahmat Pay
  /// 
  /// Note: You'll need to add MXIK codes and package codes to your product model
  /// For now, using placeholder values
  static List<Map<String, dynamic>> convertCartItemsToOFD(
    List<dynamic> cartItems,
  ) {
    return cartItems.map((item) {
      // Calculate total price including modifiers
      final basePrice = (item.product.price * 100).toInt(); // Convert to tiyin
      final quantity = item.quantity;
      
      // Calculate modifier total
      int modifierTotal = 0;
      if (item.selectedModifiers != null && item.selectedModifiers.isNotEmpty) {
        for (var modifier in item.selectedModifiers) {
          modifierTotal += ((modifier.modifier.price * modifier.quantity * 100) as num).toInt();
        }
      }
      
      final totalPrice = (basePrice + modifierTotal) * quantity;
      
      return {
        "qty": quantity,
        "price": basePrice + modifierTotal,
        "mxik": "06401004002000000", // TODO: Get from product model
        "total": totalPrice,
        "package_code": "1506113", // TODO: Get from product model
        "name": item.displayName ?? item.product.name,
      };
    }).toList();
  }

  /// Saves pending card payment order for later verification
  static Future<void> savePendingCardPayment({
    required String invoiceId,
    required String shortLink,
    required Map<String, dynamic> orderData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final pendingPayment = {
      'invoice_id': invoiceId,
      'short_link': shortLink,
      'order_data': orderData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString('pending_card_payment', json.encode(pendingPayment));
    print('Saved pending card payment: $invoiceId');
  }

  /// Gets pending card payment if exists
  static Future<Map<String, dynamic>?> getPendingCardPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingPaymentStr = prefs.getString('pending_card_payment');
    
    if (pendingPaymentStr != null) {
      return json.decode(pendingPaymentStr);
    }
    
    return null;
  }

  /// Clears pending card payment
  static Future<void> clearPendingCardPayment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_card_payment');
    print('Cleared pending card payment');
  }

  /// Determines the order type ID based on the selected index
  /// 0: Delivery (order_type_id: 2)
  /// 1: Self-Pickup (order_type_id: 1)
  /// 2: Carhop (order_type_id: 8)
  /// 3: In-Restaurant (order_type_id: 3)
  static int getOrderTypeId(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 2; // Delivery
      case 1:
        return 1; // Self-Pickup
      case 2:
        return 8; // Carhop
      case 3:
        return 3; // In-Restaurant
      default:
        return 2; // Default to delivery
    }
  }

  /// Checks the payment status for a given invoice ID
  /// Returns the payment status from the backend API
  static Future<Map<String, dynamic>> checkPaymentStatus(String invoiceId) async {
    try {
      print('\n======== RAHMAT PAY: Checking Payment Status ========');
      print('Invoice ID: $invoiceId');
      
      final url = Uri.parse('$_baseUrl/rahmat-pay/status/$invoiceId');
      print('Status URL: $url');
      
      // TODO: TESTING ONLY - Using _testBearerToken for authentication
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_testBearerToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Payment status check timed out');
        },
      );
      
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Payment status retrieved successfully');
        print('Status: ${responseData['status']}');
        print('======== END RAHMAT PAY: Checking Payment Status ========\n');
        
        return {
          'success': true,
          'status': responseData['status'],
          'data': responseData,
        };
      } else {
        print('Failed to check payment status: ${response.statusCode}');
        print('======== END RAHMAT PAY: Checking Payment Status ========\n');
        return {
          'success': false,
          'error': 'Failed to check status: ${response.statusCode}',
        };
      }
    } catch (e, stackTrace) {
      print('Error checking payment status: $e');
      print('Stack trace: $stackTrace');
      print('======== END RAHMAT PAY: Checking Payment Status ========\n');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

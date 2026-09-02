import 'dart:convert';
import 'package:apploook/models/loyalty.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/config/branch_config.dart';

class RahmatPayService {
  static const String _baseUrl = 'https://api.v3.sievesapp.com';
  static const String _createInvoiceEndpoint = '$_baseUrl/rahmat-pay/create-invoice';
  

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
  /// - [cartItems]: List of cart items
  /// - [bearerToken]: Authentication token from Sieves API
  /// - [customerName]: Customer name for delivery
  /// - [customerPhone]: Customer phone number with country code
  /// - [deliveryAddress]: Full delivery address
  /// - [latitude]: Delivery latitude
  /// - [longitude]: Delivery longitude
  /// - [additionalPhone]: Additional phone number (optional)
  /// - [restaurantId]: Nearest branch restaurant ID for Delever
  /// - [deliveryFee]: Delivery fee amount


  static Future<Map<String, dynamic>> createInvoice({
    required String branchName,
    required int orderTypeId,
    required int paymentTypeId,
    required int customerQuantity,
    required String pagerNumber,
    required String note,
    required int amount,
    required String lang,
    required List<dynamic> cartItems,
    required String bearerToken,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    double? latitude,
    double? longitude,
    String? additionalPhone,
    String? restaurantId,
    double? deliveryFee,
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
      print('Cart Items Count: ${cartItems.length}');

      // Build Sieves order items
      final List<Map<String, dynamic>> sievesOrderItems = cartItems.map((item) {
        final String? productUuid = item.product.uuid;
        final String productIdentifier = productUuid ?? item.product.id.toString();
        
        return {
          "product_id": productIdentifier,
          "total_price": item.totalPrice,
          "quantity": item.quantity,
          "actual_price": (item.totalPrice / item.quantity).toString(),
          "selectedModifiers": item.selectedModifiers
              .map((modifier) => {
                    "modifierId": modifier.modifier.id,
                    "modifierName": modifier.modifier.name,
                    "modifierPrice": modifier.modifier.price,
                    "quantity": modifier.quantity,
                  })
              .toList(),
        };
      }).toList();

      // Build Rahmat OFD items with static mxik, package_code, and name
      final List<Map<String, dynamic>> rahmatOfdItems = cartItems.map((item) {
        // Calculate total price including modifiers in tiyin
        final basePrice = (item.product.price * 100).toInt();
        final quantity = item.quantity;
        
        // Calculate modifier total
        int modifierTotal = 0;
        if (item.selectedModifiers != null && item.selectedModifiers.isNotEmpty) {
          for (var modifier in item.selectedModifiers) {
            modifierTotal += ((modifier.modifier.price * modifier.quantity * 100) as num).toInt();
          }
        }
        
        final pricePerItem = basePrice + modifierTotal;
        final totalPrice = pricePerItem * quantity;
        
        return {
          "qty": quantity,
          "price": pricePerItem,
          "mxik": "10202001002000000",
          "total": totalPrice,
          "package_code": "1506113",
          "name": "fast food",
        };
      }).toList();

      // Prepare request body with new structure
      final Map<String, dynamic> requestBody = {
        "sieves_payload": {
          "delivery_employee_id": null,
          "isSynchronous": "sync",
          "is_fast": 0,
          "queue_type": "sync",
          "day_session_id": null,
          "employee_id": branchConfig.employeeId,
          "pos_id": null,
          "branch_id": branchConfig.branchId,
          "pos_session_id": null,
          "order_type_id": orderTypeId,
          "customer_id": null,
          "address_id": null,
          "start_time": "now",
          "pager_number": pagerNumber,
          "note": note,
          "orderItems": sievesOrderItems,
          "transactions": [
            {
              "account_id": 1,
              "payment_type_id": paymentTypeId,
              "amount": amount / 100,
              "type": "deposit"
            }
          ],
          "value": amount / 100,
          "customer_quantity": customerQuantity,
        },
        "rahmat_payload": {
          "amount": amount,
          "lang": lang,
          "ofd": rahmatOfdItems,
        },
        "delever_payload": {
          "platform": "YE",
          "discriminator": "marketplace",
          "restaurantId": restaurantId ?? branchConfig.branchId.toString(),
          "deliveryInfo": {
            "clientName": customerName ?? "",
            "phoneNumber": customerPhone ?? pagerNumber,
            "additionalPhoneNumbers": additionalPhone != null ? [additionalPhone] : [],
            "deliveryDate": DateTime.now().toUtc().toIso8601String(),
            "deliveryAddress": {
              "full": deliveryAddress ?? "Branch: $branchName",
              "latitude": latitude?.toString() ?? "0.0",
              "longitude": longitude?.toString() ?? "0.0"
            },
            "courierArrivementDate": DateTime.now().add(Duration(minutes: 30)).toUtc().toIso8601String(),
            "realPhoneNumber": customerPhone ?? pagerNumber,
            "pickupCode": DateTime.now().millisecondsSinceEpoch % 10000
          },
          "paymentInfo": {
            "itemsCost": (amount - ((deliveryFee ?? 0) * 100)).toInt(),
            "deliveryFee": ((deliveryFee ?? 0)).toInt(),
            "paymentType": "CARD",
            "netting_payment": false
          },
          "items": cartItems
              .map((item) => {
                    "id": item.product.uuid,
                    "name": item.displayName,
                    "quantity": item.quantity,
                    "price": (item.product.price * 100).toInt(),
                    "modifications": item.selectedModifiers
                        .map((modifier) => {
                              "id": modifier.modifier.id,
                              "group_id": modifier.modifier.id.toString().split('-').first + "-group",
                              "name": modifier.modifier.name,
                              "quantity": modifier.quantity,
                              "price": (modifier.modifier.price * 100).toInt(),
                            })
                        .toList(),
                  })
              .toList(),
          "persons": customerQuantity,
          "comment": note
        }

      };

      print('\n======== FULL REQUEST BODY ========');
      print(const JsonEncoder.withIndent('  ').convert(requestBody));
      print('======== END REQUEST BODY ========\n');

      // Build URL with query parameters
      final url = Uri.parse(_createInvoiceEndpoint).replace(queryParameters: {
        'code': branchConfig.sievesApiCode,
        'isCarhop': '1',
      });

      print('Request URL: $url');

      // Make POST request
      // Using sievesApiCode from branch config for authentication
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${branchConfig.sievesApiCode}',
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
      
      // Try different launch modes in order of preference
      // 1. Try external application first (opens in browser)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          print('Successfully launched Rahmat Pay checkout in external app');
          return true;
        }
      } catch (e) {
        print('External application launch failed: $e');
      }
      
      // 2. Try platform default (lets system decide)
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (launched) {
          print('Successfully launched Rahmat Pay checkout with platform default');
          return true;
        }
      } catch (e) {
        print('Platform default launch failed: $e');
      }
      
      // 3. Try external non-browser mode
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalNonBrowserApplication,
        );
        if (launched) {
          print('Successfully launched Rahmat Pay checkout in external non-browser app');
          return true;
        }
      } catch (e) {
        print('External non-browser launch failed: $e');
      }
      
      print('Cannot launch URL: $paymentUrl - all launch modes failed');
      return false;
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
  /// 0: Delivery (order_type_id: 3)
  /// 1: Self-Pickup (order_type_id: 2)
  /// 2: Carhop (order_type_id: 8)
  /// 3: In-Restaurant (order_type_id: 1)
  static int getOrderTypeId(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 3; // Delivery
      case 1:
        return 2; // Self-Pickup
      case 2:
        return 8; // Carhop
      case 3:
        return 1; // In-Restaurant
      default:
        return 3; // Default to delivery
    }
  }

  /// Checks the payment status for a given invoice ID
  /// Returns the payment status from the backend API
  static Future<Map<String, dynamic>> checkPaymentStatus(String invoiceId, String branchName) async {
    try {
      // Get branch configuration
      final branchConfig = BranchConfigs.getConfig(branchName);
      
      print('\n======== RAHMAT PAY: Checking Payment Status ========');
      print('Invoice ID: $invoiceId');
      print('Branch: $branchName');
      
      // Build URL with query parameters
      final url = Uri.parse('$_baseUrl/rahmat-pay/status/$invoiceId').replace(queryParameters: {
        'code': branchConfig.sievesApiCode,
      });
      print('Status URL: $url');
      
      // Using sievesApiCode from branch config for authentication
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${branchConfig.sievesApiCode}',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
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

  /// Sends Sieves payload to a custom API endpoint for CASH payments
  /// This is used for Self-Pickup, Carhop, and In-Restaurant orders (selectedIndex 1, 2, 3)
  /// 
  /// Parameters:
  /// - [apiEndpoint]: The custom API endpoint to send the payload to
  /// - [branchName]: Name of the branch (used to get branch config)
  /// - [orderTypeId]: Order type ID (7 for self-pickup, 8 for carhop, 1 for in-restaurant)
  /// - [customerQuantity]: Number of customers
  /// - [pagerNumber]: Customer phone number
  /// - [note]: Order note/comment
  /// - [amount]: Total amount in UZS
  /// - [cartItems]: List of cart items
  /// - [additionalHeaders]: Optional additional headers for the API request
  static Future<Map<String, dynamic>> sendCashOrderToApi({
    required String apiEndpoint,
    required String branchName,
    required int orderTypeId,
    required int customerQuantity,
    required String pagerNumber,
    required String note,
    required double amount,
    required List<dynamic> cartItems,
    Map<String, String>? additionalHeaders,
    // Points applied to this order. [amount] is the cash still due; the POS
    // order's value is the sum of the two, and the payment splits into a
    // cash line and a loyalty line so accounting sees both.
    int cashbackAmount = 0,
    int loyaltyAccountId = LoyaltyPos.defaultAccountId,
    int loyaltyPaymentTypeId = LoyaltyPos.defaultPaymentTypeId,
  }) async {
    try {
      // Get branch configuration
      final branchConfig = BranchConfigs.getConfig(branchName);

      print('\n======== CASH ORDER: Sending to Custom API ========');
      print('API Endpoint: $apiEndpoint');
      print('Branch: $branchName');
      print('Branch ID: ${branchConfig.branchId}');
      print('Employee ID: ${branchConfig.employeeId}');
      print('Order Type ID: $orderTypeId');
      print('Amount: $amount UZS');
      print('Pager Number: $pagerNumber');
      print('Note: $note');
      print('Cart Items Count: ${cartItems.length}');

      // Build Sieves order items (same structure as in createInvoice)
      final List<Map<String, dynamic>> sievesOrderItems = cartItems.map((item) {
        final String? productUuid = item.product.uuid;
        final String productIdentifier = productUuid ?? item.product.id.toString();
        
        return {
          "product_id": productIdentifier,
          "total_price": item.totalPrice,
          "quantity": item.quantity,
          "actual_price": (item.totalPrice / item.quantity).toString(),
          "selectedModifiers": item.selectedModifiers
              .map((modifier) => {
                    "modifierId": modifier.modifier.id,
                    "modifierName": modifier.modifier.name,
                    "modifierPrice": modifier.modifier.price,
                    "quantity": modifier.quantity,
                  })
              .toList(),
        };
      }).toList();

      // Prepare Sieves payload
      final Map<String, dynamic> sievesPayload = {
        "delivery_employee_id": null,
        "isSynchronous": "sync",
        "is_fast": 0,
        "queue_type": "sync",
        "day_session_id": null,
        "employee_id": branchConfig.employeeId,
        "pos_id": null,
        "branch_id": branchConfig.branchId,
        "pos_session_id": null,
        "order_type_id": orderTypeId,
        "customer_id": null,
        "address_id": null,
        "start_time": "now",
        "pager_number": pagerNumber,
        "note": note,
        "orderItems": sievesOrderItems,
        "transactions": LoyaltyPos.transactions(
          cashAmount: amount,
          cashbackAmount: cashbackAmount,
          cashPaymentTypeId: 2,
          loyaltyAccountId: loyaltyAccountId,
          loyaltyPaymentTypeId: loyaltyPaymentTypeId,
        ),
        "value": amount + cashbackAmount,
        "customer_quantity": customerQuantity,
      };

      print('\n======== SIEVES PAYLOAD ========');
      print(const JsonEncoder.withIndent('  ').convert(sievesPayload));
      print('======== END SIEVES PAYLOAD ========\n');

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${branchConfig.sievesApiCode}',
        ...?additionalHeaders,
      };

      print('Request Headers: $headers');

      // Build URL with query parameters (code and isCarhop)
      final url = Uri.parse(apiEndpoint).replace(queryParameters: {
        'code': branchConfig.sievesApiCode,
        'isCarhop': '1',
      });

      print('Request URL: $url');

      // Make POST request to custom API
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(sievesPayload),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Cash order sent successfully to custom API!');
        print('Response Data: $responseData');
        print('======== END CASH ORDER: Sending to Custom API ========\n');

        return {
          'success': true,
          'data': responseData,
        };
      } else {
        print('Failed to send cash order: ${response.statusCode}');
        print('Error Response: ${response.body}');
        print('======== END CASH ORDER: Sending to Custom API ========\n');
        throw Exception('Failed to send cash order: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Error sending cash order to custom API: $e');
      print('Stack trace: $stackTrace');
      print('======== END CASH ORDER: Sending to Custom API ========\n');
      rethrow;
    }
  }
}

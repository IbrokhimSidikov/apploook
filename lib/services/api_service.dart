import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/services/payme_service.dart';

class ApiService {
  static const String _baseUrl = 'https://integrator.api.delever.uz/v1';
  // static const String _baseUrl = 'https://test.integrator.api.delever.uz/v1';

  static const String _tokenEndpoint = '$_baseUrl/security/oauth/token';
  static const String _orderEndpoint = '$_baseUrl/order';
  // Default restaurant ID - not const because it can be changed at runtime
  static String _restaurantId = 'a96eb53e-b865-415f-b4d1-5d06c06f3fb1';

  // Token cache keys
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';

  // Client credentials
  final String _clientId;
  final String _clientSecret;
  final String _grantType;
  final String _scope;

  // For setting the restaurant ID dynamically
  static void setRestaurantId(String restaurantId) {
    if (restaurantId.isNotEmpty) {
      _restaurantId = restaurantId;
      print('ApiService: Restaurant ID set to $_restaurantId');
    }
  }

  ApiService({
    required String clientId,
    required String clientSecret,
    String grantType = 'client_credentials',
    String scope = 'read write',
  })  : _clientId = clientId,
        _clientSecret = clientSecret,
        _grantType = grantType,
        _scope = scope;

  // Get token, either from cache or by making a request
  Future<String> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we have a valid cached token
    final expiryTimeString = prefs.getString(_tokenExpiryKey);
    final token = prefs.getString(_tokenKey);

    if (token != null && expiryTimeString != null) {
      final expiryTime = DateTime.parse(expiryTimeString);
      // Add some buffer (5 minutes) to ensure token doesn't expire during use
      if (expiryTime.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
        print('Using cached token: ${token.substring(0, 10)}...');
        return token;
      }
    }

    // If no valid token in cache, fetch a new one
    return _fetchNewToken();
  }

  Future<String> _fetchNewToken() async {
    try {
      print('Fetching new token from API...');
      print('Token endpoint: $_tokenEndpoint');
      print('Client ID: ${_clientId.substring(0, 5)}...');
      print('Client Secret: ${_clientSecret.substring(0, 5)}...');
      print('Grant Type: $_grantType');
      print('Scope: $_scope');

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'grant_type': _grantType,
          'scope': _scope,
        },
      );

      print('Token response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Token response data: $data');

        final token = data['access_token'];
        if (token == null) {
          print('ERROR: access_token is null in the response');
          throw Exception('access_token is null in the response: $data');
        }

        final expiresIn =
            data['expires_in'] ?? 3600; // Default to 1 hour if not specified

        print(
            'Successfully obtained new token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');
        print('Token expires in: $expiresIn seconds');

        // Calculate expiry time
        final expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

        // Cache the token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_tokenExpiryKey, expiryTime.toIso8601String());

        return token;
      } else {
        print('Failed to get token: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to get token: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Exception in _fetchNewToken: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Generic method to make authenticated API requests
  Future<Map<String, dynamic>> _authenticatedRequest(String endpoint,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    final token = await getToken();
    print('Making $method request to: $_baseUrl$endpoint');
    print('Using token: ${token.substring(0, 10)}...');

    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    late http.Response response;

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept-Charset': 'utf-8',
    };

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    if (response.statusCode == 200) {
      print('Request successful: ${response.statusCode}');

      // Ensure proper UTF-8 encoding when decoding the response
      final responseBody = utf8.decode(response.bodyBytes);
      return json.decode(responseBody);
    } else {
      print('Request failed: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception(
          'API request failed: ${response.statusCode} ${response.body}');
    }
  }

  // Method to fetch menu items
  Future<List<dynamic>> getMenuItems() async {
    // Using the specific menu endpoint - not const because _restaurantId can change
    final endpoint = '/menu/$_restaurantId/composition';

    try {
      final data = await _authenticatedRequest(endpoint);

      // Print the raw response data for testing
      print('\n==== RAW API RESPONSE DATA ====');
      print('Response data type: ${data.runtimeType}');
      print('Response data keys: ${data.keys.toList()}');
      print('==== END RAW API RESPONSE ====\n');

      // Extract and display menu items for testing
      print('\n==== EXTRACTED MENU ITEMS ====');

      // Try different possible structures
      if (data['categories'] != null) {
        // If data has categories
        final categories = data['categories'] as List;
        print('Found ${categories.length} categories');

        for (var category in categories) {
          print('\nCategory: ${category['title'] ?? category['name']}');
          final items = category['items'] ?? category['products'] ?? [];
          print('Items count: ${items.length}');

          for (var item in items) {
            final id = item['id'] ?? 'N/A';
            final name = item['name'] ?? item['title'] ?? 'N/A';
            final price = item['price'] ??
                (item['priceList'] != null
                    ? item['priceList']['price']
                    : 'N/A');
            print('  - ID: $id, Name: $name, Price: $price');
          }
        }
      } else if (data['items'] != null) {
        // If data has direct items
        final items = data['items'] as List;
        print('Found ${items.length} items directly');

        for (var item in items) {
          final id = item['id'] ?? 'N/A';
          final name = item['name'] ?? item['title'] ?? 'N/A';
          final price = item['price'] ??
              (item['priceList'] != null ? item['priceList']['price'] : 'N/A');
          print('  - ID: $id, Name: $name, Price: $price');
        }
      } else {
        // Try to find any lists in the response
        for (var key in data.keys) {
          if (data[key] is List) {
            print(
                'Found list in key: $key with ${(data[key] as List).length} items');

            for (var item in data[key]) {
              if (item is Map) {
                final id = item['id'] ?? 'N/A';
                final name = item['name'] ?? item['title'] ?? 'N/A';
                final price = item['price'] ??
                    (item['priceList'] != null
                        ? item['priceList']['price']
                        : 'N/A');
                print('  - ID: $id, Name: $name, Price: $price');
              }
            }
          }
        }
      }

      print('==== END EXTRACTED MENU ITEMS ====\n');

      // Always return the complete response data wrapped in a list
      // This ensures MenuService gets the full structure with both categories and items
      return [data];
    } catch (e) {
      print('Error fetching menu items: $e');
      rethrow;
    }
  }

  // Method to create a new order
  /// Fetches the status of an order by its ID
  /// Returns the order status response from the API
  Future<Map<String, dynamic>> getOrderStatus(String orderId) async {
    try {
      print('ORDER TRACKING: ApiService: Fetching status for order: $orderId');

      // Construct the status endpoint URL
      final statusEndpoint = '/order/$orderId/status';
      print('ORDER TRACKING: ApiService: Using endpoint: $statusEndpoint');

      // Log the request details
      print('ORDER TRACKING: ApiService: Making authenticated GET request');
      print(
          'ORDER TRACKING: ApiService: Full URL: ${_baseUrl + statusEndpoint}');

      // Log auth token being used
      final token = await getToken();
      print(
          'ORDER TRACKING: ApiService: Using auth token: ${token.substring(0, 10)}...');

      // Make an authenticated GET request to the status endpoint
      final response = await _authenticatedRequest(
        statusEndpoint,
        method: 'GET',
      );

      // Log the complete response
      print('ORDER TRACKING: ApiService: Order status raw response: $response');

      // Log specific fields in the response
      if (response is Map<String, dynamic>) {
        print('ORDER TRACKING: ApiService: Response type: Map');
        print(
            'ORDER TRACKING: ApiService: Response keys: ${response.keys.toList()}');

        if (response.containsKey('status')) {
          print(
              'ORDER TRACKING: ApiService: Status field found: ${response['status']}');
        }

        if (response.containsKey('orderStatus')) {
          print(
              'ORDER TRACKING: ApiService: OrderStatus field found: ${response['orderStatus']}');
        }

        if (response.containsKey('error')) {
          print(
              'ORDER TRACKING: ApiService: Error field found: ${response['error']}');
        }

        // Additional fields that might contain status information
        if (response.containsKey('state')) {
          print(
              'ORDER TRACKING: ApiService: State field found: ${response['state']}');
        }

        if (response.containsKey('deliveryStatus')) {
          print(
              'ORDER TRACKING: ApiService: DeliveryStatus field found: ${response['deliveryStatus']}');
        }
      } else {
        print(
            'ORDER TRACKING: ApiService: Response is not a Map: ${response.runtimeType}');
      }

      return response;
    } catch (e) {
      print('ORDER TRACKING: ApiService: Error fetching order status: $e');
      print('ORDER TRACKING: ApiService: Error type: ${e.runtimeType}');
      print('ORDER TRACKING: ApiService: Stack trace: ${StackTrace.current}');
      return {'error': e.toString(), 'status': 'unknown'};
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String clientName,
    required String phoneNumber,
    required double latitude,
    required double longitude,
    required String address,
    required List<Map<String, dynamic>> items,
    required double totalCost,
    required String paymentType,
    String? comment,
    int persons = 1,
    double deliveryFee = 0,
    String? paymeOrderId,
  }) async {
    try {
      print('Creating order with the new API endpoint');

      // Format the phone number correctly (remove + if present)
      String formattedPhone =
          phoneNumber.startsWith('+') ? phoneNumber.substring(1) : phoneNumber;

      // Generate a unique order ID in the format used by the successful example
      // Format: YYMMDD-randomnumber
      final now = DateTime.now();
      final datePrefix =
          '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final randomPart =
          (10000000 + DateTime.now().millisecondsSinceEpoch % 90000000)
              .toString();
      String orderId = '$datePrefix-$randomPart';

      String finalPaymentType =
          await _determinePaymentType(paymentType, paymeOrderId);

      final Map<String, dynamic> orderPayload = {
        "platform": "YE",
        "discriminator": "marketplace",
        "eatsId": orderId,
        "restaurantId": _restaurantId,
        "deliveryInfo": {
          "clientName": clientName,
          "phoneNumber": phoneNumber,
          "additionalPhoneNumbers": [phoneNumber],
          "deliveryDate": "1937-01-01T12:00:27.870000+00:20",
          "deliveryAddress": {
            "full": address,
            "latitude": latitude.toString(),
            "longitude": longitude.toString(),
          },
          "courierArrivementDate": "1937-01-01T12:00:27.870000+00:20",
          "realPhoneNumber": formattedPhone,
          "pickupCode": 123,
        },
        "paymentInfo": {
          "itemsCost": totalCost.round(),
          "deliveryFee": deliveryFee.round(),
          "paymentType": finalPaymentType,
          "netting_payment": false
        },
        "items": items
            .map((item) => {
                  "id": item["id"],
                  "name": item["name"],
                  "quantity": item["quantity"],
                  "price": item["price"],
                })
            .toList(),
        "persons": 2,
        "comment": (comment != null && comment.isNotEmpty)
            ? "mobile_payment_type:${finalPaymentType.toLowerCase()}\n\n$comment"
            : "mobile_payment_type:${finalPaymentType.toLowerCase()}"
      };

      print('Order payload: ${json.encode(orderPayload)}');

      // Send the order request using the endpoint constant
      // Remove the leading slash since _orderEndpoint already includes the full path
      final response = await _authenticatedRequest(
        _orderEndpoint.replaceFirst(_baseUrl, ''),
        method: 'POST',
        body: orderPayload,
      );

      print('Order created successfully: $response');
      return response;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // This duplicate getOrderStatus method has been merged with the one above

  Future<String> _determinePaymentType(
      String originalPaymentType, String? paymeOrderId) async {
    // If payment was made through Payme and we have an order ID, verify the payment
    if (originalPaymentType.toLowerCase() == 'payme' && paymeOrderId != null) {
      // Check if the Payme payment was successful
      final paymentResult = await PaymeService.verifyPayment(paymeOrderId);
      final isVerified = paymentResult['success'] == true;
      if (isVerified) {
        print(
            'Payme payment verified as successful, setting payment type to card');
        return 'card';
      }
    }

    switch (originalPaymentType.toLowerCase()) {
      case 'card':
        return 'cash';
      case 'cash':
        return 'cash';
      case 'payme':
        return 'card';
      default:
        return originalPaymentType;
    }
  }
}

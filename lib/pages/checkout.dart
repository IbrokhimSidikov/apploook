// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/models/view/map_screen.dart';
import 'package:apploook/providers/notification_provider.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/widget/branch_locations.dart';
import 'package:apploook/services/map_services/open_street_map.dart';
import 'package:apploook/services/api_service.dart';
import 'package:apploook/services/payme_service.dart';
import 'package:apploook/services/payme_transaction_service.dart';
import 'package:apploook/services/rahmat_pay_service.dart';
import 'package:apploook/services/rahmat_pay_transaction_service.dart';
import 'package:apploook/config/branch_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:apploook/cart_provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../widget/branch_data.dart';
import '../features/reorder/application/reorder_controller.dart';
import '../features/reorder/domain/reorder_payload.dart';

class Checkout extends StatefulWidget {
  Checkout({
    Key? key,
    this.prefill,
  }) : super(key: key);

  /// Optional pre-populated values when entering Checkout from the
  /// reorder flow. Address text is prefilled but the map still has to
  /// be re-confirmed before placing the order.
  final ReorderPayload? prefill;

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  int _selectedIndex = 0;
  late double orderPrice = 0;
  double deliveryFee = 0;
  String firstName = '';
  String phoneNumber = '';
  String clientComment = '';
  String clientCommentPhone = '';
  String commented = '';
  String orderType = '';
  String carDetails = '';
  String carDetailsExtraInfo = '';
  String? paymeOrderId; // To store the Payme order ID
  bool _isProcessing = false;
  double total = 0.0;

  // Distance calculation variables
  bool _isCalculatingDistance = false;
  Map<String, dynamic>? _nearestBranch;
  String _distanceMessage = '';

  late FirebaseRemoteConfig remoteConfig;
  bool _isRemoteConfigInitialized = false;

  final FocusNode _carDetailsFocusNode = FocusNode();
  final TextEditingController _carDetailsController = TextEditingController();
  final TextEditingController _additionalPhoneController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRemoteConfig();
    _loadPhoneNumber();
    _loadCustomerName();
    _loadCarDetails(); // Load cached car details
    _loadAdditionalPhoneNumber(); // Load user's phone number for additional phone field
    _applyReorderPrefill();
    // Check for pending Payme transactions
    PaymeTransactionService.checkPendingOrders(context);
    // We'll calculate distance after address selection, not on page load

    // Log cart data being passed to checkout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logCartData();
    });
  }

  void _applyReorderPrefill() {
    // Prefer the constructor argument (direct Checkout(prefill:) callers);
    // otherwise consume whatever the reorder flow staged before routing
    // the user through Cart.
    final p = widget.prefill ??
        Provider.of<ReorderController>(context, listen: false).consumePrefill();
    if (p == null) return;
    _selectedIndex = p.orderTypeIndex;
    if (p.deliveryAddressText != null && p.deliveryAddressText!.isNotEmpty) {
      selectedAddress = p.deliveryAddressText;
    }
    if (p.branchName != null && branches.contains(p.branchName)) {
      selectedBranch = p.branchName;
    }
    if (p.comment != null && p.comment!.isNotEmpty) {
      clientComment = p.comment!;
      _commentController.text = p.comment!;
      _updateCommented();
    }
    if (p.carDetails != null && p.carDetails!.isNotEmpty) {
      carDetails = p.carDetails!;
      _carDetailsController.text = p.carDetails!;
    }

    // Auto-confirm the map pin when we have historical coordinates so the
    // user doesn't need to revisit the map screen. Distance / delivery fee
    // are recalculated from the prefilled lat/lng.
    if (p.deliveryLat != null && p.deliveryLng != null) {
      final cart = Provider.of<CartProvider>(context, listen: false);
      cart.addLatLong(p.deliveryLat, p.deliveryLng);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _calculateDistanceToNearestBranch();
      });
    }
  }

  void _logCartData() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    print('\n======== CART DATA PASSED TO CHECKOUT ========');
    print('Total Items: ${cartProvider.cartItems.length}');
    print('Total Price: ${cartProvider.getTotalPrice()}');

    for (int i = 0; i < cartProvider.cartItems.length; i++) {
      final item = cartProvider.cartItems[i];
      print('\nItem ${i + 1}:');
      print('  Product ID: ${item.product.id}');
      print('  Product Name: ${item.displayName}');
      print('  Quantity: ${item.quantity}');
      print('  Base Price: ${item.product.price}');
      print('  Total Price: ${item.totalPrice}');

      if (item.selectedModifiers.isNotEmpty) {
        print('  Selected Modifiers:');
        for (final modifier in item.selectedModifiers) {
          print('    - ID: ${modifier.modifier.id}');
          print('      Name: ${modifier.modifier.name}');
          print('      Price: ${modifier.modifier.price}');
          print('      Quantity: ${modifier.quantity}');
        }
      } else {
        print('  No modifiers selected');
      }
    }
    print('============================================\n');
  }

  // Handle Payme payment for delivery orders
  Future<void> _handlePaymePayment({
    required String name,
    required String phone,
    required String? address,
    required String comment,
    required double total,
    required double latitude,
    required double longitude,
    required CartProvider cartProvider,
    required double deliveryFee,
    required String? branchName,
  }) async {
    // Don't allow Payme for self-pickup and in-restaurant orders
    if (_selectedIndex == 1 || _selectedIndex == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).paymeNotAvailable)),
      );
      return;
    }
    try {
      setState(() {
        _isProcessing = true;
      });

      // Get API service with client credentials
      final remoteConfig = FirebaseRemoteConfig.instance;
      final clientId = remoteConfig.getString('api_client_id');
      final clientSecret = remoteConfig.getString('api_client_secret');

      // Make sure branch name is not null
      if (branchName == null) {
        throw Exception('Branch name is required for Payme payment');
      }

      // Get merchant ID from selected branch config
      final branchConfig = await BranchConfigs.getConfig(branchName);
      final merchantId = branchConfig.merchantId;

      if (merchantId.isEmpty) {
        throw Exception('Payme merchant ID not configured for this branch');
      }

      // Generate a unique order ID for Payme
      final paymeOrderId = PaymeService.generateOrderId();

      // Format cart items for the API
      List<Map<String, dynamic>> formattedItems =
          cartProvider.cartItems.map((item) {
        return {
          "id": item.product.uuid,
          "name": item.product.name,
          "price": item.product.price,
          "quantity": item.quantity,
          "totalPrice": item.product.price * item.quantity,
        };
      }).toList();

      // Calculate the final total including delivery fee and bag price (2000 UZS for delivery, 0 for pickup)
      final double finalTotal = total + deliveryFee;

      print(
          'Payment breakdown: Order total: $total UZS, Delivery fee: $deliveryFee UZS, Final total: $finalTotal UZS');

      // Save the order details for later processing
      await PaymeTransactionService.savePendingOrder(
        orderId: paymeOrderId,
        name: name,
        phone: phone,
        address: address,
        comment: comment,
        total: finalTotal, // Use the final total that includes all fees
        latitude: latitude,
        longitude: longitude,
        deliveryFee: deliveryFee,
        items: formattedItems,
        clientId: clientId,
        clientSecret: clientSecret,
      );

      // Show the transaction status dialog first
      // This will start checking the transaction status every 2 seconds for 5 minutes
      PaymeTransactionService.startTransactionStatusCheck(
          context, paymeOrderId);

      // Launch Payme checkout with the final total that includes delivery fee and bag price
      final launched = await PaymeService.launchPaymeCheckout(
          context, merchantId, paymeOrderId, finalTotal);

      if (!launched) {
        // If we couldn't launch Payme, close the dialog and show error
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
          throw Exception('Could not launch Payme checkout');
        }
      }

      // Note: We don't navigate away - the transaction status check will handle navigation
      // after successful payment
    } catch (e) {
      print('Error handling Payme payment: $e');
      // Show error message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment error: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Handle Payme payment for carhop orders
  Future<void> _handlePaymeCarhopPayment({
    required String name,
    required String phone,
    required String? branchName,
    required String comment,
    required String carDetails,
    required double total,
    required double latitude,
    required double longitude,
    required CartProvider cartProvider,
    required String orderType,
  }) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      // Make sure branch name is not null
      if (branchName == null) {
        throw Exception('Branch name is required for Payme payment');
      }

      // Get branch config for the selected branch
      final branchConfig = await BranchConfigs.getConfig(branchName);
      // Note: BranchConfigs.getConfig always returns a non-null value

      // Get merchant ID from branch config
      final merchantId = branchConfig.merchantId;

      if (merchantId.isEmpty) {
        throw Exception('Payme merchant ID not configured for this branch');
      }

      // Generate a unique order ID for Payme
      final paymeOrderId = PaymeService.generateOrderId();

      // Format order items for Sieves API
      final formattedOrderItems = cartProvider.cartItems
          .map((item) => {
                "actual_price": item.product.price,
                "product_id": item.product.id.toString(),
                "quantity": item.quantity,
                "note": null,
                "inventoryPriceList": [] // Required by the API
              })
          .toList();

      // Create the full request payload
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
        "order_type_id": 8, // for carhop orders
        "orderItems": formattedOrderItems,
        "transactions": [
          {
            "account_id": 1,
            "amount": total,
            "payment_type_id": 4, // 4 for Payme
            "type": "deposit"
          }
        ],
        "value": total,
        "note": "$comment\nCar Details: $carDetails\nPayment Method: Payme",
        "day_session_id": null,
        "pager_number": phone,
        "pos_id": null,
        "pos_session_id": null,
        "delivery_amount": null
      };

      // Save the carhop order details for later processing using PaymeTransactionService
      await PaymeTransactionService.savePendingCarhopOrder({
        'order_id': paymeOrderId,
        'request_body': requestBody,
        'branch_config': {
          'sievesApiCode': branchConfig.sievesApiCode,
          'sievesApiToken': branchConfig.sievesApiToken,
        },
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'cart_items': cartProvider.cartItems
            .map((item) => {
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.price,
                  'carDetails': carDetails
                })
            .toList(),
      });

      // Show the transaction status dialog first
      // This will start checking the transaction status every 2 seconds for 5 minutes
      PaymeTransactionService.startTransactionStatusCheck(
          context, paymeOrderId);

      // Launch Payme checkout immediately after showing the dialog
      final launched = await PaymeService.launchPaymeCheckout(
          context, merchantId, paymeOrderId, total);

      if (!launched) {
        // If we couldn't launch Payme, close the dialog and show error
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close the dialog
          throw Exception('Could not launch Payme checkout');
        }
      }

      // Note: We don't navigate away - the transaction status check will handle navigation
      // after successful payment
    } catch (e) {
      print('Error handling Payme carhop payment: $e');
      // Show error message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment error: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Handle Card payment with Rahmat Pay
  Future<void> _handleCardPayment({
    required String name,
    required String phone,
    required String? branchName,
    required String comment,
    required double total,
    required CartProvider cartProvider,
    required int selectedIndex,
    String? carDetails,
    String? address,
    String? additionalPhone,
  }) async {
    try {
      setState(() {
        _isProcessing = true;
      });

      print('\n======== CARD PAYMENT HANDLER ========');
      print('Branch: $branchName');
      print('Total: $total');
      print('Order Type Index: $selectedIndex');

      // Make sure branch name is not null
      if (branchName == null) {
        throw Exception('Branch name is required for card payment');
      }

      // Get branch config
      final branchConfig = await BranchConfigs.getConfig(branchName);

      // Get bearer token from Sieves API
      // Using the branch's API token as bearer token
      final bearerToken = branchConfig.sievesApiToken;

      // Get order type ID based on selected index
      final orderTypeId = RahmatPayService.getOrderTypeId(selectedIndex);

      // Payment type ID is 10 for RAHMAT
      const paymentTypeId = 10;

      // Prepare note with car details if carhop
      String finalNote = comment;
      if (selectedIndex == 2 && carDetails != null && carDetails.isNotEmpty) {
        finalNote = '$comment\nCar Details: $carDetails';
      }

      // Create invoice
      // Use full phone number for pager_number (strip +998 and keep only digits)
      final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
      final pagerNumber = digitsOnly.startsWith('998') ? digitsOnly.substring(3) : digitsOnly;
      
      // Get nearest branch restaurant ID if available
      String? restaurantId;
      if (_nearestBranch != null && _nearestBranch!['id'] != null) {
        restaurantId = _nearestBranch!['id'].toString();
      }
      
      // Filter cart items: exclude "Пакет" for non-delivery orders (selectedIndex 1, 2, 3)
      // Only delivery (selectedIndex == 0) should include the package
      List<dynamic> filteredCartItems = cartProvider.cartItems;
      double adjustedTotal = total;
      
      if (selectedIndex != 0) {
        // For Self-Pickup, Carhop, and In-Restaurant, remove "Пакет" from cart items
        filteredCartItems = cartProvider.cartItems
            .where((item) => item.product.name != 'Пакет')
            .toList();
        
        // Calculate the package price to subtract from total
        final packageItems = cartProvider.cartItems
            .where((item) => item.product.name == 'Пакет')
            .toList();
        final packageItem = packageItems.isNotEmpty ? packageItems.first : null;
        
        if (packageItem != null) {
          final packagePrice = packageItem.totalPrice;
          adjustedTotal = total - packagePrice;
          print('Removed "Пакет" from order. Package price: $packagePrice UZS');
          print('Adjusted total: $adjustedTotal UZS (was: $total UZS)');
        }
      }
      
      print('Filtered cart items count: ${filteredCartItems.length}');
      print('Final amount to charge: $adjustedTotal UZS');
      
      final invoiceResult = await RahmatPayService.createInvoice(
        branchName: branchName,
        orderTypeId: orderTypeId,
        paymentTypeId: paymentTypeId,
        customerQuantity: 1,
        pagerNumber: pagerNumber,
        note: finalNote,
        amount: (adjustedTotal * 100).toInt(), // Convert to tiyin (multiply by 100)
        lang: 'ru', // TODO: Get from app locale
        cartItems: filteredCartItems,
        bearerToken: bearerToken,
        customerName: name,
        customerPhone: phone,
        deliveryAddress: address,
        latitude: cartProvider.showLat(),
        longitude: cartProvider.showLong(),
        additionalPhone: additionalPhone,
        restaurantId: restaurantId,
        deliveryFee: deliveryFee,
      );

      if (invoiceResult['success'] == true) {
        final shortLink = invoiceResult['short_link'] as String;
        final invoiceId = invoiceResult['invoice_id'] as String?;

        print('Invoice created successfully!');
        print('Short Link: $shortLink');
        print('Invoice ID: $invoiceId');

        // Save pending payment for verification later
        if (invoiceId != null) {
          await RahmatPayService.savePendingCardPayment(
            invoiceId: invoiceId,
            shortLink: shortLink,
            orderData: {
              'name': name,
              'phone': phone,
              'branch': branchName,
              'comment': finalNote,
              'total': adjustedTotal,
              'cart_items': filteredCartItems.map((item) => {
                'name': item.product.name,
                'quantity': item.quantity,
                'price': item.product.price,
              }).toList(),
            },
          );

          // Start the payment status checking dialog
          // This will poll the backend every 3 seconds for payment status
          if (context.mounted) {
            RahmatPayTransactionService.startPaymentStatusCheck(
              context,
              invoiceId,
              branchName,
            );
          }

          // Launch payment URL after showing the status dialog
          final launched = await RahmatPayService.launchPaymentUrl(shortLink);

          if (!launched) {
            // If we couldn't launch the payment URL, close the dialog and show error
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop(); // Close the status dialog
              throw Exception('Could not launch Rahmat Pay checkout');
            }
          }

          // Note: We don't navigate away or show additional dialogs
          // The transaction status check will handle navigation after successful payment
        } else {
          throw Exception('Invoice ID not received from backend');
        }
      } else {
        throw Exception('Failed to create invoice');
      }
    } catch (e) {
      print('Error handling card payment: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Check if there's a pending Payme payment (keeping for reference)
  Future<void> _checkPendingPaymePayment() async {
    final pendingPayment = await PaymeService.getPendingPayment();

    if (pendingPayment != null) {
      // If the payment was initiated more than 30 minutes ago, clear it
      final timestamp = pendingPayment['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > 30 * 60 * 1000) {
        // 30 minutes in milliseconds
        await PaymeService.clearPendingPayment();
        return;
      }

      // Show a dialog to check payment status
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Payme Payment'),
          content: const Text(
              'You have a pending Payme payment. Did you complete the payment?'),
          actions: [
            TextButton(
              onPressed: () async {
                await PaymeService.clearPendingPayment();
                Navigator.pop(context);
              },
              child: const Text('No, Cancel Payment'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Processing payment...'),
                      ],
                    ),
                  ),
                );

                // Simulate payment verification
                // In a real implementation, you would verify with Payme's server
                await Future.delayed(const Duration(seconds: 2));
                await PaymeService.clearPendingPayment();

                // Close loading dialog
                Navigator.pop(context);

                // Show success message
                // ignore: use_build_context_synchronously
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context).orderSuccess),
                    content:
                        Text(AppLocalizations.of(context).orderSuccessSubTitle),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/homeNew');
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Yes, Payment Complete'),
            ),
          ],
        ),
      );
    }
  }


  // Function to calculate distance to the nearest branch using backend API
  Future<void> _calculateDistanceToNearestBranch() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final clientLat = cartProvider.showLat();
    final clientLng = cartProvider.showLong();

    // Only calculate if we have valid coordinates
    if (clientLat != 0.0 && clientLng != 0.0) {
      setState(() {
        _isCalculatingDistance = true;
        _distanceMessage = 'Calculating distance...';
      });

      try {
        print('🔍 CHECKOUT: Fetching nearest branch from backend API');
        print('🔍 CHECKOUT: Client coordinates - Lat: $clientLat, Long: $clientLng');
        // Call backend API
        final url = Uri.parse('https://api.v3.sievesapp.com/branch/nearest?lat=$clientLat&long=$clientLng');
        final response = await http.get(url).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Backend API request timed out');
          },
        );
        print('🔍 CHECKOUT: API Response Status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            final data = responseData['data'];
            final branch = data['branch'];
            final distance = data['distance'];
            final deliveryFeeFromApi = data['deliveryFee'];

            print('✅ CHECKOUT: Nearest branch found: ${branch['name']}');
            print('✅ CHECKOUT: Distance: $distance km');
            print('✅ CHECKOUT: Delivery fee: $deliveryFeeFromApi');
            
            // Store branch information in the format expected by the rest of the code
            final nearestBranch = {
              'name': branch['name'],
              'lat': branch['lat'],
              'lng': branch['lng'],
              'distance': distance,
              'deliveryFee': deliveryFeeFromApi,
              'id': branch['id'],
            };

            setState(() {
              _nearestBranch = nearestBranch;
              _distanceMessage = 'Distance to ${branch['name']}: ${distance.toStringAsFixed(2)} km';
              deliveryFee = double.tryParse(deliveryFeeFromApi.toString()) ?? 0;
              _isCalculatingDistance = false;
            });
          } else {
            throw Exception('Invalid response format from backend');
          }
        } else {
          throw Exception('Backend API returned status ${response.statusCode}');
        }
      } catch (e) {
        print('❌ CHECKOUT: Error fetching nearest branch: $e');
        setState(() {
          _distanceMessage = 'Error calculating distance: $e';
          _isCalculatingDistance = false;
          deliveryFee = 0;
        });
      }
    } else {
      setState(() {
        _distanceMessage = 'Location coordinates not available';
      });
    }
  }

  @override
  void dispose() {
    _carDetailsFocusNode.dispose();
    _carDetailsController.dispose();
    _additionalPhoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _initializeRemoteConfig() async {
    try {
      remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default value as a string
      // await remoteConfig.setDefaults({'chat_id': '-1002074915184'}); Loook Test Bot

      bool updated = await remoteConfig.fetchAndActivate();
      _isRemoteConfigInitialized = true;

      print('Remote config updated: $updated');
      String currentChatId = remoteConfig.getString('chat_id');
      print('Current chat_id from Remote Config: $currentChatId');
    } catch (e) {
      print('Error initializing remote config: $e');
      _isRemoteConfigInitialized = false;
    }
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phoneNumber') ?? 'No number';
    });
  }

  Future<void> _loadAdditionalPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('phoneNumber') ?? '';
    // Extract just the digits from the phone number (remove +998 prefix if present)
    final digitsOnly = userPhone.replaceAll(RegExp(r'[^\d]'), '');
    final phoneDigits = digitsOnly.startsWith('998') ? digitsOnly.substring(3) : digitsOnly;
    
    setState(() {
      _additionalPhoneController.text = phoneDigits;
      clientCommentPhone = phoneDigits;
    });
  }

  // Total price calculation is handled in the build method

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Anonymous';
    });
  }

  Future<void> _loadCarDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCarDetails = prefs.getString('carDetails') ?? '';
    setState(() {
      carDetails = savedCarDetails;
      _carDetailsController.text = savedCarDetails;
    });
  }

  Future<void> _saveCarDetails(String details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('carDetails', details);
  }

  void _updateCommented() {
    setState(() {
      commented = (clientComment.isNotEmpty ? clientComment + ', ' : '') +
          (clientCommentPhone.isNotEmpty
              ? 'Additional Number: ' + clientCommentPhone
              : '');
    });
  }

  void _updateCarDetails() {
    setState(() {
      carDetails = (carDetails.isNotEmpty ? carDetails + ', ' : '') +
          (carDetailsExtraInfo.isNotEmpty
              ? 'Extra Info: ' + carDetailsExtraInfo
              : '');
    });
    // print('Car Details: $carDetails');
  }

  String? selectedAddress;
  String? selectedBranch;
  String? selectedOption;
  String? selectedCity;

  List<String> branches = [
    'Yunusobod',
    'Beruniy',
    'Chilonzor',
    'Maksim Gorkiy',
    'City Boulevard Loook',
    'Yangiyol Loook',
    // 'Test'
  ];
  List<String> city = [
    'Tashkent',
  ];

  // Payment validation is handled directly in the form validation

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);

    orderPrice = cartProvider.getTotalPrice();

    List<String> orderItems = cartProvider.cartItems.map((item) {
      var itemTotal = item.totalPrice;
      total += itemTotal;

      return '${item.displayName}\n Total: ${NumberFormat('#,##0').format(item.totalPrice.toInt())} сум\n';
    }).toList();

    if (_selectedIndex == 0) {
      orderType = 'Delivery';
    } else if (_selectedIndex == 1) {
      orderType = 'Self-Pickup';
    } else if (_selectedIndex == 2) {
      orderType = 'Carhop';
    } else {
      orderType = 'In-Restaurant';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 15.w),
                Text(
                  AppLocalizations.of(context).chooseOrderType,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 170.w),
              ],
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                children: [
                  // First row - Delivery and Self-Pickup
                  Row(
                    children: [
                      // Delivery button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 0;
                              // Keep Payme selection for delivery
                            });
                          },
                          child: Container(
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: _selectedIndex == 0
                                  ? const Color(0xffFEC700)
                                  : const Color(0xffF1F2F7),
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: _selectedIndex == 0
                                    ? const Color(0xffFEC700)
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delivery_dining_outlined,
                                  color: Colors.black,
                                  size: 28.w,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppLocalizations.of(context).delivery,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Self-pickup button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 1;
                              if (selectedOption == 'Payme') {
                                selectedOption = null;
                              }
                            });
                          },
                          child: Container(
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: _selectedIndex == 1
                                  ? const Color(0xffFEC700)
                                  : const Color(0xffF1F2F7),
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: _selectedIndex == 1
                                    ? const Color(0xffFEC700)
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.black,
                                  size: 28.w,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppLocalizations.of(context).selfPickup,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Second row - Carhop and In-Restaurant
                  Row(
                    children: [
                      // Carhop button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 2;
                              // Keep Payme selection for carhop
                            });
                          },
                          child: Container(
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: _selectedIndex == 2
                                  ? const Color(0xffFEC700)
                                  : const Color(0xffF1F2F7),
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: _selectedIndex == 2
                                    ? const Color(0xffFEC700)
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.car_repair_outlined,
                                  color: Colors.black,
                                  size: 28.w,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  'Carhop',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // In-Restaurant button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = 3;
                              // Reset Payme selection if selected
                              if (selectedOption == 'Payme') {
                                selectedOption = null;
                              }
                            });
                          },
                          child: Container(
                            height: 80.h,
                            decoration: BoxDecoration(
                              color: _selectedIndex == 3
                                  ? const Color(0xffFEC700)
                                  : const Color(0xffF1F2F7),
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                color: _selectedIndex == 3
                                    ? const Color(0xffFEC700)
                                    : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  color: Colors.black,
                                  size: 28.w,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppLocalizations.of(context).inRestaurant,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 15, right: 15),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        _selectedIndex == 0
                            ? AppLocalizations.of(context).yourDeliveryLocation
                            : _selectedIndex == 1
                                ? AppLocalizations.of(context).selfPickupTitle
                                : _selectedIndex == 2
                                    ? AppLocalizations.of(context).carhopService
                                    : AppLocalizations.of(context).inRestaurantTitle,
                        style: TextStyle(
                            fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // DELIVERY
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapScreen(),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            selectedAddress = result;
                          });

                          // Calculate distance after address selection
                          _calculateDistanceToNearestBranch();
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15.w),
                        child: Container(
                          height: 140.h,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            color: const Color(0xFFF1F2F7),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(15.r),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)
                                            .yourDeliveryLocation,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 20.sp,
                                        ),
                                      ),
                                      SvgPicture.asset(
                                          'images/close_black.svg'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                      left: 15.w,
                                      right: 15.w,
                                      bottom: 15.h,
                                      top: 10.h),
                                  child: Text(
                                    selectedAddress ??
                                        AppLocalizations.of(context)
                                            .chooseYourLocation,
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // SELF-PICKUP
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Container(
                        height: 140.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: const Color(0xFFF1F2F7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(15.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).chooseBranchToPick,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 20.sp),
                              ),
                              SizedBox(height: 10.h),
                              DropdownButton<String>(
                                value: selectedBranch,
                                hint: Text(
                                  AppLocalizations.of(context).selectBranch,
                                ),
                                dropdownColor: const Color(0xFFF1F2F7),
                                isExpanded: true,
                                items: branches.map((String branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch,
                                    child: Text(branch),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedBranch = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // CARHOP
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: SizedBox(
                        height: _selectedIndex == 2 ? 480.h : 140.h,
                        width: double.infinity,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15.r),
                                color: const Color(0xFFF1F2F7),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(15.r),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButton<String>(
                                            value: selectedCity,
                                            hint: Text(
                                                AppLocalizations.of(context)
                                                    .selectRegion),
                                            isExpanded: true,
                                            dropdownColor:
                                                const Color(0xFFF1F2F7),
                                            items: city.map((String city) {
                                              return DropdownMenuItem<String>(
                                                value: city,
                                                child: Text(
                                                  city,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14.sp),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedCity = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                        if (selectedCity != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                selectedCity = null;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 10.h),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButton<String>(
                                            value: selectedBranch,
                                            hint: Text(
                                                AppLocalizations.of(context)
                                                    .selectBranch),
                                            isExpanded: true,
                                            dropdownColor:
                                                const Color(0xFFF1F2F7),
                                            items:
                                                branches.map((String branch) {
                                              return DropdownMenuItem<String>(
                                                value: branch,
                                                child: Text(
                                                  branch,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14.sp),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                selectedBranch = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                        if (selectedBranch != null)
                                          IconButton(
                                            icon: const Icon(Icons.clear,
                                                color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                selectedBranch = null;
                                              });
                                            },
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 22.h),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                AppLocalizations.of(context)
                                    .carhopServiceBranchInfo,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14.sp),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Container(
                              height: 158.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F2F7),
                                borderRadius: BorderRadius.circular(15.r),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                    top: 20.h, right: 15.w),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Align(
                                          alignment: Alignment.topRight,
                                          child: SvgPicture.asset(
                                              'images/carhopMetka.svg'),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      flex: 6,
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                selectedBranch != null
                                                    ? "$selectedBranch - LOOOK"
                                                    : AppLocalizations.of(
                                                            context)
                                                        .selectBranch,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFff0000),
                                                ),
                                              ),
                                              if (selectedBranch != null) ...[
                                                SizedBox(height: 5.h),
                                                Text(
                                                  BranchData.getBranchAddress(
                                                      selectedBranch),
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xff5B5B5B),
                                                  ),
                                                ),
                                              ],
                                              SizedBox(height: 15.h),
                                              Text(
                                                '${AppLocalizations.of(context).openingHours} 9:00-00:00',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                              SizedBox(height: 15.h),
                                              Row(
                                                children: [
                                                  SvgPicture.asset(
                                                      'images/mapPointer.svg'),
                                                  SizedBox(width: 15.w),
                                                  GestureDetector(
                                                    onTap: () {
                                                      BranchLocations.openMap(
                                                          selectedBranch);
                                                    },
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)
                                                          .viewInMap,
                                                      style: TextStyle(
                                                        color:
                                                            const Color(0xFF1C90E1),
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Column(
                                children: [
                                  Text(
                                    AppLocalizations.of(context).carDetails,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 5.h),
                            SizedBox(height: 5.h),
                            Container(
                              width: double.infinity,
                              height: 48.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  FocusScope.of(context)
                                      .requestFocus(_carDetailsFocusNode);
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10.w),
                                  child: TextField(
                                    focusNode: _carDetailsFocusNode,
                                    autocorrect: false,
                                    controller: _carDetailsController,
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)
                                          .carDetailsHint,
                                      hintStyle: TextStyle(fontSize: 12.sp),
                                      border: InputBorder.none,
                                      contentPadding:
                                          EdgeInsets.only(left: 15.w),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        carDetails = value;
                                        _updateCarDetails();
                                      });
                                      _saveCarDetails(value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // IN-RESTAURANT
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Container(
                        height: 140.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          color: const Color(0xFFF1F2F7),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(15.r),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).chooseBranchToPick,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 20.sp),
                              ),
                              SizedBox(height: 10.h),
                              DropdownButton<String>(
                                value: selectedBranch,
                                hint: Text(
                                  AppLocalizations.of(context).selectBranch,
                                ),
                                dropdownColor: const Color(0xFFF1F2F7),
                                isExpanded: true,
                                items: branches.map((String branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch,
                                    child: Text(branch),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedBranch = newValue;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 40.0,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 200.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.r),
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFFD9D9D9),
                      offset: Offset(0, 7),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).orderPrice} :',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          Text(
                              '${NumberFormat('#,##0').format(orderPrice)} UZS'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).deliveryPrice} :',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          _selectedIndex == 0 && _isCalculatingDistance
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.amber),
                                  ),
                                )
                              : Text(
                                  _selectedIndex == 0 &&
                                          _nearestBranch != null &&
                                          _nearestBranch!['deliveryFee'] != null
                                      ? '${_nearestBranch!['deliveryFee'].toString()} UZS'
                                      : AppLocalizations.of(context).unknown,
                                ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15.r),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).totalPrice} :',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _selectedIndex == 0
                                ? (_nearestBranch != null &&
                                        _nearestBranch!['deliveryFee'] != null
                                    ? '${NumberFormat('#,##0').format(orderPrice + (_nearestBranch!['deliveryFee'] as num))} UZS'
                                    : '${NumberFormat('#,##0').format(orderPrice)} UZS')
                                : '${NumberFormat('#,##0').format(orderPrice)} UZS',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).paymentMethod,
                  labelStyle: const TextStyle(color: Colors.black),
                ),
                dropdownColor: const Color(0xFFF1F2F7),
                value: selectedOption,
                isExpanded: true,
                items: [
                  DropdownMenuItem<String>(
                    value: 'Card',
                    child: Row(
                      children: [
                        const Icon(Icons.credit_card, color: Colors.blue),
                        SizedBox(width: 10.w),
                        Text(AppLocalizations.of(context).card),
                      ],
                    ),
                  ),
                  if (_selectedIndex == 1 || _selectedIndex == 2 || _selectedIndex == 3)
                    DropdownMenuItem<String>(
                      value: 'Cash',
                      child: Row(
                        children: [
                          const Icon(Icons.payment, color: Colors.purple),
                          SizedBox(width: 10.w),
                          Text(AppLocalizations.of(context).cash),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedOption = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).additionalNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    height: 48.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.black26,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Text(
                            '+998',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _additionalPhoneController,
                            decoration: InputDecoration(
                              hintText:
                                  AppLocalizations.of(context).numberHintText,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              isDense: true,
                            ),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            onChanged: (value) {
                              setState(() {
                                clientCommentPhone = value;
                                _updateCommented();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40.h),
                  Text(
                    AppLocalizations.of(context).comments,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    height: 100.h,
                    width: MediaQuery.of(context).size.width - 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          clientComment = value;
                          _updateCommented();
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            // Show warning message when delivery fee is not calculated in delivery mode
            _selectedIndex == 0 && deliveryFee <= 0
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      AppLocalizations.of(context).deliveryFeeSpinner,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: (_selectedIndex == 0
                      ? selectedAddress != null &&
                          selectedOption != null &&
                          !_isProcessing &&
                          deliveryFee > 0 // Ensure delivery fee is calculated
                      : _selectedIndex == 1
                          ? selectedBranch != null &&
                              selectedOption != null &&
                              !_isProcessing
                          : _selectedIndex == 2
                              ? selectedCity !=
                                      null && // Add check for selectedCity
                                  selectedBranch != null &&
                                  selectedOption != null &&
                                  carDetails != null &&
                                  carDetails!.trim().isNotEmpty &&
                                  !_isProcessing
                              : _selectedIndex == 3
                                  ? selectedBranch != null &&
                                      selectedOption != null &&
                                      !_isProcessing
                                  : false)
                  ? () async {
                      setState(() {
                        _isProcessing = true; // Start processing
                      });

                      // Check if payment type is Card
                      if (selectedOption == 'Card') {
                        try {
                          // Handle Card payment based on order type
                          String? branchForPayment;
                          
                          if (_selectedIndex == 0) {
                            // For delivery orders, use the nearest branch
                            if (_nearestBranch == null) {
                              throw Exception(
                                  'Unable to determine nearest branch for delivery. Please try again.');
                            }
                            branchForPayment = _nearestBranch!['name'] as String;
                          } else {
                            // For other order types, use selected branch
                            if (selectedBranch == null) {
                              throw Exception('Please select a branch before proceeding with payment');
                            }
                            branchForPayment = selectedBranch;
                          }

                          // Handle card payment for all order types
                          await _handleCardPayment(
                            name: firstName,
                            phone: phoneNumber,
                            branchName: branchForPayment,
                            comment: commented,
                            total: _selectedIndex == 0 
                                ? orderPrice + deliveryFee 
                                : orderPrice,
                            cartProvider: cartProvider,
                            selectedIndex: _selectedIndex,
                            carDetails: _selectedIndex == 2 ? carDetails : null,
                            address: _selectedIndex == 0 ? selectedAddress : null,
                            additionalPhone: clientCommentPhone.isNotEmpty ? clientCommentPhone : null,
                          );

                          // Reset processing state
                          setState(() {
                            _isProcessing = false;
                          });

                          // Return early - payment flow handled
                          return;
                        } catch (e) {
                          print('Error handling Card payment: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Error processing Card payment: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() {
                            _isProcessing = false;
                          });
                          return;
                        }
                      }


                      try {
                        // First try to use the new API endpoint
                        bool apiSuccess = false;

                        // Handle different order types
                        if (_selectedIndex == 0) {
                          // Delivery order
                          try {
                            apiSuccess = await sendOrderToApi(
                              selectedAddress, // address
                              firstName, // name
                              phoneNumber, // phone
                              selectedOption!, // paymentType
                              commented, // comment
                              orderPrice, // total
                              cartProvider.showLat(), // latitude
                              cartProvider.showLong(), // longitude
                              cartProvider,
                              deliveryFee:
                                  deliveryFee, // Add delivery fee from nearest branch
                            );
                          } catch (e) {
                            print('Error with delivery order API: $e');
                            apiSuccess = false;
                          }
                        } else if (_selectedIndex == 1) {
                          // Self-pickup order
                          if (selectedBranch == null) {
                            throw Exception('Please select a branch for self-pickup');
                          }
                          await sendSelfPickupOrderToSieves(
                            branchName: selectedBranch!,
                            name: firstName,
                            phone: phoneNumber,
                            paymentType: selectedOption!,
                            comment: commented,
                            total: orderPrice,
                            cartProvider: cartProvider,
                            isInRestaurant: false,
                          );
                          apiSuccess = true;
                        } else if (_selectedIndex == 2) {
                          // Carhop order
                          if (selectedBranch == null) {
                            throw Exception('Please select a branch for carhop order');
                          }
                          // For carhop, we need to send to Sieves API with order_type_id 8
                          await sendSelfPickupOrderToSieves(
                            branchName: selectedBranch!,
                            name: firstName,
                            phone: phoneNumber,
                            paymentType: selectedOption!,
                            comment: "$commented\nCar Details: $carDetails",
                            total: orderPrice,
                            cartProvider: cartProvider,
                            isInRestaurant: false,
                            isCarhop: true, // Mark as carhop order
                          );
                          apiSuccess = true;
                        } else if (_selectedIndex == 3) {
                          // In-restaurant order
                          if (selectedBranch == null) {
                            throw Exception('Please select a branch for in-restaurant order');
                          }
                          // Calculate total excluding "Пакет" (package)
                          final packageItem = cartProvider.cartItems.firstWhere(
                            (item) => item.product.name == 'Пакет',
                            orElse: () => cartProvider.cartItems.first,
                          );
                          final packagePrice = packageItem.product.name == 'Пакет' 
                              ? packageItem.totalPrice 
                              : 0.0;
                          final adjustedTotal = orderPrice - packagePrice;
                          
                          await sendSelfPickupOrderToSieves(
                            branchName: selectedBranch!,
                            name: firstName,
                            phone: phoneNumber,
                            paymentType: selectedOption!,
                            comment: commented,
                            total: adjustedTotal,
                            cartProvider: cartProvider,
                            isInRestaurant: true,
                          );
                          apiSuccess = true;
                        }
                        
                        // Reset processing state
                        setState(() {
                          _isProcessing = false;
                        });

                        // Show success message
                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              AppLocalizations.of(context).orderSuccess,
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            content: Text(AppLocalizations.of(context)
                                .orderSuccessSubTitle),
                            contentPadding: const EdgeInsets.only(
                                top: 30, left: 30, right: 30),
                            actions: [
                              const SizedBox(height: 20),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pushNamed(context, '/homeNew');
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                  ),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        // Reset processing state
                        setState(() {
                          _isProcessing = false;
                        });

                        // Handle error
                        print('Error during order submission: $e');
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Order Error'),
                            content: Text(
                                'Failed to place your order: ${e.toString().length > 100 ? e.toString().substring(0, 100) + '...' : e.toString()}\n\nPlease try again later.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      } finally {
                        setState(() {
                          _isProcessing = false;
                        });
                      }
                    }
                  : null,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                  (_selectedIndex == 0 &&
                              selectedAddress != null &&
                              selectedOption != null &&
                              deliveryFee > 0) ||
                          (_selectedIndex == 1 &&
                              selectedBranch != null &&
                              selectedOption != null) ||
                          (_selectedIndex == 2 &&
                              selectedCity !=
                                  null && // Add check for selectedCity
                              selectedBranch != null &&
                              selectedOption != null &&
                              carDetails != null &&
                              carDetails!.trim().isNotEmpty) ||
                          (_selectedIndex == 3 &&
                              selectedBranch != null &&
                              selectedOption != null)
                      ? const Color(0xffFEC700) // Enabled state
                      : const Color(0xFFCCCCCC), // Disabled state
                ),
              ),
              child: _isProcessing
                  ? Padding(
                      padding: EdgeInsets.all(12.r),
                      child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 15.h, horizontal: 125.w),
                      child: Text(
                        AppLocalizations.of(context).order,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          color: Colors.black,
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 50.h),
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context).checkout,
        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const Cart()));
        },
        child: SizedBox(
          height: 25.h,
          width: 25.w,
          child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
        ),
      ),
    );
  }

  Future<String> getChatId() async {
    try {
      if (!_isRemoteConfigInitialized) {
        await _initializeRemoteConfig();
      }

      String chatId = remoteConfig.getString('chat_id');
      if (chatId.isEmpty) {
        print('Using default chat_id as Remote Config value was empty');
        return '-1002074915184';
      }

      print('Retrieved chat_id from Remote Config: $chatId');
      return chatId;
    } catch (e) {
      print('Error getting chat_id: $e');
      return '-1002074915184';
    }
  }

  Future<bool> sendOrderToApi(
      String? address,
      String name,
      String phone,
      String paymentType,
      String comment,
      double total,
      double latitude,
      double longitude,
      CartProvider cartProvider,
      {double deliveryFee = 0}) async {
    try {
      // For self-pickup orders, use Telegram API instead of Delever API
      // if (_selectedIndex == 1) {
      //   try {
      //     List<String> orderItems = cartProvider.cartItems.map((item) {
      //       return '${item.displayName}\n Total: ${NumberFormat('#,##0').format(item.totalPrice.toInt())} сум\n';
      //     }).toList();
      //
      //     await sendOrderToTelegram(
      //       null, // No address for self-pickup
      //       selectedBranch ?? '',
      //       name,
      //       phone,
      //       paymentType,
      //       comment,
      //       orderItems,
      //       total,
      //       latitude,
      //       longitude,
      //       'Self-Pickup',
      //       '', // No car details for self-pickup
      //       cartProvider,
      //     );
      //
      //     // Clear the cart after successful order
      //     cartProvider.clearCart();
      //
      //     // Show success dialog
      //     if (mounted) {
      //       _showOrderSuccessDialog(
      //           'self-pickup-${DateTime.now().millisecondsSinceEpoch}');
      //     }
      //
      //     return true;
      //   } catch (e) {
      //     print('Error sending self-pickup order to Telegram: $e');
      //     return false;
      //   }
      // }

      // For delivery orders, continue with the Delever API
      // Get API service with client credentials
      final remoteConfig = FirebaseRemoteConfig.instance;
      final clientId = remoteConfig.getString('api_client_id');
      final clientSecret = remoteConfig.getString('api_client_secret');

      final apiService = ApiService(
        clientId: clientId,
        clientSecret: clientSecret,
      );

      // Format cart items for the API
      List<Map<String, dynamic>> formattedItems =
          cartProvider.cartItems.map((item) {
        return {
          "id": item.product.uuid, // Use the UUID from the product model
          "name": item.displayName, // Include modifier names
          "price": item.product.price,
          "quantity": item.quantity,
          "totalPrice":
              item.totalPrice, // Use totalPrice which includes modifiers
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

      print('Formatted items with UUIDs: ${json.encode(formattedItems)}');

      // Send the order using the API service
      final response = await apiService.createOrder(
        clientName: name,
        phoneNumber: phone,
        latitude: latitude,
        longitude: longitude,
        address: address ?? 'No address provided',
        items: formattedItems,
        totalCost: total,
        paymentType:
            paymentType.toLowerCase(), // Pass the actual payment type as is
        comment: comment,
        persons: 1,
        deliveryFee: deliveryFee,
      );

      print('Order submitted successfully: ${response.toString()}');

      // Get the order ID from the response
      String orderId;
      print('Full API response: ${response.toString()}');

      if (response.containsKey('orderId')) {
        // Format: {"result": "OK", "orderId": "2d968150-48e6-4730-bfbf-0403187b54d1"}
        orderId = response['orderId'].toString();
        print('Using orderId from API response: $orderId');
      } else if (response.containsKey('id')) {
        orderId = response['id'].toString();
        print('Using id from API response: $orderId');
      } else if (response.containsKey('eatsId')) {
        orderId = response['eatsId'].toString();
        print('Using eatsId from API response: $orderId');
      } else {
        // Fallback to timestamp only if no ID is found in the response
        orderId = DateTime.now().millisecondsSinceEpoch.toString();
        print('No order ID found in response, using timestamp: $orderId');
      }

      // Log the order status endpoint that will be used for tracking
      print('ORDER TRACKING: Order submitted successfully with ID: $orderId');
      print(
          'ORDER TRACKING: Status endpoint will be: https://integrator.api.delever.uz/v1/order/$orderId/status');

      // Immediately try to fetch the initial status to verify the endpoint works
      try {
        print('ORDER TRACKING: Attempting to fetch initial status...');
        final statusResponse = await apiService.getOrderStatus(orderId);
        print('ORDER TRACKING: Initial status response: $statusResponse');
      } catch (e) {
        print('ORDER TRACKING: Error fetching initial status: $e');
      }


      // Add order notification
      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.addOrderNotification(
        title: "New Order",
        body: "Your order has been placed successfully!",
        messageId: orderId,
      );

      // Clear the cart
      cartProvider.clearCart();

      // Show success dialog with option to track order
      // if (mounted) {
      //   _showOrderSuccessDialog(orderId);
      // }

      return true;
    } catch (e) {
      print('Error submitting order to API: $e');
      return false;
    }
  }

  // Show order success dialog with tracking option
  void _showOrderSuccessDialog(String orderId) {
    final localizations = AppLocalizations.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(localizations.orderPlacedSuccess),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                  '${localizations.yourOrderText} #$orderId ${localizations.hasBeenPlaced}'),
              const SizedBox(height: 8),
              Text(localizations.trackOrderMessage),
            ],
          ),
          actions: [
            TextButton(
              child: Text(localizations.closeButton),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to previous screen
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEC700),
                foregroundColor: Colors.black,
              ),
              child: Text(localizations.trackOrderButton),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/orderTracking');
              },
            ),
          ],
        );
      },
    );
  }


  // Send self-pickup order to Sieves API
  Future<void> sendSelfPickupOrderToSieves({
    required String branchName,
    required String name,
    required String phone,
    required String paymentType,
    required String comment,
    required double total,
    required CartProvider cartProvider,
    bool isInRestaurant = false,
    bool isCarhop = false,
  }) async {
    try {
      if (branchName.isEmpty) {
        throw Exception('Please select a branch first');
      }

      final branchConfig = await BranchConfigs.getConfig(branchName);
      
      // Format order items for Sieves API
      // Filter out "Пакет" (package) for in-restaurant orders
      final itemsToProcess = isInRestaurant
          ? cartProvider.cartItems.where((item) => item.product.name != 'Пакет').toList()
          : cartProvider.cartItems;
      
      final List<Map<String, dynamic>> formattedOrderItems =
          itemsToProcess.map((item) {
        final String? productUuid = item.product.uuid;
        if (productUuid == null || productUuid.isEmpty) {
          print(
              'WARNING: Missing UUID for product ${item.product.name} (ID: ${item.product.id})');
        }
        final String productIdentifier =
            productUuid ?? item.product.id.toString();
        print(
            'Self-Pickup: Using product identifier: $productIdentifier for ${item.product.name}');

        return {
          "actual_price": item.totalPrice / item.quantity,
          "product_id": productIdentifier,
          "quantity": item.quantity,
          "note": item.selectedModifiers.isNotEmpty
              ? "Modifiers: ${item.selectedModifiers.map((m) => m.modifier.name).join(", ")}"
              : null,
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

      // Prepare the request body for Sieves API
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
        "order_type_id": isCarhop ? 8 : (isInRestaurant ? 1 : 2), // 8 for carhop, 1 for in-restaurant, 2 for self-pickup
        "orderItems": formattedOrderItems,
        "transactions": [
          {
            "account_id": 1,
            "amount": total,
            "payment_type_id": paymentType.toLowerCase() == 'card'
                ? 1
                : (paymentType.toLowerCase() == 'payme' ? 3 : 2),
            "type": "deposit"
          }
        ],
        "value": total,
        "note": isCarhop
            ? comment // Carhop comment already includes car details
            : (isInRestaurant
                ? (comment.isNotEmpty ? "В ресторане\n$comment" : "В ресторане")
                : (comment.isNotEmpty ? "С Сабой\n$comment" : "С Сабой")),
        "day_session_id": null,
        "pager_number": phone.replaceFirst('+998', ''),
        "pos_id": null,
        "pos_session_id": null,
        "delivery_amount": null
      };

      // If payment type is CASH, send to custom API endpoint
      if (paymentType.toLowerCase() == 'cash') {
        print('\n===== CASH PAYMENT DETECTED - Sending to Custom API =====');
        
        // API endpoint - will be called with ?code={branchConfig.sievesApiCode}&isCarhop=1
        const String customApiEndpoint = 'https://api.sievesapp.com/v1/order';
        
        // Determine order type ID based on order type
        final int orderTypeId = isCarhop ? 8 : (isInRestaurant ? 1 : 2); // 8 for carhop, 1 for in-restaurant, 2 for self-pickup
        
        // Remove +998 prefix from phone number
        final String cleanPhone = phone.replaceFirst('+998', '');
        
        // Send to custom API using RahmatPayService
        final customApiResult = await RahmatPayService.sendCashOrderToApi(
          apiEndpoint: customApiEndpoint,
          branchName: branchName,
          orderTypeId: orderTypeId,
          customerQuantity: 1,
          pagerNumber: cleanPhone,
          note: isCarhop
              ? comment // Carhop comment already includes car details
              : (isInRestaurant
                  ? (comment.isNotEmpty ? "В ресторане\n$comment" : "В ресторане")
                  : (comment.isNotEmpty ? "С Сабой\n$comment" : "С Сабой")),
          amount: total,
          cartItems: itemsToProcess,
        );
        
        print('Custom API response: ${customApiResult['data']}');
        print('===== END CASH PAYMENT - Custom API Call =====\n');
        
        // Parse the response and handle success
        final responseData = customApiResult['data'];
        
        // Extract order ID from response (handle different possible structures)
        final orderId = responseData?['id']?.toString() ?? 
                       responseData?['order_id']?.toString() ?? 
                       DateTime.now().millisecondsSinceEpoch.toString();
        
        print('Order ID for notification: $orderId');
        
        // Add order notification
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.addOrderNotification(
          title: isCarhop 
              ? "New Carhop Order" 
              : (isInRestaurant ? "New In-Restaurant Order" : "New Self-Pickup Order"),
          body: isCarhop
              ? "Your carhop order has been placed successfully!"
              : (isInRestaurant 
                  ? "Your in-restaurant order has been placed successfully!"
                  : "Your self-pickup order has been placed successfully!"),
          messageId: orderId,
        );

        // Update order tracking notification indicator
        final orderTrackingService = OrderTrackingService();
        orderTrackingService.markNewOrderAdded();

        // Clear cart
        cartProvider.clearCart();
        
        // Navigate to home page
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/homeNew', (route) => false);
        }
        return;
      }
    } catch (e) {
      print('Error sending self-pickup order: $e');
      rethrow;
    }
  }
}

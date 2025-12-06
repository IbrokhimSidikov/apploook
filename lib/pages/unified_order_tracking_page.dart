import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/services/order_history_service.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/widget/api_order_tracking_card.dart';
import 'package:http/http.dart' as http;

class UnifiedOrderTrackingPage extends StatefulWidget {
  const UnifiedOrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<UnifiedOrderTrackingPage> createState() =>
      _UnifiedOrderTrackingPageState();
}

class _UnifiedOrderTrackingPageState extends State<UnifiedOrderTrackingPage>
    with SingleTickerProviderStateMixin {
  final OrderHistoryService _orderHistoryService = OrderHistoryService();
  final OrderTrackingService _trackingService = OrderTrackingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveryOrders = [];
  List<Map<String, dynamic>> _carhopOrders = [];
  List<Map<String, dynamic>> _selfPickupOrders = [];
  String? _updatingOrderId;
  Set<String> _arrivedOrders = {};

  // Track new orders for each tab
  int _newDeliveryOrders = 0;
  int _newCarhopOrders = 0;
  int _newSelfPickupOrders = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Add listener to clear notification for the active tab
    _tabController.addListener(_handleTabChange);

    // Load both types of orders
    _loadOrders();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Clear notification indicator for the selected tab
        if (_tabController.index == 0) {
          _newDeliveryOrders = 0;
        } else if (_tabController.index == 1) {
          _newCarhopOrders = 0;
        } else {
          _newSelfPickupOrders = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get previous counts to calculate new orders
      final prevDeliveryCount = _deliveryOrders.length;
      final prevCarhopCount = _carhopOrders.length;
      final prevSelfPickupCount = _selfPickupOrders.length;

      // Fetch orders from API
      final response = await _orderHistoryService.fetchOrderHistory(
        page: 1,
        limit: 50,
      );

      final orders = (response['data'] as List<dynamic>? ?? [])
          .map((order) => order as Map<String, dynamic>)
          .toList();

      // Sort orders by time (newest first)
      orders.sort((a, b) {
        final aTime = DateTime.parse(a['time'] ?? '');
        final bTime = DateTime.parse(b['time'] ?? '');
        return bTime.compareTo(aTime);
      });

      // Separate orders by type
      final deliveryOrders = orders
          .where((order) => order['order_type_id'] == 1 || order['order_type_id'] == 3)
          .toList();
      final carhopOrders = orders
          .where((order) => order['order_type_id'] == 8)
          .toList();
      final selfPickupOrders = orders
          .where((order) => order['order_type_id'] == 7)
          .toList();

      // Calculate new orders (only if there are more orders than before)
      final newDeliveryOrders = deliveryOrders.length > prevDeliveryCount
          ? deliveryOrders.length - prevDeliveryCount
          : 0;
      final newCarhopOrders = carhopOrders.length > prevCarhopCount
          ? carhopOrders.length - prevCarhopCount
          : 0;
      final newSelfPickupOrders = selfPickupOrders.length > prevSelfPickupCount
          ? selfPickupOrders.length - prevSelfPickupCount
          : 0;

      setState(() {
        _deliveryOrders = deliveryOrders;
        _carhopOrders = carhopOrders;
        _selfPickupOrders = selfPickupOrders;

        // Update notification counts (don't reset the current tab)
        if (_tabController.index != 0) {
          _newDeliveryOrders += newDeliveryOrders;
        }
        if (_tabController.index != 1) {
          _newCarhopOrders += newCarhopOrders;
        }
        if (_tabController.index != 2) {
          _newSelfPickupOrders += newSelfPickupOrders;
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show confirmation dialog before clearing all orders
  Future<void> _showClearConfirmationDialog(int tabIndex) async {
    final localizations = AppLocalizations.of(context);
    String orderType = tabIndex == 0 ? 'delivery' : (tabIndex == 1 ? 'carhop' : 'self-pickup/in-restaurant');
    
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.clearAll),
            content: Text('Are you sure you want to clear all $orderType order history? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  localizations.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (tabIndex == 0) {
          // Clear delivery orders
          final success = await _trackingService.clearAllOrders();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All delivery orders cleared')),
            );
          }
        } else if (tabIndex == 1) {
          // Clear carhop orders
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('carhop_orders', []);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All carhop orders cleared')),
            );
          }
        } else {
          // Clear self-pickup orders
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('selfpickup_orders', []);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All self-pickup/in-restaurant orders cleared')),
            );
          }
        }

        // Reload orders
        _loadOrders();
      } catch (e) {
        print('Error clearing orders: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing orders')),
          );
        }
      }
    }
  }

  Future<void> updateCarhopOrderStatus(String orderId) async {
    // If already arrived, show a message and return
    if (_arrivedOrders.contains(orderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).alreadyArrived),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _updatingOrderId = orderId;
    });

    final String url =
        'https://app.sievesapp.com/v1/order/$orderId?isDelever=1';

    final Map<String, dynamic> requestBody = {
      "id": orderId,
      "customer_arrived": 1,
      "is_sync": 0,
    };

    const String bearerToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiZWFyZXIiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.fo1-6HkjCqoQ_m4cCO6laUgHHBBqktz0SAgmOi6axqQ";
    const String xApiKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ODk4ODkiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.twqu6OB88osWslaoMr6UDH8RNuSX095LlEf0OVdDglY";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'x-api': xApiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _arrivedOrders.add(orderId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).arrivedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).arrivedError),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).arrivedError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingOrderId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.orderTracking),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            tabs: [
            Tab(
              height: 66,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delivery_dining),
                        const SizedBox(height: 2),
                        Text(
                          localizations.deliveryOrders,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_newDeliveryOrders > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_newDeliveryOrders',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              height: 66,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_parking),
                        const SizedBox(height: 2),
                        Text(
                          localizations.carhopOrders,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_newCarhopOrders > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_newCarhopOrders',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              height: 66,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag),
                        const SizedBox(height: 2),
                        Text(
                          'Pickup/Dine-In',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_newSelfPickupOrders > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_newSelfPickupOrders',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
          // Test uchun
          // Builder(
          //   builder: (context) {
          //     return IconButton(
          //       icon: const Icon(Icons.delete_outline),
          //       onPressed: () {
          //         // Clear orders based on current tab
          //         _showClearConfirmationDialog(_tabController.index);
          //       },
          //       tooltip: 'Clear all orders',
          //     );
          //   },
          // ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Delivery Orders Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _deliveryOrders.isEmpty
                  ? _buildEmptyState(0)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _deliveryOrders.length,
                        itemBuilder: (context, index) {
                          return ApiOrderTrackingCard(
                            orderData: _deliveryOrders[index],
                          );
                        },
                      ),
                    ),

          // Carhop Orders Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _carhopOrders.isEmpty
                  ? _buildEmptyState(1)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _carhopOrders.length,
                        itemBuilder: (context, index) {
                          final order = _carhopOrders[index];
                          
                          return Column(
                            children: [
                              ApiOrderTrackingCard(
                                orderData: order,
                              ),
                              // Arrived Button for Carhop Orders
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    updateCarhopOrderStatus(order['id'].toString());
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _arrivedOrders.contains(order['id'].toString())
                                          ? Colors.grey[300]
                                          : const Color(0xFFFEC700),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_updatingOrderId == order['id'].toString())
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            ),
                                          )
                                        else
                                          const Icon(
                                            Icons.directions_car_rounded,
                                            size: 20,
                                            color: Colors.black,
                                          ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _arrivedOrders.contains(order['id'].toString())
                                              ? localizations.alreadyArrived
                                              : localizations.arrived,
                                          style: TextStyle(
                                            color: _arrivedOrders.contains(order['id'].toString())
                                                ? Colors.grey[600]
                                                : Colors.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
                    ),

          // Self-Pickup & In-Restaurant Orders Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _selfPickupOrders.isEmpty
                  ? _buildEmptyState(2)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _selfPickupOrders.length,
                        itemBuilder: (context, index) {
                          return ApiOrderTrackingCard(
                            orderData: _selfPickupOrders[index],
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(int tabIndex) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            tabIndex == 0 ? Icons.receipt_long : (tabIndex == 1 ? Icons.directions_car : Icons.shopping_bag),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            tabIndex == 0
                ? localizations.noDeliveryOrders
                : (tabIndex == 1 ? localizations.noCarhopOrders : 'No pickup/dine-in orders yet'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.placeOrderToSee,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

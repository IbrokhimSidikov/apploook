import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/services/order_history_service.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/widget/api_order_tracking_card.dart';
import 'package:apploook/widget/order_tracking_shimmer.dart';
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
  bool _backgroundRefreshRunning = false;
  List<Map<String, dynamic>> _deliveryOrders = [];
  List<Map<String, dynamic>> _carhopOrders = [];
  List<Map<String, dynamic>> _selfPickupOrders = [];
  String? _updatingOrderId;
  Set<String> _arrivedOrders = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load both types of orders with smart caching
    _loadOrdersWithBackgroundRefresh();
  }

  Future<void> _loadOrdersWithBackgroundRefresh() async {
    await _loadOrders(forceRefresh: false);
    
    _backgroundRefresh();
  }

  void _backgroundRefresh() async {
    if (_backgroundRefreshRunning) return;
    _backgroundRefreshRunning = true;
    try {
      final response = await _orderHistoryService.fetchOrderHistory(
        page: 1,
        limit: 50,
        forceRefresh: true,
      );

      if (!mounted) return;

      final orders = (response['data'] as List<dynamic>? ?? [])
          .map((order) => order as Map<String, dynamic>)
          .toList();

      orders.sort((a, b) {
        final aTime = DateTime.parse(a['time'] ?? '');
        final bTime = DateTime.parse(b['time'] ?? '');
        return bTime.compareTo(aTime);
      });

      final deliveryOrders = orders
          .where((order) => order['order_type_id'] == 3)
          .toList();
      final carhopOrders = orders
          .where((order) => order['order_type_id'] == 8)
          .toList();
      final selfPickupOrders = orders
          .where((order) => order['order_type_id'] == 7 || order['order_type_id'] == 1 || order['order_type_id'] == 2)
          .toList();

      if (mounted) {
        setState(() {
          _deliveryOrders = deliveryOrders;
          _carhopOrders = carhopOrders;
          _selfPickupOrders = selfPickupOrders;
        });
      }
    } catch (e) {
      print('Background refresh failed: $e');
    } finally {
      _backgroundRefreshRunning = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Release list references so the GC can reclaim the order data
    _deliveryOrders = [];
    _carhopOrders = [];
    _selfPickupOrders = [];
    super.dispose();
  }

  Future<void> _loadOrders({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch orders from API (with caching)
      final response = await _orderHistoryService.fetchOrderHistory(
        page: 1,
        limit: 50,
        forceRefresh: forceRefresh,
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
          .where((order) =>  order['order_type_id'] == 3)
          .toList();
      final carhopOrders = orders
          .where((order) => order['order_type_id'] == 8)
          .toList();
      final selfPickupOrders = orders
          .where((order) => order['order_type_id'] == 7 || order['order_type_id'] == 1 || order['order_type_id'] == 2)
          .toList();

      setState(() {
        _deliveryOrders = deliveryOrders;
        _carhopOrders = carhopOrders;
        _selfPickupOrders = selfPickupOrders;
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
            localizations.orderTracking,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: TabBar(
            controller: _tabController,
            labelPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            tabs: [
            Tab(
              height: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.delivery_dining),
                  const SizedBox(height: 2),
                  Text(
                    localizations.deliveryOrders,
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Tab(
              height: 66,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_parking),
                    const SizedBox(height: 2),
                    Text(
                      localizations.carhopOrders,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const Tab(
              height: 66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag),
                  SizedBox(height: 2),
                  Text(
                    'Pickup/Dine-In',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadOrders(forceRefresh: true),
              tooltip: 'Refresh',
            ),
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
              ? const OrderTrackingShimmer()
              : _deliveryOrders.isEmpty
                  ? _buildEmptyState(0)
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(forceRefresh: true),
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
              ? const OrderTrackingShimmer()
              : _carhopOrders.isEmpty
                  ? _buildEmptyState(1)
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(forceRefresh: true),
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
              ? const OrderTrackingShimmer()
              : _selfPickupOrders.isEmpty
                  ? _buildEmptyState(2)
                  : RefreshIndicator(
                      onRefresh: () => _loadOrders(forceRefresh: true),
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

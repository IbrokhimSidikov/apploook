import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/widget/order_tracking_card.dart';
import 'package:http/http.dart' as http;

class UnifiedOrderTrackingPage extends StatefulWidget {
  const UnifiedOrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<UnifiedOrderTrackingPage> createState() => _UnifiedOrderTrackingPageState();
}

class _UnifiedOrderTrackingPageState extends State<UnifiedOrderTrackingPage> with SingleTickerProviderStateMixin {
  final OrderTrackingService _trackingService = OrderTrackingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveryOrders = [];
  List<Map<String, dynamic>> _carhopOrders = [];
  String? _updatingOrderId;
  
  // Track new orders for each tab
  int _newDeliveryOrders = 0;
  int _newCarhopOrders = 0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
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
        } else {
          _newCarhopOrders = 0;
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
      
      // Load delivery orders
      final deliveryOrders = await _trackingService.getSavedDeliveryOrders();
      
      // Load carhop orders
      final prefs = await SharedPreferences.getInstance();
      final savedCarhopOrders = prefs.getStringList('carhop_orders') ?? [];
      final carhopOrders = savedCarhopOrders
          .map((order) => jsonDecode(order) as Map<String, dynamic>)
          .toList();
      
      // Sort orders by timestamp (newest first)
      deliveryOrders.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime);
      });
      
      carhopOrders.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime);
      });
      
      // Calculate new orders (only if there are more orders than before)
      final newDeliveryOrders = deliveryOrders.length > prevDeliveryCount ? 
          deliveryOrders.length - prevDeliveryCount : 0;
      final newCarhopOrders = carhopOrders.length > prevCarhopCount ? 
          carhopOrders.length - prevCarhopCount : 0;
      
      setState(() {
        _deliveryOrders = deliveryOrders;
        _carhopOrders = carhopOrders;
        
        // Update notification counts (don't reset the current tab)
        if (_tabController.index != 0) {
          _newDeliveryOrders += newDeliveryOrders;
        }
        if (_tabController.index != 1) {
          _newCarhopOrders += newCarhopOrders;
        }
        
        _isLoading = false;
      });
      
      // Mark orders as read in the tracking service
      _trackingService.markOrdersAsRead();
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Show confirmation dialog before clearing all orders
  Future<void> _showClearConfirmationDialog(bool isDelivery) async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.clearAll),
        content: Text(isDelivery 
            ? 'Are you sure you want to clear all delivery order history? This action cannot be undone.'
            : 'Are you sure you want to clear all carhop order history? This action cannot be undone.'),
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
    ) ?? false;

    if (confirmed && mounted) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        if (isDelivery) {
          // Clear delivery orders
          final success = await _trackingService.clearAllOrders();
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All delivery orders cleared')),
            );
          }
        } else {
          // Clear carhop orders
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('carhop_orders', []);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All carhop orders cleared')),
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
    setState(() {
      _updatingOrderId = orderId;
    });

    final String url = 'https://app.sievesapp.com/v1/order/$orderId?isDelever=1';

    final Map<String, dynamic> requestBody = {
      "id": orderId,
      "customer_arrived": 1,
      "is_sync": 0,
    };

    const String bearerToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiZWFyZXIiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.fo1-6HkjCqoQ_m4cCO6laUgHHBBqktz0SAgmOi6axqQ";
    const String xApiKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ODk4ODkiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.twqu6OB88osWslaoMr6UDH8RNuSX095LlEf0OVdDglY";

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
        print("Order status updated successfully!");
      } else {
        print("Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("Error updating order status: $e");
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delivery_dining),
                      const SizedBox(height: 4),
                      Text(localizations.deliveryOrders),
                    ],
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
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car),
                      const SizedBox(height: 4),
                      Text(localizations.carhopOrders),
                    ],
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
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
            tooltip: 'Refresh',
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  // Clear orders based on current tab
                  _showClearConfirmationDialog(_tabController.index == 0);
                },
                tooltip: 'Clear all orders',
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Delivery Orders Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _deliveryOrders.isEmpty
                  ? _buildEmptyState(true)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _deliveryOrders.length,
                        itemBuilder: (context, index) {
                          return OrderTrackingCard(
                            orderData: _deliveryOrders[index],
                          );
                        },
                      ),
                    ),
          
          // Carhop Orders Tab
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _carhopOrders.isEmpty
                  ? _buildEmptyState(false)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _carhopOrders.length,
                        itemBuilder: (context, index) {
                          final order = _carhopOrders[index];
                          final timestamp = DateTime.parse(order['timestamp']);
                          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                // Order Header
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order['id']}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          updateCarhopOrderStatus(order['id'].toString());
                                        },
                                        child: Tooltip(
                                          message: localizations.arrivedButtonTooltip,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEC700),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (_updatingOrderId == order['id'].toString())
                                                  const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(
                                                        Colors.black,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const Icon(
                                                    Icons.directions_car,
                                                    size: 18,
                                                    color: Colors.black,
                                                  ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  localizations.arrived,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Order Items
                                if (order['orderItems'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      children: [
                                        ...List<Widget>.from(
                                          (order['orderItems'] as List).map((item) => Padding(
                                                padding: const EdgeInsets.only(bottom: 12),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${item['quantity']}x',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: Theme.of(context).primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '${item['name']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(item['price'] * item['quantity']).toStringAsFixed(0)} UZS',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          localizations.totalAmount,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${order['paid']} UZS',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool isDelivery) {
    final localizations = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDelivery ? Icons.receipt_long : Icons.directions_car,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isDelivery ? localizations.noDeliveryOrders : localizations.noCarhopOrders,
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

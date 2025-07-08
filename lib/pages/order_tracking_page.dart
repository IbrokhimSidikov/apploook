import 'package:flutter/material.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/widget/order_tracking_card.dart';
import 'package:apploook/l10n/app_localizations.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final OrderTrackingService _trackingService = OrderTrackingService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _deliveryOrders = [];

  @override
  void initState() {
    super.initState();
    // Mark orders as read when the page is opened
    _trackingService.markOrdersAsRead();
    _loadDeliveryOrders();
  }

  Future<void> _loadDeliveryOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await _trackingService.getSavedDeliveryOrders();

      // Sort orders by timestamp (newest first)
      orders.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp'] ?? '');
        final bTime = DateTime.parse(b['timestamp'] ?? '');
        return bTime.compareTo(aTime);
      });

      setState(() {
        _deliveryOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading delivery orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show confirmation dialog before clearing all orders
  Future<void> _showClearConfirmationDialog() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(localizations.clearAll),
            content: Text(
                'Are you sure you want to clear all order history? This action cannot be undone.'),
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
        final success = await _trackingService.clearAllOrders();
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('All orders cleared')),
          );
          _loadDeliveryOrders(); // Refresh the list (which will now be empty)
        }
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.orderTracking),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryOrders,
            tooltip: 'Refresh',
          ),
          if (_deliveryOrders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearConfirmationDialog,
              tooltip: 'Clear all orders',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveryOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.noDeliveryOrders,
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
                )
              : RefreshIndicator(
                  onRefresh: _loadDeliveryOrders,
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
    );
  }
}

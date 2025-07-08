import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:apploook/services/order_tracking_service.dart';

class OrderTrackingCard extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool autoRefresh;

  const OrderTrackingCard({
    Key? key,
    required this.orderData,
    this.autoRefresh = false, // Default to false since we don't auto-refresh anymore
  }) : super(key: key);

  @override
  State<OrderTrackingCard> createState() => _OrderTrackingCardState();
}

class _OrderTrackingCardState extends State<OrderTrackingCard> {
  late Map<String, dynamic> _orderData;
  bool _isLoading = false;
  final OrderTrackingService _trackingService = OrderTrackingService();

  @override
  void initState() {
    super.initState();
    _orderData = widget.orderData;
    
    // No initial status update or auto-refresh
    // Status will only update when refresh button is clicked
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateOrderStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final orderId = _orderData['id'];
      print('ORDER TRACKING: OrderTrackingCard: Refreshing status for order ID: $orderId');
      print('ORDER TRACKING: OrderTrackingCard: Current status before refresh: ${_orderData['status']}');
      
      // Log the full URL that will be used for the status request
      print('ORDER TRACKING: OrderTrackingCard: Will request status from: https://integrator.api.delever.uz/v1/order/$orderId/status');
      
      final updatedStatus = await _trackingService.updateOrderStatus(orderId);
      print('ORDER TRACKING: OrderTrackingCard: API response for order $orderId: $updatedStatus');
      
      // Log the status and any error information
      if (updatedStatus.containsKey('status')) {
        print('ORDER TRACKING: OrderTrackingCard: Status field: ${updatedStatus['status']}');
      }
      if (updatedStatus.containsKey('statusDetails')) {
        print('ORDER TRACKING: OrderTrackingCard: Status details: ${updatedStatus['statusDetails']}');
      }
      if (updatedStatus.containsKey('error')) {
        print('ORDER TRACKING: OrderTrackingCard: Error: ${updatedStatus['error']}');
      }
      
      // Log all fields in the response
      print('ORDER TRACKING: OrderTrackingCard: All response fields:');
      updatedStatus.forEach((key, value) {
        print('ORDER TRACKING: OrderTrackingCard: Field $key = $value');
      });
      
      if (mounted) {
        setState(() {
          _orderData = {
            ..._orderData,
            'status': updatedStatus['status'],
            'statusDetails': updatedStatus['statusDetails']
          };
          _isLoading = false;
        });
        print('ORDER TRACKING: OrderTrackingCard: UI updated with new status: ${_orderData['status']}');
        print('ORDER TRACKING: OrderTrackingCard: Status change: ${_orderData['status'] != updatedStatus['status'] ? 'CHANGED' : 'UNCHANGED'}');
      }
    } catch (e) {
      print('ORDER TRACKING: OrderTrackingCard: Error updating order status: $e');
      print('ORDER TRACKING: OrderTrackingCard: Error type: ${e.runtimeType}');
      print('ORDER TRACKING: OrderTrackingCard: Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown time';
    }
  }
  
  String _formatDateOnly(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getStatusText(String status) {
  // Convert to lowercase for case-insensitive comparison
  final statusLower = status.toLowerCase();
  
  // Log the status being processed
  print('ORDER TRACKING: Processing status: $status (lowercase: $statusLower)');
  
  switch (statusLower) {
    // New order statuses from API
    case 'new':
      return 'Pending';
    case 'accepted_by_restaurant':
      return 'Confirmed';
    case 'cooking':
      return 'Preparing';
    case 'ready':
      return 'Ready for delivery';
    case 'taken_by_courier':
      return 'On the way';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
      
    // Legacy status mappings
    case 'pending':
      return 'Pending';
    case 'confirmed':
    case 'accepted':
      return 'Confirmed';
    case 'preparing':
    case 'in_progress':
    case 'inprogress':
      return 'Preparing';
    case 'ready_for_delivery':
      return 'Ready for delivery';
    case 'delivering':
    case 'on_the_way':
    case 'ontheway':
    case 'in_delivery':
      return 'On the way';
    case 'completed':
    case 'complete':
      return 'Delivered';
    case 'canceled':
    case 'rejected':
      return 'Cancelled';
    case 'error':
      return 'Error';
    default:
      print('ORDER TRACKING: Unrecognized status: $status');
      return 'Processing';
  }
}

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    
    switch (statusLower) {
      // New order statuses from API
      case 'new':
        return Colors.orange;
      case 'accepted_by_restaurant':
        return Colors.blue;
      case 'cooking':
        return Colors.amber;
      case 'ready':
        return Colors.indigo;
      case 'taken_by_courier':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
        
      // Legacy status mappings
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'preparing':
      case 'in_progress':
      case 'inprogress':
        return Colors.amber;
      case 'ready_for_delivery':
        return Colors.indigo;
      case 'delivering':
      case 'on_the_way':
      case 'ontheway':
      case 'in_delivery':
        return Colors.purple;
      case 'completed':
      case 'complete':
        return Colors.green;
      case 'canceled':
      case 'rejected':
        return Colors.red;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusIndicator(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = _orderData['timestamp'] ?? '';
    final formattedTime = _formatDateTime(timestamp);
    final status = _orderData['status'] ?? 'pending';
    final address = _orderData['address'] ?? 'No address';
    final paymentType = _orderData['paymentType'] ?? 'Unknown';
    final total = _orderData['total'] ?? 0.0;
    final deliveryFee = _orderData['deliveryFee'] ?? 0.0;
    final items = _orderData['items'] as List<dynamic>? ?? [];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Show a snackbar with the full order ID when tapped
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Order ID: ${_orderData['id']}'),
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _orderData['id'].toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order ID copied to clipboard')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Order from ${_formatDateOnly(timestamp)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusIndicator(status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Order Summary',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item['quantity']}x ${item['name']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      '${NumberFormat('#,##0').format(item['totalPrice'])} sum',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('${NumberFormat('#,##0').format(total - deliveryFee)} sum'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text('${NumberFormat('#,##0').format(deliveryFee)} sum'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${NumberFormat('#,##0').format(total)} sum',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      paymentType.toLowerCase() == 'card'
                          ? Icons.credit_card
                          : Icons.money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      paymentType,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateOrderStatus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Refresh Status'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

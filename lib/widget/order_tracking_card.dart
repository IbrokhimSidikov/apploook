import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/l10n/app_localizations.dart';

class OrderTrackingCard extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final bool autoRefresh;

  const OrderTrackingCard({
    Key? key,
    required this.orderData,
    this.autoRefresh =
        false, // Default to false since we don't auto-refresh anymore
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
      print(
          'ORDER TRACKING: OrderTrackingCard: Refreshing status for order ID: $orderId');
      print(
          'ORDER TRACKING: OrderTrackingCard: Current status before refresh: ${_orderData['status']}');

      // Log the full URL that will be used for the status request
      print(
          'ORDER TRACKING: OrderTrackingCard: Will request status from: https://integrator.api.delever.uz/v1/order/$orderId/status');

      final updatedStatus = await _trackingService.updateOrderStatus(orderId);
      print(
          'ORDER TRACKING: OrderTrackingCard: API response for order $orderId: $updatedStatus');

      // Log the status and any error information
      if (updatedStatus.containsKey('status')) {
        print(
            'ORDER TRACKING: OrderTrackingCard: Status field: ${updatedStatus['status']}');
      }
      if (updatedStatus.containsKey('statusDetails')) {
        print(
            'ORDER TRACKING: OrderTrackingCard: Status details: ${updatedStatus['statusDetails']}');
      }
      if (updatedStatus.containsKey('error')) {
        print(
            'ORDER TRACKING: OrderTrackingCard: Error: ${updatedStatus['error']}');
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
        print(
            'ORDER TRACKING: OrderTrackingCard: UI updated with new status: ${_orderData['status']}');
        print(
            'ORDER TRACKING: OrderTrackingCard: Status change: ${_orderData['status'] != updatedStatus['status'] ? 'CHANGED' : 'UNCHANGED'}');
      }
    } catch (e) {
      print(
          'ORDER TRACKING: OrderTrackingCard: Error updating order status: $e');
      print('ORDER TRACKING: OrderTrackingCard: Error type: ${e.runtimeType}');
      print(
          'ORDER TRACKING: OrderTrackingCard: Stack trace: ${StackTrace.current}');
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
    print(
        'ORDER TRACKING: Processing status: $status (lowercase: $statusLower)');

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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status).withOpacity(0.15),
            _getStatusColor(status).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(status),
                  _getStatusColor(status).withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(status).withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _getStatusText(status),
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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
    final paketPrice = 2000;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      // Show a snackbar with the full order ID when tapped
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${AppLocalizations.of(context).orderID} : ${_orderData['id']}'),
                          duration: const Duration(seconds: 3),
                          action: SnackBarAction(
                            label: 'Copy',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: _orderData['id'].toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order ID copied to clipboard')),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '${AppLocalizations.of(context).orderCardTitle} ${_formatDateOnly(timestamp)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  flex: 1,
                  child: _buildStatusIndicator(status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).orderSummary,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.map((item) {
              // Get modifiers if they exist
              final selectedModifiers = item['selectedModifiers'] as List<dynamic>? ?? [];
              final hasModifiers = selectedModifiers.isNotEmpty;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor.withOpacity(0.1),
                                Theme.of(context).primaryColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item['quantity']}x',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item['name']}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                              height: 1.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${NumberFormat('#,##0').format(item['totalPrice'] ?? item['price'] * item['quantity'])} sum',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    // Display modifiers if they exist
                    if (hasModifiers)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: selectedModifiers.map((modifier) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${modifier['modifierName']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '+${NumberFormat('#,##0').format(modifier['modifierPrice'])} sum',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).deliveryFee,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(deliveryFee)} sum',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.shade300,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).totalTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.15),
                              Theme.of(context).primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${NumberFormat('#,##0').format(total + deliveryFee)} sum',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            paymentType.toLowerCase() == 'card'
                                ? Icons.credit_card_rounded
                                : Icons.payments_rounded,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            paymentType,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey.shade300, Colors.grey.shade400]
                          : [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.8),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateOrderStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context).refreshStatus,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
    );
  }
}

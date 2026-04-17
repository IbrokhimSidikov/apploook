import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/widget/delivery_status_timeline.dart';

class ApiOrderTrackingCard extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const ApiOrderTrackingCard({
    Key? key,
    required this.orderData,
  }) : super(key: key);

  @override
  State<ApiOrderTrackingCard> createState() => _ApiOrderTrackingCardState();
}

class _ApiOrderTrackingCardState extends State<ApiOrderTrackingCard> {
  bool _isExpanded = false;

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toUtc().add(const Duration(hours: 5));
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } catch (e) {
      return 'Unknown time';
    }
  }

  String _formatDateOnly(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString).toUtc().add(const Duration(hours: 5));
      return DateFormat('MMM d').format(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase().trim()) {
      case 'new':
      case 'open':
      case 'pending':
        return 'Pending';
      case 'accepted':
      case 'confirmed':
        return 'Confirmed';
      case 'cooking':
      case 'preparing':
      case 'production':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'on the way':
      case 'on_the_way':
      case 'delivering':
        return 'On the way';
      case 'delivered':
      case 'completed':
      case 'closed':
        return 'Delivered';
      case 'cancel':
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'new':
      case 'open':
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'confirmed':
        return Colors.blue;
      case 'cooking':
      case 'preparing':
      case 'production':
        return Colors.amber;
      case 'ready':
        return Colors.indigo;
      case 'on the way':
      case 'on_the_way':
      case 'delivering':
        return Colors.purple;
      case 'delivered':
      case 'completed':
      case 'closed':
        return Colors.green;
      case 'cancel':
      case 'cancelled':
      case 'canceled':
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

  String _getOrderTypeIcon(int orderTypeId) {
    switch (orderTypeId) {
      case 1:
        return '🍽️';
      case 2:
        return '🍽️';
      case 3:
        return '🚗';
      case 7:
        return '🛍️';
      case 8:
        return '🅿️';
      default:
        return '📦';
    }
  }

  String _getOrderTypeName(int orderTypeId) {
    switch (orderTypeId) {
      case 1:
        return 'Dine-In';
      case 2:
        return 'In-Restaurant';
      case 3:
        return 'Delivery';
      case 7:
        return 'Self-Pickup';
      case 8:
        return 'Carhop';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderData['id'];
    final deliveryFee = widget.orderData['delivery_fee'] ?? 0;
    final time = widget.orderData['time'] ?? '';
    final orderTypeId = widget.orderData['order_type_id'] ?? 0;
    final statusName = widget.orderData['status_name'] ?? 'Unknown';
    final currentStatusId = widget.orderData['current_status_id'] as int?;
    final value = widget.orderData['value'] ?? 0;
    final branchName = widget.orderData['branch_name'] ?? 'Unknown Branch';
    final orderItems = widget.orderData['order_items'] as List<dynamic>? ?? [];

    final formattedTime = _formatDateTime(time);
    final formattedDate = _formatDateOnly(time);

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Compact Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Order Type Icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getOrderTypeIcon(orderTypeId),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Order Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Order #$orderId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(statusName).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getStatusColor(statusName).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(statusName),
                                    style: TextStyle(
                                      color: _getStatusColor(statusName),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getOrderTypeName(orderTypeId),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand Icon
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ── Delivery status timeline (delivery orders only) ──
                  if (orderTypeId == 3) ...[
                    DeliveryStatusTimeline(statusName: statusName, statusId: currentStatusId),
                    const SizedBox(height: 8),
                  ],
                  // Date and Total Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(value + deliveryFee)} sum',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expandable Details
            if (_isExpanded) ...[
              Divider(height: 1, color: Colors.grey.shade200),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Branch Info
                    Row(
                      children: [
                        Icon(
                          Icons.store_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branchName,
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
                    const SizedBox(height: 16),
                    // Order Items Header
                    Text(
                      AppLocalizations.of(context).orderSummary,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...orderItems.map((item) {
                      final itemName = item['name'] ?? 'Unknown Item';
                      final quantity = item['quantity'] ?? 1;
                      final actualPrice = item['actual_price'] ?? 0;
                      final modifiers = item['modifiers'] as List<dynamic>? ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${quantity}x',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    itemName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${NumberFormat('#,##0').format(actualPrice)} sum',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                            if (modifiers.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 32, top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: modifiers.map((modifier) {
                                    final modifierName = modifier['name'] ?? 'Unknown';
                                    final modifierQuantity = modifier['quantity'] ?? 1;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '+ $modifierQuantity x $modifierName',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    // Delivery Fee and Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).deliveryFee,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).totalTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,##0').format(value+deliveryFee)} sum',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

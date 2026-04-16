import 'dart:async';
import 'package:flutter/material.dart';
import 'package:apploook/services/order_history_service.dart';
import 'package:apploook/services/review_service.dart';
import 'package:apploook/widget/review_bottom_sheet.dart';

/// Polls delivery orders and, when an order transitions to "delivered",
/// waits [reviewDelay] then shows the review bottom sheet exactly once.
class DeliveryReviewScheduler {
  static final DeliveryReviewScheduler _instance =
      DeliveryReviewScheduler._internal();
  factory DeliveryReviewScheduler() => _instance;
  DeliveryReviewScheduler._internal();

  final _orderHistoryService = OrderHistoryService();
  final _reviewService = ReviewService();

  static const Duration reviewDelay = Duration(minutes: 5);
  static const Duration pollInterval = Duration(minutes: 2);

  Timer? _pollTimer;
  final Set<int> _scheduledOrderIds = {};

  /// Call once (e.g., from main.dart) to start background polling.
  void start(GlobalKey<NavigatorState> navigatorKey) {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(pollInterval, (_) {
      _checkDeliveredOrders(navigatorKey);
    });
    // Also run immediately on start
    _checkDeliveredOrders(navigatorKey);
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkDeliveredOrders(
      GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final response = await _orderHistoryService.fetchOrderHistory(
        page: 1,
        limit: 50,
        forceRefresh: true,
      );

      final orders = (response['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();

      for (final order in orders) {
        final orderTypeId = order['order_type_id'] as int? ?? 0;
        // Only delivery orders (order_type_id == 3)
        if (orderTypeId != 3) continue;

        final orderId = order['id'];
        if (orderId == null) continue;
        final orderIdInt = orderId is int ? orderId : int.tryParse('$orderId');
        if (orderIdInt == null) continue;

        final statusName =
            (order['status_name'] as String? ?? '').toLowerCase();
        final isDelivered =
            statusName == 'delivered' || statusName == 'completed';
        if (!isDelivered) continue;

        // Only prompt for orders delivered within the last 24 hours
        final timeStr = order['time'] as String?;
        if (timeStr != null) {
          try {
            final orderTime = DateTime.parse(timeStr).toUtc();
            final age = DateTime.now().toUtc().difference(orderTime);
            if (age > const Duration(hours: 24)) continue;
          } catch (_) {}
        }

        // Skip if already scheduled or shown
        if (_scheduledOrderIds.contains(orderIdInt)) continue;
        final alreadyShown =
            await _reviewService.hasReviewBeenShown(orderIdInt);
        if (alreadyShown) continue;

        // Schedule the prompt
        _scheduledOrderIds.add(orderIdInt);
        Future.delayed(reviewDelay, () {
          _showReviewSheet(navigatorKey, orderIdInt);
        });
        print(
            'DeliveryReviewScheduler: Scheduled review for order $orderIdInt in ${reviewDelay.inMinutes} min');
      }
    } catch (e) {
      print('DeliveryReviewScheduler: Error checking orders: $e');
    }
  }

  void _showReviewSheet(
      GlobalKey<NavigatorState> navigatorKey, int orderId) async {
    // Double-check it hasn't been shown while waiting
    final alreadyShown = await _reviewService.hasReviewBeenShown(orderId);
    if (alreadyShown) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Mark as shown before displaying so a second trigger won't race
    await _reviewService.markReviewShown(orderId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReviewBottomSheet(orderId: orderId),
    );
  }
}

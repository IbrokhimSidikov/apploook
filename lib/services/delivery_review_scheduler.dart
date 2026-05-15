import 'dart:async';
import 'package:flutter/material.dart';
import 'package:apploook/services/notification_service.dart';
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
  final _notificationService = NotificationService();

  /// How long to wait after detecting a "delivered" status before showing the sheet.
  /// Kept short since the API status already confirms delivery.
  static const Duration reviewDelay = Duration(seconds: 30);

  /// How often to poll the API for status updates.
  static const Duration pollInterval = Duration(minutes: 2);

  Timer? _pollTimer;

  /// In-memory set of order IDs already scheduled OR shown this session,
  /// to avoid double-scheduling across polls.
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
      // Always fetch fresh data so status changes are detected immediately.
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

        // Skip if already scheduled or shown this session
        if (_scheduledOrderIds.contains(orderIdInt)) continue;

        // Skip if the review was already shown in a previous session
        final alreadyShown =
            await _reviewService.hasReviewBeenShown(orderIdInt);
        if (alreadyShown) continue;

        // Mark in-memory to prevent duplicate scheduling across polls
        _scheduledOrderIds.add(orderIdInt);

        // Send a local notification immediately so the user knows
        await _notificationService.showLocalNotification(
          id: orderIdInt,
          title: '⭐ Rate your order #$orderIdInt',
          body: 'Your order has been delivered! Tap to share your feedback.',
          payload: 'review:$orderIdInt',
        );

        final orderSnapshot = Map<String, dynamic>.from(order);
        Future.delayed(reviewDelay, () {
          _showReviewSheet(navigatorKey, orderIdInt, orderSnapshot);
        });

        print(
            'DeliveryReviewScheduler: Scheduled review for order $orderIdInt in ${reviewDelay.inSeconds}s');
      }
    } catch (e) {
      print('DeliveryReviewScheduler: Error checking orders: $e');
    }
  }

  void _showReviewSheet(
      GlobalKey<NavigatorState> navigatorKey, int orderId,
      [Map<String, dynamic>? orderData]) async {
    // Double-check it hasn't been shown while waiting
    final alreadyShown = await _reviewService.hasReviewBeenShown(orderId);
    if (alreadyShown) return;

    final context = navigatorKey.currentContext;
    if (context == null) {
      // Context not ready — remove from scheduled so it can retry on next poll
      _scheduledOrderIds.remove(orderId);
      print('DeliveryReviewScheduler: context null for order $orderId, will retry');
      return;
    }

    // NOTE: We intentionally do NOT call markReviewShown here.
    // The ReviewBottomSheet calls it when the user submits or skips,
    // ensuring it's only marked after the user actually sees it.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReviewBottomSheet(orderId: orderId, orderData: orderData),
    ).then((_) {
      // If the sheet was dismissed without the user pressing skip/submit
      // (e.g., OS back gesture slipped through), mark it shown so we don't loop.
      _reviewService.hasReviewBeenShown(orderId).then((shown) {
        if (!shown) _reviewService.markReviewShown(orderId);
      });
    });
  }
}

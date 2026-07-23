import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One step of the order tracker, derived from a raw Delever status string.
class OrderStep {
  final String key; // confirmed | preparing | onTheWay | delivered | cancelled
  final String text; // human-readable label
  final int index; // 0..3 for the progress bar
  final bool isTerminal; // delivered / cancelled -> end the activity

  const OrderStep(this.key, this.text, this.index, this.isTerminal);
}

/// Bridges Flutter to the native iOS Live Activity (ActivityKit).
///
/// On Android (or iOS < 16.1) every method is a safe no-op.
///
/// Usage:
///   await LiveActivityService.instance.startForOrder(
///     orderId: id, branchName: branch, rawStatus: 'new');
///   await LiveActivityService.instance.updateForOrder(
///     orderId: id, rawStatus: 'on_the_way', etaMinutes: 20);
class LiveActivityService {
  LiveActivityService._() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }
  static final LiveActivityService instance = LiveActivityService._();

  static const _channel = MethodChannel('com.loook.apploook/live_activity');

  // Persisted orderId -> activityId map so updates survive app restarts.
  static const _prefsKey = 'live_activity_ids';

  /// Called when ActivityKit issues a push token for an activity.
  /// Wire this to OneSignal once the SDK is installed (see LIVE_ACTIVITY_SETUP.md).
  void Function(String activityId, String token)? onPushToken;

  bool get _supported => Platform.isIOS;

  Future<bool> isEnabled() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('areActivitiesEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Start a Live Activity for a freshly placed order.
  Future<void> startForOrder({
    required String orderId,
    required String branchName,
    required String rawStatus,
    int etaMinutes = 0,
  }) async {
    if (!_supported) {
      print('LiveActivity: skipped — not iOS');
      return;
    }
    final enabled = await isEnabled();
    print('LiveActivity: areActivitiesEnabled = $enabled');
    if (!enabled) {
      print('LiveActivity: NOT started — Live Activities are disabled in '
          'Settings > LOOOK > Live Activities (or a Focus is hiding them).');
      return;
    }

    final step = mapStatus(rawStatus);
    if (step.isTerminal) {
      print('LiveActivity: NOT started — status "$rawStatus" is terminal');
      return; // nothing to track
    }

    try {
      final activityId = await _channel.invokeMethod<String>('startActivity', {
        'orderId': orderId,
        'branchName': branchName,
        ..._stateArgs(step, etaMinutes),
      });
      print('LiveActivity: started, activityId = $activityId');
      if (activityId != null) {
        await _saveId(orderId, activityId);
      }
    } catch (e) {
      // ignore: avoid_print
      print('LiveActivity start failed: $e');
    }
  }

  /// Update (or end, if terminal) the activity for an order.
  Future<void> updateForOrder({
    required String orderId,
    required String rawStatus,
    int etaMinutes = 0,
  }) async {
    if (!_supported) return;
    final activityId = await _idFor(orderId);
    if (activityId == null) return;

    final step = mapStatus(rawStatus);
    try {
      if (step.isTerminal) {
        await _channel.invokeMethod('endActivity', {
          'activityId': activityId,
          ..._stateArgs(step, 0),
        });
        await _removeId(orderId);
      } else {
        await _channel.invokeMethod('updateActivity', {
          'activityId': activityId,
          ..._stateArgs(step, etaMinutes),
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('LiveActivity update failed: $e');
    }
  }

  /// Force-end an order's activity (e.g. user cleared the order).
  Future<void> endForOrder(String orderId) async {
    if (!_supported) return;
    final activityId = await _idFor(orderId);
    if (activityId == null) return;
    try {
      await _channel.invokeMethod('endActivity', {'activityId': activityId});
    } catch (_) {}
    await _removeId(orderId);
  }

  // --- status mapping (mirrors api_order_tracking_card._getStatusText) ---

  static OrderStep mapStatus(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'new':
      case 'open':
      case 'pending':
      case 'accepted':
      case 'confirmed':
        return const OrderStep('confirmed', 'Order confirmed', 0, false);
      case 'cooking':
      case 'preparing':
      case 'production':
      case 'book':
      case 'booked':
        return const OrderStep('preparing', 'Preparing your order', 1, false);
      case 'ready':
      case 'on the way':
      case 'on_the_way':
      case 'delivering':
      case 'go':
      case 'finish':
        return const OrderStep('onTheWay', 'On the way', 2, false);
      case 'delivered':
      case 'completed':
      case 'closed':
        return const OrderStep('delivered', 'Delivered', 3, true);
      case 'cancel':
      case 'cancelled':
      case 'canceled':
        return const OrderStep('cancelled', 'Order cancelled', 0, true);
      default:
        return const OrderStep('confirmed', 'Order confirmed', 0, false);
    }
  }

  Map<String, dynamic> _stateArgs(OrderStep step, int etaMinutes) => {
        'statusKey': step.key,
        'statusText': step.text,
        'stepIndex': step.index,
        'etaMinutes': etaMinutes,
      };

  // --- native -> dart callbacks ---

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onPushToken') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      onPushToken?.call(args['activityId'] as String, args['token'] as String);
    }
  }

  // --- id persistence ---

  Future<void> _saveId(String orderId, String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _decode(prefs.getStringList(_prefsKey));
    map[orderId] = activityId;
    await prefs.setStringList(_prefsKey, _encode(map));
  }

  Future<void> _removeId(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _decode(prefs.getStringList(_prefsKey));
    map.remove(orderId);
    await prefs.setStringList(_prefsKey, _encode(map));
  }

  Future<String?> _idFor(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getStringList(_prefsKey))[orderId];
  }

  Map<String, String> _decode(List<String>? list) {
    final map = <String, String>{};
    for (final entry in list ?? const <String>[]) {
      final i = entry.indexOf('=');
      if (i > 0) map[entry.substring(0, i)] = entry.substring(i + 1);
    }
    return map;
  }

  List<String> _encode(Map<String, String> map) =>
      map.entries.map((e) => '${e.key}=${e.value}').toList();
}

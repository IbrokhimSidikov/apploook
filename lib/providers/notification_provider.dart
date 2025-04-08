import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/notification.dart';

class NotificationProvider with ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  static const String _orderStorageKey = 'order_notifications';
  
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _orderNotifications = [];
  
  int _unreadCount = 0;
  int _unreadOrderCount = 0;

  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get orderNotifications => _orderNotifications;
  int get unreadCount => _unreadCount;
  int get unreadOrderCount => _unreadOrderCount;

  NotificationProvider() {
    loadNotifications();
    loadOrderNotifications();
  }

  void addNotification({
    required String title,
    required String body,
    required String messageId,
  }) {
    final notification = NotificationItem(
      title: title,
      message: body,
      time: DateTime.now().toString(),
      type: NotificationType.promotion,
      isRead: false,
      messageId: messageId,
    );
    
    if (!_notifications.any((n) => n.messageId == messageId)) {
      _notifications.insert(0, notification);
      _unreadCount++;
      _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> addOrderNotification({
    required String title,
    required String body,
    required String messageId,
  }) async {
    final notification = NotificationItem(
      title: title,
      message: body,
      time: DateTime.now().toString(),
      type: NotificationType.success,
      isRead: false,
      messageId: messageId,
    );
    
    if (!_orderNotifications.any((n) => n.messageId == messageId)) {
      _orderNotifications.insert(0, notification);
      _unreadOrderCount++;
      await _saveOrderNotifications();
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedNotifications = prefs.getString(_storageKey);
    
    if (savedNotifications != null) {
      final List<dynamic> decoded = jsonDecode(savedNotifications);
      _notifications = decoded.map((item) => NotificationItem.fromJson(item)).toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> loadOrderNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedNotifications = prefs.getString(_orderStorageKey);
    
    if (savedNotifications != null) {
      final List<dynamic> decoded = jsonDecode(savedNotifications);
      _orderNotifications = decoded.map((item) => NotificationItem.fromJson(item)).toList();
      _unreadOrderCount = _orderNotifications.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _notifications.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _saveOrderNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _orderNotifications.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_orderStorageKey, encoded);
  }

  Future<void> markAllAsRead() async {
    for (var i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        type: notification.type,
        isRead: true,
        messageId: notification.messageId,
      );
    }
    _unreadCount = 0;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> markAllOrdersAsRead() async {
    for (var i = 0; i < _orderNotifications.length; i++) {
      final notification = _orderNotifications[i];
      _orderNotifications[i] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        type: notification.type,
        isRead: true,
        messageId: notification.messageId,
      );
    }
    _unreadOrderCount = 0;
    await _saveOrderNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;
    await _saveNotifications();
    notifyListeners();
  }

  Future<void> clearAllOrders() async {
    _orderNotifications.clear();
    _unreadOrderCount = 0;
    await _saveOrderNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String? messageId) async {
    if (messageId == null) return;
    
    final index = _notifications.indexWhere((n) => n.messageId == messageId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        type: notification.type,
        isRead: true,
        messageId: notification.messageId,
      );
      if (_unreadCount > 0) _unreadCount--;
      await _saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markOrderAsRead(String? messageId) async {
    if (messageId == null) return;
    
    final index = _orderNotifications.indexWhere((n) => n.messageId == messageId);
    if (index != -1) {
      final notification = _orderNotifications[index];
      _orderNotifications[index] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        type: notification.type,
        isRead: true,
        messageId: notification.messageId,
      );
      if (_unreadOrderCount > 0) _unreadOrderCount--;
      await _saveOrderNotifications();
      notifyListeners();
    }
  }
}

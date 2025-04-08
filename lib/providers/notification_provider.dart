import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../pages/notification.dart';

class NotificationProvider with ChangeNotifier {
  static const String _storageKey = 'app_notifications';
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  NotificationProvider() {
    loadNotifications();
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
    
    // Check if notification with this messageId already exists
    if (!_notifications.any((n) => n.messageId == messageId)) {
      _notifications.insert(0, notification);
      _unreadCount++;
      _saveNotifications();
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

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _notifications.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
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

  Future<void> clearAll() async {
    _notifications.clear();
    _unreadCount = 0;
    await _saveNotifications();
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

  Future<void> incrementUnreadCount() async {
    _unreadCount++;
    notifyListeners();
  }
}

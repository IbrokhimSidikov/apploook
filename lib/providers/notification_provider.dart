import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Future<void> loadUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrders = prefs.getStringList('carhop_orders') ?? [];
    _unreadCount = savedOrders.length;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> incrementUnreadCount() async {
    _unreadCount++;
    notifyListeners();
  }
}

import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent different order modes
enum OrderMode {
  deliveryTakeaway,  // For delivery and takeaway orders (new API)
  carhop,            // For carhop orders (old API)
}

/// Service to manage the order mode (delivery/takeaway vs carhop) selection
/// Singleton pattern ensures consistent access across the app
class OrderModeService {
  // Singleton pattern
  static final OrderModeService _instance = OrderModeService._internal();
  factory OrderModeService() => _instance;
  OrderModeService._internal();
  
  // State variables
  OrderMode _currentMode = OrderMode.deliveryTakeaway; // Default to delivery/takeaway
  bool _hasUserSelected = false;
  
  // Keys - only kept for reference, not used for persistence anymore
  static const String _orderModeKey = 'order_mode';
  static const String _hasUserSelectedKey = 'has_user_selected_order_mode';
  
  // Getters for current state
  OrderMode get currentMode => _currentMode;
  
  // Always return false to prompt the user each time
  bool get hasSelectedMode => false;
  bool get hasUserSelected => _hasUserSelected;
  
  /// Initialize the service from SharedPreferences
  Future<void> initialize() async {
    // Set default mode but don't load from preferences
    _currentMode = OrderMode.deliveryTakeaway;
    _hasUserSelected = false;
    print('OrderModeService: Initialized with default mode: $_currentMode');
  }
  
  /// Set and save the order mode
  Future<void> setOrderMode(OrderMode mode) async {
    // Just set the mode in memory, don't save to SharedPreferences
    _currentMode = mode;
    _hasUserSelected = true;
    print('OrderModeService: Set mode to $mode');
  }
  
  /// Reset the order mode selection (for testing or when user logs out)
  Future<void> reset() async {
    try {
      _currentMode = OrderMode.deliveryTakeaway;
      _hasUserSelected = false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderModeKey);
      await prefs.remove(_hasUserSelectedKey);
      print('OrderModeService: Reset order mode selection');
    } catch (e) {
      print('OrderModeService: Error resetting order mode: $e');
    }
  }
}

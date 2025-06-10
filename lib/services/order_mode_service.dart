import 'package:shared_preferences/shared_preferences.dart';

// Enum to represent different order modes
enum OrderMode {
  deliveryTakeaway, // For delivery and takeaway orders (new API)
  carhop, // For carhop orders (old API)
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

  // Keys for SharedPreferences
  static const String _orderModeKey = 'order_mode';
  static const String _hasUserSelectedKey = 'has_user_selected_order_mode';

  // Session flag to prevent showing dialog multiple times in the same session
  bool _hasSelectedModeInSession = false;

  // Getters for current state
  OrderMode get currentMode => _currentMode;

  // Return true if mode has been selected either in this session or in a previous one
  bool get hasSelectedMode => _hasSelectedModeInSession || _hasUserSelected;
  bool get hasUserSelected => _hasUserSelected;

  /// Initialize the service from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user selection status from SharedPreferences
      _hasUserSelected = prefs.getBool(_hasUserSelectedKey) ?? false;
      
      // Load order mode from SharedPreferences if it exists
      if (prefs.containsKey(_orderModeKey)) {
        final savedModeIndex = prefs.getInt(_orderModeKey) ?? 0;
        if (savedModeIndex < OrderMode.values.length) {
          _currentMode = OrderMode.values[savedModeIndex];
        }
      }
      
      print('OrderModeService: Initialized with mode: $_currentMode, hasUserSelected: $_hasUserSelected');
    } catch (e) {
      print('OrderModeService: Error initializing: $e');
      // Use defaults if there's an error
      _currentMode = OrderMode.deliveryTakeaway;
      _hasUserSelected = false;
    }
  }

  /// Set and save the order mode
  Future<void> setOrderMode(OrderMode mode) async {
    try {
      // Update in-memory state
      _currentMode = mode;
      _hasUserSelected = true;
      _hasSelectedModeInSession = true;
      
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_orderModeKey, mode.index);
      await prefs.setBool(_hasUserSelectedKey, true);
      
      print('OrderModeService: Set and saved mode to $mode');
    } catch (e) {
      print('OrderModeService: Error saving order mode: $e');
      // Still update in-memory state even if saving fails
      _currentMode = mode;
      _hasUserSelected = true;
      _hasSelectedModeInSession = true;
    }
  }

  /// Reset the order mode selection (for testing or when user logs out)
  Future<void> reset() async {
    try {
      // Reset in-memory state
      _currentMode = OrderMode.deliveryTakeaway;
      _hasUserSelected = false;
      _hasSelectedModeInSession = false;

      // Clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_orderModeKey);
      await prefs.remove(_hasUserSelectedKey);
      
      print('OrderModeService: Reset order mode selection');
    } catch (e) {
      print('OrderModeService: Error resetting order mode: $e');
    }
  }
}

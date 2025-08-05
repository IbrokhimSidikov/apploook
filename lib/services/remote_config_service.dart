import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Default values for remote config parameters
  static const int _defaultCutoffHour = 23;
  static const int _defaultCutoffMinute = 45;

  // Remote config keys
  static const String _keyCutoffHour = 'order_cutoff_hour';
  static const String _keyCutoffMinute = 'order_cutoff_minute';

  factory RemoteConfigService() {
    return _instance;
  }

  RemoteConfigService._internal();

  Future<void> initialize() async {
    try {
      // Set a very short fetch interval for development/testing
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 0), // Allow immediate fetches
      ));

      await _remoteConfig.setDefaults({
        _keyCutoffHour: _defaultCutoffHour,
        _keyCutoffMinute: _defaultCutoffMinute,
      });

      // Fetch and activate the latest values
      bool updated = await _remoteConfig.fetchAndActivate();
      
      if (kDebugMode) {
        print('Remote Config initialized. Values updated: $updated');
        print('Current cutoff hour: ${orderCutoffHour}');
        print('Current cutoff minute: ${orderCutoffMinute}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Remote Config: $e');
      }
    }
  }

  /// Get the cutoff hour for orders (24-hour format)
  int get orderCutoffHour {
    try {
      return _remoteConfig.getInt(_keyCutoffHour);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cutoff hour: $e');
      }
      return _defaultCutoffHour;
    }
  }

  /// Get the cutoff minute for orders
  int get orderCutoffMinute {
    try {
      return _remoteConfig.getInt(_keyCutoffMinute);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cutoff minute: $e');
      }
      return _defaultCutoffMinute;
    }
  }
  
  /// Force fetch the latest values from Firebase Remote Config
  /// Returns true if the fetch and activation was successful
  Future<bool> forceUpdate() async {
    try {
      // Fetch the latest values
      await _remoteConfig.fetch();
      
      // Activate the fetched values
      bool updated = await _remoteConfig.activate();
      
      if (kDebugMode) {
        print('Remote Config force updated. Values updated: $updated');
        print('New cutoff hour: ${orderCutoffHour}');
        print('New cutoff minute: ${orderCutoffMinute}');
      }
      
      return updated;
    } catch (e) {
      if (kDebugMode) {
        print('Error force updating Remote Config: $e');
      }
      return false;
    }
  }
}

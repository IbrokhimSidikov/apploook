import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Default values for remote config parameters
  static const int _defaultCutoffHour = 23;
  static const int _defaultCutoffMinute = 45;
  static const String _defaultMinRequiredVersion = '1.0.0';

  // Remote config keys
  static const String _keyCutoffHour = 'order_cutoff_hour';
  static const String _keyCutoffMinute = 'order_cutoff_minute';
  static const String _keyMinRequiredVersion = 'min_required_version';

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
        _keyMinRequiredVersion: _defaultMinRequiredVersion,
      });

      // Fetch and activate the latest values
      bool updated = await _remoteConfig.fetchAndActivate();
      
      if (kDebugMode) {
        print('Remote Config initialized. Values updated: $updated');
        print('Current cutoff hour: ${orderCutoffHour}');
        print('Current cutoff minute: ${orderCutoffMinute}');
        print('Minimum required version: ${minimumRequiredVersion}');
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
        print('New minimum required version: ${minimumRequiredVersion}');
      }
      
      return updated;
    } catch (e) {
      if (kDebugMode) {
        print('Error force updating Remote Config: $e');
      }
      return false;
    }
  }

  /// Get the minimum required version from remote config
  String get minimumRequiredVersion {
    try {
      return _remoteConfig.getString(_keyMinRequiredVersion);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting minimum required version: $e');
      }
      return _defaultMinRequiredVersion;
    }
  }

  /// Check if the current app version meets the minimum required version
  /// Returns true if an update is required
  Future<bool> isUpdateRequired() async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      
      // Get minimum required version from remote config
      final String requiredVersion = minimumRequiredVersion;
      
      // Log detailed package info
      print('======= PACKAGE INFO DETAILS =======');
      print('App Name: ${packageInfo.appName}');
      print('Package Name: ${packageInfo.packageName}');
      print('Version: ${packageInfo.version}');
      print('Build Number: ${packageInfo.buildNumber}');
      print('Current app version: $currentVersion');
      print('Minimum required version: $requiredVersion');
      print('Update required: ${_isVersionLowerThan(currentVersion, requiredVersion)}');
      print('==================================');
      
      // Compare versions
      return _isVersionLowerThan(currentVersion, requiredVersion);
    } catch (e) {
      print('Error checking if update is required: $e');
      return false;
    }
  }
  
  /// Compare two version strings
  /// Returns true if version1 is lower than version2
  bool _isVersionLowerThan(String version1, String version2) {
    List<int> v1Parts = version1.split('.').map((e) => int.parse(e)).toList();
    List<int> v2Parts = version2.split('.').map((e) => int.parse(e)).toList();
    
    // Ensure both lists have the same length
    while (v1Parts.length < v2Parts.length) v1Parts.add(0);
    while (v2Parts.length < v1Parts.length) v2Parts.add(0);
    
    // Compare each part
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return true;
      if (v1Parts[i] > v2Parts[i]) return false;
    }
    
    // Versions are equal
    return false;
  }
}

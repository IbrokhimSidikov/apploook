import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/remote_config_service.dart';
import '../widgets/update_required_dialog.dart';

class VersionCheckerService {
  static final VersionCheckerService _instance = VersionCheckerService._internal();
  final RemoteConfigService _remoteConfigService = RemoteConfigService();
  
  factory VersionCheckerService() {
    return _instance;
  }

  VersionCheckerService._internal();

  /// Check if an update is required and show a dialog if needed
  /// Returns true if an update is required
  Future<bool> checkForUpdates(BuildContext context) async {
    try {
      // Get current app version
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      
      // Get minimum required version from remote config
      final String requiredVersion = _remoteConfigService.minimumRequiredVersion;
      
      // Check if update is required
      final bool updateRequired = await _remoteConfigService.isUpdateRequired();
      
      if (updateRequired) {
        // Show update required dialog
        if (context.mounted) {
          _showUpdateRequiredDialog(context, currentVersion, requiredVersion);
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return false;
    }
  }

  /// Show update required dialog
  void _showUpdateRequiredDialog(BuildContext context, String currentVersion, String requiredVersion) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return UpdateRequiredDialog(
          currentVersion: currentVersion,
          requiredVersion: requiredVersion,
        );
      },
    );
  }
}

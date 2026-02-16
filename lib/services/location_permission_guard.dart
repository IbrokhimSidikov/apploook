import 'package:flutter/material.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:apploook/services/nearest_branch_service.dart';
import 'package:apploook/widgets/location_permission_dialog.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';

/// Service to guard app usage with location permission requirement
class LocationPermissionGuard {
  static final LocationPermissionGuard _instance = LocationPermissionGuard._internal();
  factory LocationPermissionGuard() => _instance;
  
  LocationPermissionGuard._internal();
  
  final LocationService _locationService = LocationService();
  final NearestBranchService _nearestBranchService = NearestBranchService();
  
  /// Check if location permission is granted, if not show dialog and block app usage
  /// Returns true if permission is granted, false otherwise
  Future<bool> ensureLocationPermission(BuildContext context) async {
    // Check if permission is already granted
    bool hasPermission = await _locationService.checkPermission();
    if (hasPermission) {
      return true;
    }
    
    // Permission not granted, show dialog
    return await _showPermissionDialog(context);
  }
  
  Future<bool> _showPermissionDialog(BuildContext context) async {
    // Check if permission is permanently denied
    bool isPermanentlyDenied = await _locationService.isPermissionPermanentlyDenied();
    
    if (isPermanentlyDenied) {
      return await _showSettingsDialog(context);
    }
    
    // Show permission request dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent dismissing by back button
        child: LocationPermissionDialog(
          onPermissionGranted: () async {
            Navigator.of(context).pop(true);
          },
          onPermissionDenied: () {
            Navigator.of(context).pop(false);
          },
        ),
      ),
    );
    
    if (result == true) {
      final granted = await _locationService.requestPermission();
      if (granted) {
        // Try to find nearest branch
        try {
          await _nearestBranchService.findNearestBranch();
        } catch (e) {
          print('LocationPermissionGuard: Error finding nearest branch: $e');
        }
      }
      return granted;
    }
    
    return false;
  }
  
  Future<bool> _showSettingsDialog(BuildContext context) async {
    bool? dialogResult;
    
    dialogResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false, // Prevent dismissing by back button
        child: LocationSettingsDialog(
          onOpenSettings: () async {
            Navigator.of(dialogContext).pop(true);
          },
          onCancel: () {
            Navigator.of(dialogContext).pop(false);
          },
        ),
      ),
    );
    
    if (dialogResult == true) {
      await Geolocator.openAppSettings();
      
      // Poll for permission changes while user is in settings
      bool granted = false;
      int attempts = 0;
      const maxAttempts = 30; // Poll for up to 30 seconds
      
      while (!granted && attempts < maxAttempts) {
        await Future.delayed(const Duration(seconds: 1));
        granted = await _locationService.checkPermission();
        attempts++;
      }
      
      if (granted) {
        // Try to find nearest branch
        try {
          await _nearestBranchService.findNearestBranch();
        } catch (e) {
          print('LocationPermissionGuard: Error finding nearest branch: $e');
        }
      }
      
      return granted;
    }
    
    return false;
  }
  
  /// Show a blocking dialog that requires location permission to continue
  /// This will keep showing until permission is granted
  Future<void> requireLocationPermission(BuildContext context) async {
    bool hasPermission = false;
    
    while (!hasPermission) {
      hasPermission = await ensureLocationPermission(context);
      
      if (!hasPermission) {
        // Wait a bit before showing dialog again
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
}

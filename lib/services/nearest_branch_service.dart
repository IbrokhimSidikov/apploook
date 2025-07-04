import 'dart:math';
import 'package:apploook/config/branch_config.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:apploook/widget/branch_locations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NearestBranchService {
  static final NearestBranchService _instance = NearestBranchService._internal();
  factory NearestBranchService() => _instance;

  static const String _nearestBranchKey = 'nearest_branch_name';
  static const String _nearestBranchDeliverIdKey = 'nearest_branch_deliver_id';
  
  final LocationService _locationService = LocationService();
  
  NearestBranchService._internal();
  
  // Find the nearest branch based on user's location
  Future<String> findNearestBranch() async {
    try {
      print('🔍 NearestBranchService: Starting nearest branch detection');
      // Check if we have location permission
      bool hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        print('📱 NearestBranchService: No location permission, requesting...');
        hasPermission = await _locationService.requestPermission();
        if (!hasPermission) {
          print('❌ NearestBranchService: Location permission denied, defaulting to Loook Yunusobod');
          // Default to a branch if permission is denied
          return _saveAndReturnBranch('Loook Yunusobod');
        }
      }
      
      // Get current location
      print('📍 NearestBranchService: Getting current location...');
      AppLatLong currentLocation = await _locationService.getCurrentLocation();
      print('📍 NearestBranchService: Current location - Lat: ${currentLocation.lat}, Long: ${currentLocation.long}');
      
      // Calculate nearest branch
      String nearestBranch = _calculateNearestBranch(currentLocation.lat, currentLocation.long);
      print('🏪 NearestBranchService: Nearest branch detected: $nearestBranch');
      
      // Save the nearest branch name for future use
      return _saveAndReturnBranch(nearestBranch);
    } catch (e) {
      print('❌ NearestBranchService: Error finding nearest branch: $e');
      // Default to a branch if there's an error
      return _saveAndReturnBranch('Loook Yunusobod');
    }
  }
  
  // Calculate which branch is closest to the user's location
  String _calculateNearestBranch(double userLat, double userLong) {
    print('🧮 NearestBranchService: Calculating nearest branch from user location');
    double minDistance = double.infinity;
    String nearestBranch = 'Loook Yunusobod'; // Default branch
    
    // Create a map to store all branch distances for logging
    Map<String, double> branchDistances = {};
    
    BranchLocations.branchCoordinates.forEach((branchName, coordinates) {
      List<String> parts = coordinates.split(',');
      if (parts.length == 2) {
        try {
          double branchLat = double.parse(parts[0].trim());
          double branchLong = double.parse(parts[1].trim());
          
          // Calculate distance using the Haversine formula
          double distance = _calculateDistance(userLat, userLong, branchLat, branchLong);
          
          // Store distance for logging
          branchDistances[branchName] = distance;
          
          if (distance < minDistance) {
            minDistance = distance;
            nearestBranch = branchName;
          }
        } catch (e) {
          print('❌ NearestBranchService: Error parsing coordinates for $branchName: $e');
        }
      }
    });
    
    // Log all branch distances for debugging
    print('📊 NearestBranchService: Branch distances from user location:');
    branchDistances.forEach((branch, distance) {
      String marker = branch == nearestBranch ? '✅' : '  ';
      print('  $marker $branch: ${distance.toStringAsFixed(2)} km');
    });
    
    // Get the deliver ID for the nearest branch
    BranchConfig config = BranchConfigs.getConfig(nearestBranch);
    print('🏪 NearestBranchService: Selected branch: $nearestBranch (Deliver ID: ${config.deleverId})');
    
    return nearestBranch;
  }
  
  // Calculate distance between two coordinates using the Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int earthRadius = 6371; // Radius of the earth in km
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // Distance in km
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  // Save the branch name and its deliver ID to SharedPreferences
  Future<String> _saveAndReturnBranch(String branchName) async {
    print('💾 NearestBranchService: Saving nearest branch information');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nearestBranchKey, branchName);
    print('✅ NearestBranchService: Saved branch name: $branchName');
    
    // Get the deliver ID for this branch and save it
    BranchConfig config = BranchConfigs.getConfig(branchName);
    // Save the deliver ID
    await prefs.setString(_nearestBranchDeliverIdKey, config.deleverId);
    print('✅ NearestBranchService: Saved branch deliver ID: ${config.deleverId}');
    
    // Print a summary of the saved branch information
    print('📝 NearestBranchService: BRANCH SUMMARY:');
    print('  • Branch Name: $branchName');
    print('  • Branch ID: ${config.branchId}');
    print('  • Deliver ID: ${config.deleverId}');
    print('  • Merchant ID: ${config.merchantId}');
    
    return branchName;
  }
  
  // Get the saved nearest branch name
  Future<String?> getSavedNearestBranch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nearestBranchKey);
  }
  
  // Get the saved nearest branch deliver ID
  Future<String?> getSavedNearestBranchDeliverId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nearestBranchDeliverIdKey);
  }
}

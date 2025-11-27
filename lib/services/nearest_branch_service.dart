import 'dart:convert';
import 'package:apploook/config/branch_config.dart';
import 'package:apploook/models/app_lat_long.dart';
import 'package:apploook/services/app_location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NearestBranchService {
  static final NearestBranchService _instance = NearestBranchService._internal();
  factory NearestBranchService() => _instance;

  static const String _nearestBranchKey = 'nearest_branch_name';
  static const String _nearestBranchDeliverIdKey = 'nearest_branch_deliver_id';
  static const String _backendApiUrl = 'http://64.23.216.120:3000';
  
  final LocationService _locationService = LocationService();
  
  NearestBranchService._internal();
  
  // Find the nearest branch based on user's location using backend API
  Future<String> findNearestBranch() async {
    try {
      print('🔍 NearestBranchService: Starting nearest branch detection');
      // Check if we have location permission
      bool hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        print('📱 NearestBranchService: No location permission, requesting...');
        hasPermission = await _locationService.requestPermission();
        if (!hasPermission) {
          print('❌ NearestBranchService: Location permission denied, defaulting to Yunusobod');
          // Default to a branch if permission is denied
          return _saveAndReturnBranch('Yunusobod');
        }
      }
      
      // Get current location
      print('📍 NearestBranchService: Getting current location...');
      AppLatLong currentLocation = await _locationService.getCurrentLocation();
      print('📍 NearestBranchService: Current location - Lat: ${currentLocation.lat}, Long: ${currentLocation.long}');
      
      // Call backend API to get nearest branch
      String nearestBranch = await _fetchNearestBranchFromBackend(currentLocation.lat, currentLocation.long);
      print('🏪 NearestBranchService: Nearest branch detected: $nearestBranch');
      
      // Save the nearest branch name for future use
      return _saveAndReturnBranch(nearestBranch);
    } catch (e) {
      print('❌ NearestBranchService: Error finding nearest branch: $e');
      // Default to a branch if there's an error
      return _saveAndReturnBranch('Yunusobod');
    }
  }
  
  // Fetch nearest branch from backend API
  Future<String> _fetchNearestBranchFromBackend(double userLat, double userLong) async {
    try {
      print('🌐 NearestBranchService: Calling backend API...');
      final url = Uri.parse('$_backendApiUrl/branch/nearest?lat=$userLat&long=$userLong');
      print('🌐 NearestBranchService: API URL: $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Backend API request timed out');
        },
      );
      
      print('🌐 NearestBranchService: API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('🌐 NearestBranchService: API Response Data: $responseData');
        
        // Extract branch name from nested response structure
        // Response format: {success: true, data: {branch: {name: "City Boulevard Loook", ...}, distance: 0.19}}
        String branchName = 'Yunusobod'; // Default fallback
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data['branch'] != null) {
            final branch = data['branch'];
            final apiName = branch['name'] as String?;
            final distance = data['distance'];
            final distanceUnit = data['distanceUnit'];
            
            print('🏪 NearestBranchService: Branch details from API:');
            print('  • Branch Name: $apiName');
            print('  • Distance: $distance $distanceUnit');
            
            // Use branch name directly from API (no mapping needed)
            branchName = apiName ?? 'Yunusobod';
          }
        }
        
        print('✅ NearestBranchService: Backend returned branch: $branchName');
        return branchName;
      } else {
        print('❌ NearestBranchService: Backend API error - Status: ${response.statusCode}');
        print('❌ NearestBranchService: Response body: ${response.body}');
        throw Exception('Backend API returned status ${response.statusCode}');
      }
    } catch (e) {
      print('❌ NearestBranchService: Error calling backend API: $e');
      // Fallback to default branch
      return 'Yunusobod';
    }
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

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
  // static const String _backendApiUrl = 'http://64.23.216.120:3000';
  static const String _backendApiUrl = 'https://api.v3.sievesapp.com';

  final LocationService _locationService = LocationService();
  
  NearestBranchService._internal();
  
  // Store the latest menu data from backend
  Map<String, dynamic>? _latestMenuData;
  
  // Get the latest menu data
  Map<String, dynamic>? getLatestMenuData() => _latestMenuData;
  
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
      
      // Call backend API to get nearest branch and menu data
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
      final url = Uri.parse('$_backendApiUrl/branch/menu?lat=$userLat&long=$userLong');
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
        print('🌐 NearestBranchService: API Response Status: Success');
        
        // Extract branch name and menu data from nested response structure
        // Response format: {success: true, data: {branch: {...}, distance: 0.19, categories: [], items: [], productVariationGroups: []}}
        String branchName = 'Yunusobod'; // Default fallback
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Extract branch information
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
          
          // Extract menu data (nested inside "menu" object)
          if (data['menu'] != null) {
            final menuData = data['menu'];
            
            // Extract categories - items are nested inside categories
            List<dynamic> categories = menuData['categories'] ?? [];
            List<dynamic> allItems = [];
            
            // Extract items from each category
            for (var category in categories) {
              if (category is Map && category['items'] != null) {
                var items = category['items'];
                if (items is List) {
                  allItems.addAll(items);
                }
              }
            }
            
            // Handle productVariationGroups - can be Map (object) or List (array)
            var variationGroups = menuData['productVariationGroups'];
            
            _latestMenuData = {
              'categories': categories,
              'items': allItems,
              'productVariationGroups': variationGroups, // Pass as-is (Map or List)
            };
            
            print('📋 NearestBranchService: Menu data extracted:');
            print('  • Categories: ${categories.length}');
            print('  • Items: ${allItems.length}');
            int groupCount = 0;
            if (variationGroups is Map) {
              groupCount = variationGroups.length;
            } else if (variationGroups is List) {
              groupCount = variationGroups.length;
            }
            print('  • Product Variation Groups: $groupCount');
          } else {
            print('⚠️ NearestBranchService: No menu data in response');
            _latestMenuData = null;
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

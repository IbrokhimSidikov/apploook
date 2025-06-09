import 'dart:convert';
import 'dart:math';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/services/api_service.dart';
import 'package:apploook/services/order_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  late ApiService _apiService;
  late OrderModeService _orderModeService;
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  bool _isInitialized = false;

  // Cache constants
  static const String _cacheKey = 'cachedCategoryData';
  static const String _cacheTimestampKey = 'lastCacheUpdateTime';
  static const String _cacheKeyOldApi = 'cachedCategoryDataOldApi';
  static const String _cacheTimestampKeyOldApi = 'lastCacheUpdateTimeOldApi';
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  // Old API endpoint
  static const String _oldApiEndpoint =
      'https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1';

  // Getters
  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  bool get isInitialized => _isInitialized;

  MenuService._internal() {
    _apiService = ApiService(
      clientId: '5e5e55a2-30f4-4adb-b929-a27428be9776',
      clientSecret: 'bG9vb2tBcHBBZ2dAMTpsb29va0FwcEFnZ0Ax',
    );
    _orderModeService = OrderModeService();
  }

  Future<void> initialize() async {
    print('MenuService: Initializing...');
    if (_isInitialized) {
      print('MenuService: Already initialized, returning');
      return;
    }

    // Initialize the order mode service first
    await _orderModeService.initialize();
    print(
        'MenuService: Order mode initialized to: ${_orderModeService.currentMode}');

    try {
      // First try to load from cache if it's valid
      print('MenuService: Checking cache validity');
      bool isCacheValid = await _isCacheValid();
      print('MenuService: Cache valid: $isCacheValid');

      if (isCacheValid) {
        print('MenuService: Loading from cache');
        final loaded = await _loadFromCache();
        if (loaded) {
          _isInitialized = true;
          print(
              'MenuService: Initialized from cache, refreshing data in background');

          // Refresh data in background even if we loaded from cache
          refreshData().catchError((e) {
            print('MenuService: Background refresh error: $e');
          });
        } else {
          print('MenuService: Cache is valid but data is null');
        }
      } else {
        print('MenuService: Cache is not valid or missing');
      }

      // If not initialized from cache, fetch fresh data
      if (!_isInitialized) {
        print('MenuService: Not initialized from cache, fetching fresh data');
        await refreshData();
      }
    } catch (e, stackTrace) {
      print('MenuService: Error initializing: $e');
      print('MenuService: Stack trace: $stackTrace');
      if (!_isInitialized) {
        print('MenuService: Not initialized, throwing exception');
        throw Exception('Failed to initialize menu data: $e');
      }
    }
  }

  Future<bool> _isCacheValid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use different cache keys based on the order mode
    final String timestampKey =
        _orderModeService.currentMode == OrderMode.deliveryTakeaway
            ? _cacheTimestampKey
            : _cacheTimestampKeyOldApi;

    final lastUpdateTime = prefs.getInt(timestampKey);
    if (lastUpdateTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - lastUpdateTime) <
        _cacheValidityDuration.inMilliseconds;
  }

  Future<bool> _loadFromCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Use different cache keys based on the order mode
      final String cacheKey =
          _orderModeService.currentMode == OrderMode.deliveryTakeaway
              ? _cacheKey
              : _cacheKeyOldApi;

      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return false;

      final decodedData = json.decode(cachedData);
      _processCategoryData(decodedData);
      return true;
    } catch (e) {
      print('MenuService: Error loading from cache: $e');
      return false;
    }
  }

  // Process category data from either API format
  void _processCategoryData(dynamic data) {
    try {
      if (data is Map<String, dynamic> && data.containsKey('categories')) {
        // Process in standard API format
        List<dynamic> categories = data['categories'] ?? [];
        List<dynamic> items = data['items'] ?? [];

        if (_orderModeService.currentMode == OrderMode.deliveryTakeaway) {
          _processNewApiData(categories, items, data);
        } else {
          _processOldApiData(data);
        }
      } else if (data is Map<String, dynamic> && data.containsKey('items')) {
        // Just items array, process as old API format
        _processOldApiData(data);
      } else {
        print('MenuService: Unknown data format, creating default data');
        _createDefaultData();
      }
    } catch (e) {
      print('MenuService: Error processing category data: $e');
      _createDefaultData();
    }
  }

  Future<void> refreshData() async {
    print(
        'MenuService: Starting refreshData for mode: ${_orderModeService.currentMode}');
    try {
      // Use different APIs based on the order mode
      if (_orderModeService.currentMode == OrderMode.deliveryTakeaway) {
        // Fetch from the new API for delivery/takeaway
        print('MenuService: Fetching menu items from new API service');
        final menuItems = await _apiService.getMenuItems();
        print(
            'MenuService: Received menu items from new API, count: ${menuItems.length}');

        // Extract the data from the response
        final apiData = menuItems.isNotEmpty && menuItems[0] is Map
            ? menuItems[0]
            : {'categories': [], 'items': []};
        print('MenuService: API data structure: ${apiData.keys.toList()}');

        // Based on the logs, we can see the API returns both categories and items
        List<dynamic> categories = apiData['categories'] ?? [];
        List<dynamic> directItems = apiData['items'] ?? [];

        print(
            'MenuService: API returned ${categories.length} categories and ${directItems.length} direct items');

        // Process data from the new API
        await _processNewApiData(categories, directItems, apiData);
      } else {
        // Fetch from the old API endpoint
        print('MenuService: Fetching menu items from old API service');
        print('MenuService: Old API endpoint: $_oldApiEndpoint');
        final response = await http.get(Uri.parse(_oldApiEndpoint));

        // Log the full response body for testing
        print('MenuService: OLD API RESPONSE FULL BODY:');
        print(response.body);

        if (response.statusCode == 200) {
          // Based on the original code, the response is a List<dynamic> directly, not a Map
          final List<dynamic> categoryData = json.decode(response.body);
          print('MenuService: Received data from old API');
          print('MenuService: Old API returned ${categoryData.length} categories');
          if (categoryData.isNotEmpty) {
            print('MenuService: First category sample: ${json.encode(categoryData[0])}');
            // Check if the first item has products
            if (categoryData[0]['products'] != null && categoryData[0]['products'] is List) {
              print('MenuService: First category has ${(categoryData[0]['products'] as List).length} products');
            }
          }

          // Process data from the old API in the List format
          await _processOldApiCategoryList(categoryData);
        } else {
          print('MenuService: Error fetching from old API: ${response.statusCode}');
          print('MenuService: Error response: ${response.body}');
          // Create default data if API fails
          _createDefaultData();
        }
      }
    } catch (e, stackTrace) {
      print('MenuService: Error refreshing data: $e');
      print('MenuService: Stack trace: $stackTrace');
      // Create default data if there's an error
      _createDefaultData();
    }
  }

  // Process data from the old API in List format (for carhop mode)
  Future<void> _processOldApiCategoryList(List<dynamic> categoryList) async {
    try {
      print('MenuService: Processing old API category list with ${categoryList.length} categories');
      
      // Reset collections
      _categories = [];
      _allProducts = [];
      
      if (categoryList.isEmpty) {
        print('MenuService: Category list is empty, creating default category');
        _createDefaultData();
        return;
      }
      
      int processedCategories = 0;
      int processedProducts = 0;
      
      // Process each category in the list
      for (var category in categoryList) {
        if (category is Map<String, dynamic>) {
          // Extract category information
          String rawCategoryName = category['name'] ?? 'Unknown Category';
          String categoryName = _formatCategoryName(rawCategoryName);
          
          // Skip categories with blank, empty names or default unknown names
          if (categoryName.trim().isEmpty || categoryName == 'Unknown Category' || 
              categoryName == 'Menu Item') {
            print('MenuService: Skipping blank category: "$rawCategoryName"');
            continue;
          }
          
          int categoryId = int.tryParse(category['id']?.toString() ?? '0') ?? 0;
          
          if (categoryId <= 0) {
            categoryId = _getUniqueCategoryId(_nextCategoryId);
          }
          
          // Process products in this category
          List<dynamic> products = category['products'] ?? [];
          print('MenuService: Category $categoryName has ${products.length} products');
          
          // Skip categories that don't have any products
          if (products.isEmpty) {
            print('MenuService: Skipping empty category: $categoryName (no products)');
            continue;
          }
          
          print('MenuService: Processing category: $categoryName (ID: $categoryId)');
          
          // Create category
          _categories.add(Category(id: categoryId, name: categoryName));
          processedCategories++;
          
          for (var product in products) {
            if (product is Map<String, dynamic>) {
              _processOldApiProduct(product, categoryId, categoryName);
              processedProducts++;
            }
          }
        }
      }
      
      print('MenuService: Successfully processed $processedCategories categories with $processedProducts total products');
      
      // If we ended up with no categories or products, create default data
      if (_categories.isEmpty || _allProducts.isEmpty) {
        print('MenuService: No valid categories or products found, creating default data');
        _createDefaultData();
        return;
      }
      
      _isInitialized = true;
      print('MenuService: Processed ${_categories.length} categories and ${_allProducts.length} products from old API');
      
      // Cache the data for future use
      print('MenuService: Updating old API cache');
      await _updateCache({'categories': categoryList}, isNewApi: false);
      print('MenuService: Old API cache updated successfully');
    } catch (e, stackTrace) {
      print('MenuService: Error processing old API category list: $e');
      print('MenuService: Stack trace: $stackTrace');
      _createDefaultData();
    }
  }
  
  // Process data from the old API format (map structure)
  Future<void> _processOldApiData(Map<String, dynamic> data) async {
    try {
      print('MenuService: Processing old API data');
      print('MenuService: Old API data structure: ${data.keys.toList()}'); 

      // Reset collections
      _categories = [];
      _allProducts = [];

      // Check if categories exist in data
      if (data['categories'] != null && data['categories'] is List) {
        List<dynamic> categoryData = data['categories'];
        print('MenuService: Found ${categoryData.length} categories in old API data');
        print('MenuService: First category sample: ${categoryData.isNotEmpty ? json.encode(categoryData.first) : "none"}');

        // Create a map to group items by category ID
        Map<int, List<Map<String, dynamic>>> itemsByCategory = {};

        // Process items and group them by category
        final items = data['items'] as List<dynamic>? ?? [];
        print('MenuService: Old API returned ${items.length} items');
        if (items.isNotEmpty) {
          print('MenuService: First item sample: ${json.encode(items.first)}');
          print('MenuService: Item category_id format: ${items.first['category_id'] != null ? items.first['category_id'].runtimeType : "null"}');
        }

        // First pass: group items by category ID
        int itemsWithCategories = 0;
        for (var item in items) {
          if (item is Map<String, dynamic>) {
            int categoryId = 0;
            if (item['category_id'] != null) {
              categoryId = int.tryParse(item['category_id'].toString()) ?? 0;
              if (categoryId > 0) {
                itemsWithCategories++;
              }
            }

            if (categoryId > 0) {
              itemsByCategory.putIfAbsent(categoryId, () => []).add(item);
            }
          }
        }
        
        print('MenuService: Items with valid categories: $itemsWithCategories');
        print('MenuService: Category groups created: ${itemsByCategory.keys.length}');
        if (itemsByCategory.isNotEmpty) {
          print('MenuService: Sample category items count: ${itemsByCategory.values.first.length}');
        }

        // Now we process categories with their items
        int processedCategories = 0;
        for (var category in categoryData) {
          if (category is Map<String, dynamic>) {
            String categoryName = category['name'] ?? 'Unknown Category';
            int categoryId = int.tryParse(category['id']?.toString() ?? '0') ?? 0;
            print('MenuService: Processing category: $categoryName (ID: $categoryId)');

            // Skip empty/special categories
            if (categoryId > 0) {
              // Get items for this category
              List<Map<String, dynamic>> categoryItems = itemsByCategory[categoryId] ?? [];
              print('MenuService: Category $categoryName has ${categoryItems.length} items');

              // If we have items for this category, add it
              if (categoryItems.isNotEmpty) {
                // Ensure unique category ID
                int uniqueCategoryId = _getUniqueCategoryId(categoryId);
                print('MenuService: Using unique category ID: $uniqueCategoryId for original ID: $categoryId');

                // Create the category
                _categories.add(Category(id: uniqueCategoryId, name: categoryName));
                processedCategories++;

                // Process all items for this category
                for (var item in categoryItems) {
                  _processOldApiItem(item, uniqueCategoryId, categoryName);
                }
              }
            }
          }
        }
        print('MenuService: Successfully processed $processedCategories categories');
      } else {
        // If we don't have categories, create a default one and put all items there
        _categories.add(Category(id: 1, name: 'All Items'));

        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          _processOldApiItem(item, 1, 'All Items');
        }
      }
      
      _isInitialized = true;
      print('MenuService: Processed ${_categories.length} categories and ${_allProducts.length} products from old API');

      // Cache the data for future use
      print('MenuService: Updating old API cache');
      await _updateCache(data, isNewApi: false);
      print('MenuService: Old API cache updated successfully');
    } catch (e, stackTrace) {
      print('MenuService: Error processing old API data: $e');
      print('MenuService: Stack trace: $stackTrace');
      _createDefaultData();
    }
  }

  // Process a product from the old API list format (for carhop mode)
  void _processOldApiProduct(Map<String, dynamic> product, int categoryId, String categoryName) {
    try {
      print('MenuService: Processing product: ${product['name'] ?? product['title'] ?? 'Unknown'} for category ID: $categoryId');
      print('MenuService: Raw product data: ${json.encode(product).substring(0, min(200, json.encode(product).length))}...');
      
      // Extract product information
      String name = product['name'] ?? product['title'] ?? 'Unknown Product';
      
      // Extract price safely - in the old API, price might be directly in product or in priceList
      double price = 0.0;
      
      // Check for priceList first (this is the format from the provided sample code)
      if (product['priceList'] != null && product['priceList']['price'] != null) {
        var priceValue = product['priceList']['price'];
        if (priceValue is double) {
          price = priceValue;
        } else if (priceValue is int) {
          price = priceValue.toDouble();
        } else {
          try {
            price = double.tryParse(priceValue.toString()) ?? 0.0;
          } catch (e) {
            print('MenuService: Error parsing price from priceList: $e');
          }
        }
        print('MenuService: Using price from priceList: $price');
      } 
      // Fall back to direct price field
      else if (product['price'] != null) {
        var rawPrice = product['price'];
        if (rawPrice is double) {
          price = rawPrice;
        } else if (rawPrice is int) {
          price = rawPrice.toDouble();
        } else {
          try {
            price = double.tryParse(rawPrice.toString()) ?? 0.0;
          } catch (e) {
            print('MenuService: Error parsing direct price: $e');
          }
        }
        print('MenuService: Using direct price field: $price');
      }
      
      // Generate unique product ID
      int originalId = int.tryParse(product['id']?.toString() ?? '0') ?? 0;
      int id = _getUniqueProductId(originalId);
      String uuid = product['id']?.toString() ?? '';
      
      // Extract description - handle different formats safely
      String description = '';
      var rawDescription = product['description'];
      if (rawDescription != null) {
        if (rawDescription is String) {
          description = rawDescription;
          print('MenuService: Got plain text description, length: ${description.length}');
        } else if (rawDescription is Map) {
          if (rawDescription['en'] != null) {
            description = rawDescription['en'].toString();
          } else if (rawDescription.isNotEmpty) {
            description = rawDescription.values.first.toString();
          }
          print('MenuService: Extracted description from map, length: ${description.length}');
        } else {
          description = rawDescription.toString();
        }
      }
      
      // Extract image path - handle the standardized format from the sievesapp API
      String? imagePath;
      
      // First check for photo with path/name/format structure (from the MenuItem.fromJson example)
      if (product['photo'] != null) {
        var photo = product['photo'];
        print('MenuService: Found photo: $photo');
        
        if (photo is Map<String, dynamic>) {
          // Check for the standard format with path/name/format
          if (photo['path'] != null && photo['name'] != null && photo['format'] != null) {
            // Format like the MenuItem.fromJson example
            imagePath = 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}';
            print('MenuService: Constructed image path from path/name/format: $imagePath');
          }
          // Fall back to URL if available
          else if (photo['url'] != null) {
            imagePath = photo['url'].toString();
            print('MenuService: Using photo URL directly: $imagePath');
          }
        } else if (photo is String) {
          // Direct photo URL
          imagePath = photo;
          print('MenuService: Using direct photo string: $imagePath');
        }
      }
      // Fall back to image field
      else if (product['image'] != null) {
        imagePath = product['image'].toString();
        print('MenuService: Using image field: $imagePath');
      }
      
      // Create product and add to collection
      Product newProduct = Product(
        id: id,
        uuid: uuid,
        name: name,
        description: description,
        price: price,
        imagePath: imagePath,
        categoryId: categoryId,
        categoryTitle: categoryName,
      );
      
      _allProducts.add(newProduct);
      print('MenuService: Added product $name with ID $id to category $categoryName (ID: $categoryId)');
    } catch (e) {
      print('MenuService: Error processing product: $e');
    }
  }
  
  // Process an item from the old API format
  void _processOldApiItem(Map<String, dynamic> item,
      [int categoryId = 1, String categoryName = 'All Items']) {
    try {
      // First, debug log the item being processed
      print('MenuService: Processing item: ${item['name'] ?? item['title'] ?? 'Unknown'} for category ID: $categoryId');

      // Validate the category ID exists
      bool categoryExists = _categories.any((category) => category.id == categoryId);
      if (!categoryExists) {
        print('MenuService: WARNING - Category with ID $categoryId not found in the list');
        // If the category doesn't exist, use the first available category or create one
        if (_categories.isNotEmpty) {
          categoryId = _categories.first.id;
          categoryName = _categories.first.name;
          print('MenuService: Using fallback category: $categoryName (ID: $categoryId) instead');
        } else {
          print('MenuService: No categories available, creating "All Items" category');
          categoryId = 1;
          categoryName = 'All Items';
          _categories.add(Category(id: categoryId, name: categoryName));
        }
      }

      // Extract price safely
      double price = 0.0;
      if (item['price'] != null) {
        if (item['price'] is double) {
          price = item['price'];
        } else if (item['price'] is int) {
          price = (item['price'] as int).toDouble();
        } else {
          try {
            price = double.tryParse(item['price'].toString()) ?? 0.0;
          } catch (e) {
            print('MenuService: Error parsing price: $e');
          }
        }
      }

      // Extract the unique ID and UUID
      int id = _getUniqueProductId(item['id'] ?? 0);
      String uuid = item['id']?.toString() ?? '';

      // Extract description - handle different formats safely
      String description = '';
      var rawDescription = item['description'];
      if (rawDescription != null) {
        if (rawDescription is String) {
          // Plain text description
          description = rawDescription;
          print('MenuService: Got plain text description, length: ${description.length}');
        } else if (rawDescription is Map) {
          // Map structure description, likely in multiple languages
          // Try to get English description or any available language
          if (rawDescription['en'] != null) {
            description = rawDescription['en'].toString();
          } else if (rawDescription.isNotEmpty) {
            // Take first available language
            description = rawDescription.values.first.toString();
          }
          print('MenuService: Extracted description from map, length: ${description.length}');
        } else {
          // Handle unexpected formats
          try {
            description = rawDescription.toString();
            print('MenuService: Converted description to string, length: ${description.length}');
          } catch (e) {
            print('MenuService: Failed to parse description: $e');
          }
        }
      }

      // Extract image path
      String? imagePath = item['image'];
      if (imagePath == null && item['photo'] != null) {
        var photo = item['photo'];
        if (photo is Map<String, dynamic>) {
          if (photo['url'] != null) {
            imagePath = photo['url'];
            print('MenuService: Found image URL in photo: $imagePath');
          }
        }
      }

      // Create a product with the provided category info
      final product = Product(
        id: id,
        uuid: uuid, // Use the same ID as UUID for old API
        name: item['name'] ?? 'Unknown Product',
        categoryId: categoryId, // Use the provided category ID
        categoryTitle: categoryName, // Use the provided category name
        price: price,
        description: description,
        imagePath: imagePath,
      );

      _allProducts.add(product);
    } catch (e) {
      print('MenuService: Error processing old API item: $e');
    }
  }

  // Process data from the new API format
  Future<void> _processNewApiData(List<dynamic> categories,
      List<dynamic> directItems, Map<String, dynamic> apiData) async {
    try {
      // Reset collections
      _categories = [];
      _allProducts = [];

      // Create a map to store category ID strings to int IDs for reference
      Map<String, int> categoryIdMap = {};

      // Process categories first
      print('MenuService: Processing categories');
      for (var category in categories) {
        try {
          // Extract the original category ID (which is now a string UUID)
          String originalCategoryId =
              category['id'] != null ? category['id'].toString() : '';

          // Generate a unique integer ID for internal use
          int categoryId =
              _getUniqueCategoryId(categories.indexOf(category) + 1);
          print(
              'MenuService: Original category ID: $originalCategoryId, assigned unique ID: $categoryId');

          // Store the mapping from string ID to int ID
          categoryIdMap[originalCategoryId] = categoryId;

          final categoryName = category['name'] ?? 'Unknown Category';
          // Capture sortOrder but we don't need to use it right now
          // final sortOrder = category['sortOrder'] ?? 0;

          print(
              'MenuService: Processing category: $categoryName (ID: $categoryId)');

          // Add to categories list with a guaranteed non-zero ID
          _categories.add(Category(id: categoryId, name: categoryName));
        } catch (e) {
          print('MenuService: Error processing category: $e');
          print('MenuService: Category data: $category');
        }
      }

      if (directItems.isNotEmpty) {
        print('MenuService: Processing ${directItems.length} direct items');

        for (var item in directItems) {
          try {
            String categoryIdString =
                item['categoryId'] != null ? item['categoryId'].toString() : '';

            int categoryId = categoryIdMap[categoryIdString] ?? 0;

            if (categoryId == 0) {
              String categoryName = '';
              for (var category in categories) {
                if (category['id'] == categoryIdString) {
                  categoryName = category['name'] ?? '';
                  break;
                }
              }

              if (categoryName.isNotEmpty) {
                var matchingCategory = _categories.firstWhere(
                  (c) => c.name == categoryName,
                  orElse: () => Category(id: 0, name: ''),
                );
                if (matchingCategory.id != 0) {
                  categoryId = matchingCategory.id;
                }
              }
            }

            // If we still don't have a valid category ID, create a new category
            if (categoryId == 0) {
              print(
                  'MenuService: Could not find category for item ${item['name']}, creating default category');
              categoryId = _getUniqueCategoryId(_nextCategoryId);
              _categories.add(Category(id: categoryId, name: 'Other'));
            }

            // Find the category name
            String categoryName = '';
            for (var category in _categories) {
              if (category.id == categoryId) {
                categoryName = category.name;
                break;
              }
            }

            // Process the item with the appropriate category ID and name
            _processItem(item, categoryId, categoryName);
          } catch (e) {
            print('MenuService: Error processing direct item: $e');
            print('MenuService: Item data: $item');
          }
        }
      }

      // If we still don't have any categories or products, create a default one
      if (_categories.isEmpty) {
        print(
            'MenuService: No categories found at all, creating default category');
        _categories = [Category(id: 1, name: 'All Items')];
      }

      if (_allProducts.isEmpty) {
        print('MenuService: No products found, creating a sample product');
        _allProducts.add(Product(
          id: 1,
          uuid: 'sample-1',
          name: 'Sample Product',
          categoryId: 1,
          categoryTitle: 'All Items',
          price: 9.99,
          imagePath: null,
          description: 'This is a sample product for testing',
        ));
      }

      _isInitialized = true;
      print(
          'MenuService: Processed ${_categories.length} categories and ${_allProducts.length} products');

      // Cache the data for future use
      print('MenuService: Updating cache');
      await _updateCache(apiData, isNewApi: true);
      print('MenuService: Cache updated successfully');

      _isInitialized = true;
    } catch (e, stackTrace) {
      print('MenuService: Error processing new API data: $e');
      print('MenuService: Stack trace: $stackTrace');
      _createDefaultData();
    }
  }

  // Keep track of used IDs to ensure uniqueness
  final Set<int> _usedProductIds = {};
  final Set<int> _usedCategoryIds = {};
  int _nextProductId = 1000; // Start with a high number to avoid conflicts
  int _nextCategoryId = 100; // Start with a high number to avoid conflicts

  // Get a unique product ID
  int _getUniqueProductId(int originalId) {
    // If the original ID is valid (not 0) and not already used, use it
    if (originalId > 0 && !_usedProductIds.contains(originalId)) {
      _usedProductIds.add(originalId);
      return originalId;
    }

    // Otherwise, generate a new unique ID
    while (_usedProductIds.contains(_nextProductId)) {
      _nextProductId++;
    }

    _usedProductIds.add(_nextProductId);
    return _nextProductId++;
  }

  // Get a unique category ID
  int _getUniqueCategoryId(int originalId) {
    // If the original ID is valid (not 0) and not already used, use it
    if (originalId > 0 && !_usedCategoryIds.contains(originalId)) {
      _usedCategoryIds.add(originalId);
      return originalId;
    }

    // Otherwise, generate a new unique ID
    while (_usedCategoryIds.contains(_nextCategoryId)) {
      _nextCategoryId++;
    }

    _usedCategoryIds.add(_nextCategoryId);
    return _nextCategoryId++;
  }

  // Helper method to process an individual item
  void _processItem(
      Map<dynamic, dynamic> item, int categoryId, String categoryName) {
    try {
      print(
          'MenuService: Processing item: ${item['name'] ?? item['title'] ?? 'Unknown'}');

      // Extract basic product information
      int originalId = item['id'] is int
          ? item['id']
          : int.tryParse(item['id'].toString()) ?? 0;
      // Generate a unique ID if the original is 0 or duplicate
      final id = _getUniqueProductId(originalId);
      print(
          'MenuService: Item original ID: $originalId, assigned unique ID: $id');

      final name = item['name'] ?? item['title'] ?? 'Unknown';
      print('MenuService: Item name: $name');

      // Handle different price formats
      double price = 0.0;
      if (item['price'] != null) {
        print('MenuService: Item has price field: ${item['price']}');
        price = item['price'] is double
            ? item['price']
            : double.tryParse(item['price'].toString()) ?? 0.0;
      } else if (item['priceList'] != null &&
          item['priceList']['price'] != null) {
        print(
            'MenuService: Item has priceList field: ${item['priceList']['price']}');
        price = item['priceList']['price'] is double
            ? item['priceList']['price']
            : double.tryParse(item['priceList']['price'].toString()) ?? 0.0;
      } else {
        print('MenuService: Item has no price field, using default 0.0');
      }
      print('MenuService: Final price: $price');

      // Handle different image formats
      String? imagePath;

      // Check for images array first (new format)
      if (item['images'] != null &&
          item['images'] is List &&
          (item['images'] as List).isNotEmpty) {
        print(
            'MenuService: Item has images array with ${(item['images'] as List).length} images');
        var firstImage = (item['images'] as List).first;
        if (firstImage is Map && firstImage['url'] != null) {
          imagePath = firstImage['url'].toString();
          print(
              'MenuService: Using first image URL from images array: $imagePath');
        }
      }
      // Fall back to image field
      else if (item['image'] != null) {
        print('MenuService: Item has image field: ${item['image']}');
        imagePath = item['image'].toString();
      }
      // Fall back to photo field
      else if (item['photo'] != null) {
        print('MenuService: Item has photo field');
        var photo = item['photo'];
        if (photo['url'] != null) {
          imagePath = photo['url'].toString();
          print('MenuService: Using photo URL: $imagePath');
        } else if (photo['path'] != null &&
            photo['name'] != null &&
            photo['format'] != null) {
          imagePath =
              'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}';
          print('MenuService: Constructed image path: $imagePath');
        } else {
          print('MenuService: Photo field missing required attributes');
        }
      } else {
        print('MenuService: Item has no images, image, or photo field');
      }

      // Get description
      final description = item['description'] ?? '';
      print(
          'MenuService: Item description length: ${description.toString().length}');

      // Store the original UUID from the API
      String uuid = '';
      if (item['id'] != null) {
        uuid = item['id'].toString();
      }
      print('MenuService: Original item UUID: $uuid');

      // Create the product
      final product = Product(
        id: id,
        uuid: uuid, // Include the original UUID
        name: name,
        categoryId: categoryId,
        categoryTitle: categoryName,
        price: price,
        imagePath: imagePath,
        description: description,
      );

      print(
          'MenuService: Created product: ${product.name} (ID: ${product.id})');
      _allProducts.add(product);
      print(
          'MenuService: Added product to allProducts list, new count: ${_allProducts.length}');
    } catch (e, stackTrace) {
      print('MenuService: Error processing item: $e');
      print('MenuService: Item data: $item');
      print('MenuService: Stack trace: $stackTrace');
    }
  }

  // This method has been integrated directly into refreshData

  // Format category names to proper display format
  String _formatCategoryName(String rawName) {
    if (rawName.isEmpty) return 'Unknown Category';
    
    // Replace underscores with spaces
    String name = rawName.replaceAll('_', ' ');
    
    // Remove the portion starting with numbers (e.g., "Kids Meal 8 H" -> "Kids Meal")
    RegExp numbersStartRegex = RegExp(r'\s+\d');
    Match? match = numbersStartRegex.firstMatch(name);
    if (match != null) {
      name = name.substring(0, match.start);
    }
    
    // If the name ends with certain patterns like "- H", "- M", etc., remove them
    RegExp endPatternRegex = RegExp(r'\s*-\s*[A-Za-z]\s*$');
    name = name.replaceAll(endPatternRegex, '');
    
    // Trim any excess whitespace
    name = name.trim();
    
    // Capitalize each word
    List<String> words = name.split(' ');
    words = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).toList();
    
    // Ensure we return something meaningful
    String result = words.join(' ');
    return result.isEmpty ? 'Menu Item' : result;
  }

  // Create default data when API fails or returns empty data
  void _createDefaultData() {
    print('MenuService: Creating default data');

    // Reset collections
    _categories = [];
    _allProducts = [];

    // Add default category
    _categories.add(Category(id: 1, name: 'All Items'));

    // Add a sample product
    _allProducts.add(Product(
      id: 1,
      uuid: 'sample-1',
      name: 'Sample Product',
      categoryId: 1,
      categoryTitle: 'All Items',
      price: 9.99,
      imagePath: null,
      description: 'This is a sample product for testing',
    ));

    _isInitialized = true;
    print(
        'MenuService: Created default data with ${_categories.length} categories and ${_allProducts.length} products');
  }

  // Update the cache with the latest data
  Future<void> _updateCache(dynamic data, {bool isNewApi = true}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Use different cache keys based on the API used
      final String cacheKey = isNewApi ? _cacheKey : _cacheKeyOldApi;
      final String timestampKey =
          isNewApi ? _cacheTimestampKey : _cacheTimestampKeyOldApi;

      await prefs.setString(cacheKey, json.encode(data));
      await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
      print('MenuService: Updated cache for ${isNewApi ? 'new' : 'old'} API');
    } catch (e) {
      print('MenuService: Error updating cache: $e');
    }
  }

  // Legacy method removed as it's no longer used

  // This method can be used if you need to convert between model types
  // Uncomment when needed
  /*
  Product convertMenuItemToProduct(MenuItem item) {
    return Product(
      name: item.name,
      id: item.id,
      categoryId: item.categoryId,
      categoryTitle: item.categoryTitle,
      imagePath: item.imagePath,
      price: item.price,
      description: item.description
    );
  }
  */
}

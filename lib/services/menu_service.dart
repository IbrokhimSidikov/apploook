import 'dart:convert';

import 'package:apploook/pages/homenew.dart';
import 'package:apploook/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  late ApiService _apiService;
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  bool _isInitialized = false;

  // Cache constants
  static const String _cacheKey = 'cachedCategoryData';
  static const String _cacheTimestampKey = 'lastCacheUpdateTime';
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  // Getters
  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  bool get isInitialized => _isInitialized;

  MenuService._internal() {
    _apiService = ApiService(
      clientId: '5e5e55a2-30f4-4adb-b929-a27428be9776',
      clientSecret: 'bG9vb2tBcHBBZ2dAMTpsb29va0FwcEFnZ0Ax',
    );
  }

  Future<void> initialize() async {
    print('MenuService: Initializing...');
    if (_isInitialized) {
      print('MenuService: Already initialized, returning');
      return;
    }

    try {
      // First try to load from cache if it's valid
      print('MenuService: Checking cache validity');
      bool isCacheValid = false;
      try {
        isCacheValid = await _isCacheValid();
        print('MenuService: Cache valid: $isCacheValid');
      } catch (e) {
        print('MenuService: Error checking cache validity: $e');
      }
      
      if (isCacheValid) {
        print('MenuService: Loading from cache');
        try {
          final cachedData = await _loadFromCache();
          if (cachedData != null) {
            print('MenuService: Processing cached data');
            _processCategoryData(cachedData);
            _isInitialized = true;
            print('MenuService: Successfully initialized from cache');
          } else {
            print('MenuService: Cache is valid but data is null');
          }
        } catch (e) {
          print('MenuService: Error loading from cache: $e');
        }
      } else {
        print('MenuService: Cache is not valid or missing');
      }

      // If not initialized from cache, fetch fresh data
      if (!_isInitialized) {
        print('MenuService: Not initialized from cache, fetching fresh data');
        await refreshData();
      } else {
        print('MenuService: Already initialized from cache, still refreshing data in background');
        // Refresh data in background even if we loaded from cache
        refreshData().catchError((e) {
          print('MenuService: Background refresh error: $e');
        });
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
    final lastUpdateTime = prefs.getInt(_cacheTimestampKey);
    if (lastUpdateTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - lastUpdateTime) <
        _cacheValidityDuration.inMilliseconds;
  }

  Future<List<dynamic>?> _loadFromCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        return json.decode(cachedData);
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  Future<void> refreshData() async {
    print('MenuService: Starting refreshData');
    try {
      // Fetch the raw API response directly using getMenuItems
      print('MenuService: Fetching menu items from API service');
      final menuItems = await _apiService.getMenuItems();
      print('MenuService: Received menu items from API, count: ${menuItems.length}');
      
      // Extract the data from the response
      final apiData = menuItems.isNotEmpty && menuItems[0] is Map ? menuItems[0] : {'categories': [], 'items': []};
      print('MenuService: API data structure: ${apiData.keys.toList()}');
      
      // Based on the logs, we can see the API returns both categories and items
      List<dynamic> categories = apiData['categories'] ?? [];
      List<dynamic> directItems = apiData['items'] ?? [];
      
      print('MenuService: API returned ${categories.length} categories and ${directItems.length} direct items');
      
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
          String originalCategoryId = category['id'] != null ? category['id'].toString() : '';
          
          // Generate a unique integer ID for internal use
          int categoryId = _getUniqueCategoryId(categories.indexOf(category) + 1);
          print('MenuService: Original category ID: $originalCategoryId, assigned unique ID: $categoryId');
          
          // Store the mapping from string ID to int ID
          categoryIdMap[originalCategoryId] = categoryId;
          
          final categoryName = category['name'] ?? 'Unknown Category';
          // Capture sortOrder but we don't need to use it right now
          // final sortOrder = category['sortOrder'] ?? 0;
          
          print('MenuService: Processing category: $categoryName (ID: $categoryId)');
          
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
            String categoryIdString = item['categoryId'] != null ? item['categoryId'].toString() : '';
            
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
              print('MenuService: Could not find category for item ${item['name']}, creating default category');
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
        print('MenuService: No categories found at all, creating default category');
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
      print('MenuService: Processed ${_categories.length} categories and ${_allProducts.length} products');
      
      // Cache the data for future use
      print('MenuService: Updating cache');
      await _updateCache(apiData);
      print('MenuService: Cache updated successfully');
    } catch (e, stackTrace) {
      print('MenuService: Error refreshing data: $e');
      print('MenuService: Stack trace: $stackTrace');
      rethrow;
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
  void _processItem(Map<dynamic, dynamic> item, int categoryId, String categoryName) {
    try {
      print('MenuService: Processing item: ${item['name'] ?? item['title'] ?? 'Unknown'}');
      
      // Extract basic product information
      int originalId = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
      // Generate a unique ID if the original is 0 or duplicate
      final id = _getUniqueProductId(originalId);
      print('MenuService: Item original ID: $originalId, assigned unique ID: $id');
      
      final name = item['name'] ?? item['title'] ?? 'Unknown';
      print('MenuService: Item name: $name');
      
      // Handle different price formats
      double price = 0.0;
      if (item['price'] != null) {
        print('MenuService: Item has price field: ${item['price']}');
        price = item['price'] is double 
            ? item['price'] 
            : double.tryParse(item['price'].toString()) ?? 0.0;
      } else if (item['priceList'] != null && item['priceList']['price'] != null) {
        print('MenuService: Item has priceList field: ${item['priceList']['price']}');
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
      if (item['images'] != null && item['images'] is List && (item['images'] as List).isNotEmpty) {
        print('MenuService: Item has images array with ${(item['images'] as List).length} images');
        var firstImage = (item['images'] as List).first;
        if (firstImage is Map && firstImage['url'] != null) {
          imagePath = firstImage['url'].toString();
          print('MenuService: Using first image URL from images array: $imagePath');
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
        } else if (photo['path'] != null && photo['name'] != null && photo['format'] != null) {
          imagePath = 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}';
          print('MenuService: Constructed image path: $imagePath');
        } else {
          print('MenuService: Photo field missing required attributes');
        }
      } else {
        print('MenuService: Item has no images, image, or photo field');
      }
      
      // Get description
      final description = item['description'] ?? '';
      print('MenuService: Item description length: ${description.toString().length}');
      
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
      
      print('MenuService: Created product: ${product.name} (ID: ${product.id})');
      _allProducts.add(product);
      print('MenuService: Added product to allProducts list, new count: ${_allProducts.length}');
    } catch (e, stackTrace) {
      print('MenuService: Error processing item: $e');
      print('MenuService: Item data: $item');
      print('MenuService: Stack trace: $stackTrace');
    }
  }

  // This method has been integrated directly into refreshData

  Future<void> _updateCache(dynamic data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, json.encode(data));
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating cache: $e');
    }
  }

  void _processCategoryData(List<dynamic> categoryData) {
    List<Category> newCategories = [];
    List<Product> mergedProducts = [];

    for (var category in categoryData) {
      // Extract category information
      String categoryName = '';
      int categoryId = 0;
      List<dynamic> productData = [];
      
      // Handle different category structures from the API
      if (category['name'] != null) {
        // Handle the original API format
        categoryName = category['name'].toString().split('_')[0];
        categoryId = category['id'] ?? 0;
        productData = category['products'] ?? [];
      } else if (category['title'] != null) {
        // Handle the new API format
        categoryName = category['title'].toString();
        categoryId = int.tryParse(category['id']?.toString() ?? '0') ?? 0;
        productData = category['items'] ?? [];
      }
      
      // Skip categories with 'ava' in the name (as in the original code)
      if (!categoryName.toLowerCase().contains('ava') && productData.isNotEmpty) {
        List<Product> products = productData.map<Product>((product) {
          // Extract image path
          String? imagePath;
          
          // Handle different image formats
          if (product['photo'] != null) {
            var photo = product['photo'];
            if (photo['path'] != null && photo['name'] != null && photo['format'] != null) {
              imagePath = 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}';
            } else if (photo['url'] != null) {
              imagePath = photo['url'];
            }
          } else if (product['image'] != null) {
            // New API might use 'image' instead of 'photo'
            imagePath = product['image'].toString();
          }
          
          // Extract price
          double price = 0.0;
          if (product['priceList'] != null && product['priceList']['price'] != null) {
            price = product['priceList']['price'].toDouble();
          } else if (product['price'] != null) {
            price = double.tryParse(product['price'].toString()) ?? 0.0;
          }
          
          // Extract product ID
          int productId = 0;
          if (product['id'] != null) {
            productId = product['id'] is int ? product['id'] : int.tryParse(product['id'].toString()) ?? 0;
          }
          
          // Handle description - check if it's already a JSON object or a string
          dynamic description = product['description'] ?? product['desc'] ?? '';
          
          // If it's a string that looks like plain text (not JSON), convert it to a JSON object
          if (description is String && !description.trim().startsWith('{')) {
            // Create a simple object with language codes as keys
            description = {
              'en': description,
              'ru': description,
              'uz': description
            };
          }
          
          // Store the original UUID from the API
          String uuid = '';
          if (product['id'] != null) {
            uuid = product['id'].toString();
          }
          
          // Create a JSON map to feed into Product.fromJson constructor
          Map<String, dynamic> productJson = {
            'name': product['name'] ?? product['title'] ?? '',
            'id': productId,
            'uuid': uuid, // Include the original UUID
            'categoryId': categoryId,
            'categoryTitle': categoryName,
            'imagePath': imagePath,
            'price': price,
            'description': description
          };
          
          // Use Product.fromJson constructor to create the product object
          return Product.fromJson(productJson);
        }).toList();

        if (products.isNotEmpty) {
          mergedProducts.addAll(products);
          newCategories.add(Category(id: categoryId, name: categoryName));
        }
      }
    }

    _categories = newCategories;
    _allProducts = mergedProducts;
  }

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

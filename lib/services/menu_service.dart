import 'dart:convert';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/services/api_service.dart';
import 'package:apploook/services/order_mode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  late ApiService _apiService;
  late OrderModeService _orderModeService;
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  bool _isInitialized = false;
  String? _nearestBranchDeliverId;

  static const String _cacheKey = 'cachedCategoryData';
  static const String _cacheTimestampKey = 'lastCacheUpdateTime';
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  bool get isInitialized => _isInitialized;

  MenuService._internal() {
    _apiService = ApiService(
      clientId: '0cd4095f-cfe5-4852-b18b-d4f97832b653', //Production
      // clientId: '5e5e55a2-30f4-4adb-b929-a27428be9776', //Test

      clientSecret: 'bW9iaWxlQXBwOm1vYmlsZUFwcEU1JCQ=', //Production
      // clientSecret: 'bG9vb2tBcHBBZ2dAMTpsb29va0FwcEFnZ0Ax', //Test
    );
    _orderModeService = OrderModeService();
  }

  void setNearestBranchDeliverId(String deliverId) {
    _nearestBranchDeliverId = deliverId;
    // print('MenuService: Set nearest branch deliver ID: $deliverId');
  }

  Future<void> initialize() async {
    // print('MenuService: Initializing...');
    if (_isInitialized) {
      // print('MenuService: Already initialized, returning');
      return;
    }

    await _orderModeService.initialize();
    // print(
    //     'MenuService: Order mode initialized to: ${_orderModeService.currentMode}');

    try {
      // print('MenuService: Checking cache validity');
      bool isCacheValid = await _isCacheValid();
      // print('MenuService: Cache valid: $isCacheValid');

      if (isCacheValid) {
        // print('MenuService: Loading from cache');
        final loaded = await _loadFromCache();
        if (loaded) {
          _isInitialized = true;
          // print(
          //     'MenuService: Initialized from cache, refreshing data in background');

          refreshData().catchError((e) {
            // print('MenuService: Background refresh error: $e');
          });
        } else {
          // print('MenuService: Cache is valid but data is null');
        }
      } else {
        // print('MenuService: Cache is not valid or missing');
      }

      if (!_isInitialized) {
        // print('MenuService: Not initialized from cache, fetching fresh data');
        await refreshData();
      }
    } catch (e, stackTrace) {
      // print('MenuService: Error initializing: $e');
      // print('MenuService: Stack trace: $stackTrace');
      if (!_isInitialized) {
        // print('MenuService: Not initialized, throwing exception');
        throw Exception('Failed to initialize menu data: $e');
      }
    }
  }

  Future<bool> _isCacheValid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // We now use the same cache key for all order modes
    final lastUpdateTime = prefs.getInt(_cacheTimestampKey);
    if (lastUpdateTime == null) return false;

    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - lastUpdateTime) <
        _cacheValidityDuration.inMilliseconds;
  }

  Future<bool> _loadFromCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // We now use the same cache key for all order modes
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData == null) return false;

      final decodedData = json.decode(cachedData);
      _processCategoryData(decodedData);
      return true;
    } catch (e) {
      // print('MenuService: Error loading from cache: $e');
      return false;
    }
  }

  // Process category data from API format
  void _processCategoryData(dynamic data) {
    try {
      if (data is Map<String, dynamic> && data.containsKey('categories')) {
        // Process in standard API format
        List<dynamic> categories = data['categories'] ?? [];
        List<dynamic> items = data['items'] ?? [];

        _processNewApiData(categories, items, data);
      } else if (data is Map<String, dynamic> && data.containsKey('items')) {
        // Just items array, still process with new API logic
        List<dynamic> items = data['items'] ?? [];
        _processNewApiData([], items, data);
      } else {
        // print('MenuService: Unknown data format, creating default data');
        _createDefaultData();
      }
    } catch (e) {
      // print('MenuService: Error processing category data: $e');
      _createDefaultData();
    }
  }

  Future<void> refreshData() async {
    // print('MenuService: Starting refreshData');
    try {
      // Set the restaurant ID if we have a nearest branch deliver ID
      if (_nearestBranchDeliverId != null &&
          _nearestBranchDeliverId!.isNotEmpty) {
        // print(
        // 'MenuService: Using nearest branch deliver ID: $_nearestBranchDeliverId');
        ApiService.setRestaurantId(_nearestBranchDeliverId!);
      }

      // Always fetch from the new API regardless of order mode
      // print('MenuService: Fetching menu items from API service');
      final menuItems = await _apiService.getMenuItems();
      // print(
      //     'MenuService: Received menu items from API, count: ${menuItems.length}');

      // Extract the data from the response
      final apiData = menuItems.isNotEmpty && menuItems[0] is Map
          ? menuItems[0]
          : {'categories': [], 'items': []};
      // print('MenuService: API data structure: ${apiData.keys.toList()}');

      // Based on the logs, we can see the API returns both categories and items
      List<dynamic> categories = apiData['categories'] ?? [];
      List<dynamic> directItems = apiData['items'] ?? [];

      print(
          'MenuService: API returned ${categories.length} categories and ${directItems.length} direct items');

      // Process data from the API
      await _processNewApiData(categories, directItems, apiData);
    } catch (e, stackTrace) {
      print('MenuService: Error refreshing data: $e');
      print('MenuService: Stack trace: $stackTrace');
      // Create default data if there's an error
      _createDefaultData();
    }
  }

  Future<void> _processNewApiData(List<dynamic> categories,
      List<dynamic> directItems, Map<String, dynamic> apiData) async {
    try {
      _categories = [];
      _allProducts = [];

      // Create a list to store categories with their sort order
      List<Map<String, dynamic>> categoriesWithSortOrder = [];

      // Create a map to store category ID strings to int IDs for reference
      Map<String, int> categoryIdMap = {};

      // Process categories first
      // print('MenuService: Processing categories');
      for (var category in categories) {
        try {
          // Extract the original category ID (which is now a string UUID)
          String originalCategoryId =
              category['id'] != null ? category['id'].toString() : '';

          // Generate a unique integer ID for internal use
          int categoryId =
              _getUniqueCategoryId(categories.indexOf(category) + 1);
          // print(
          //     'MenuService: Original category ID: $originalCategoryId, assigned unique ID: $categoryId');

          // Store the mapping from string ID to int ID
          categoryIdMap[originalCategoryId] = categoryId;

          final categoryName = category['name'] ?? 'Unknown Category';
          // Capture sortOrder for category sorting
          final sortOrder = category['sortOrder'] ?? 0;

          // print(
          //     'MenuService: Processing category: $categoryName (ID: $categoryId), sortOrder: $sortOrder');

          // Store category with its sort order for later sorting
          categoriesWithSortOrder.add(
              {'id': categoryId, 'name': categoryName, 'sortOrder': sortOrder});
        } catch (e) {
          // print('MenuService: Error processing category: $e');
          // print('MenuService: Category data: $category');
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

      // Custom sort for delivery/takeaway mode
      if (_orderModeService.currentMode == OrderMode.deliveryTakeaway) {
        // print(
        //     'MenuService: Applying custom category order for delivery/takeaway mode');

        // Define custom order priority map
        final Map<String, int> customOrderPriority = {
          'КОМБО': 1,
          'АППЕТАЙЗЕРЫ': 2,
          'КУРИЦА': 3,
          'СПИННЕРЫ': 4,
          'БУРГЕРЫ': 5,
          'ПИЦЦА': 6,
          'САЛАТЫ': 7,
          'НАПИТКИ': 8,
          'ГОРЯЧИЕ НАПИТКИ': 9,
          'ДЕСЕРТЫ': 10,
          'МОРОЖЕНОЕ И МИЛКШЕЙКИ': 11,
          // Any other categories will be sorted after these by their original sortOrder
        };

        categoriesWithSortOrder.sort((a, b) {
          String nameA = a['name'].toString().trim();
          String nameB = b['name'].toString().trim();

          // Get priority from map or use a high number as default
          int priorityA = customOrderPriority[nameA] ?? 1000;
          int priorityB = customOrderPriority[nameB] ?? 1000;

          // If both are in the priority map, sort by priority
          if (priorityA < 1000 && priorityB < 1000) {
            return priorityA.compareTo(priorityB);
          }
          // If only one is in the priority map, it comes first
          else if (priorityA < 1000) {
            return -1;
          } else if (priorityB < 1000) {
            return 1;
          }
          // If neither is in the priority map, sort by original sortOrder
          else {
            return (a['sortOrder'] as int).compareTo(b['sortOrder'] as int);
          }
        });

        // Debug log the sorted categories
        // print('MenuService: Custom sorted categories:');
        for (var category in categoriesWithSortOrder) {
          print(
              '  - ${category['name']} (sortOrder: ${category['sortOrder']})');
        }
      }

      // Add sorted categories to _categories list
      for (var categoryData in categoriesWithSortOrder) {
        _categories
            .add(Category(id: categoryData['id'], name: categoryData['name']));
      }

      // Apply custom sorting to products within each category
      _applyCategoryProductSorting();

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
      // print(
      //     'MenuService: Processing item: ${item['name'] ?? item['title'] ?? 'Unknown'}');

      // Extract basic product information
      int originalId = item['id'] is int
          ? item['id']
          : int.tryParse(item['id'].toString()) ?? 0;
      // Generate a unique ID if the original is 0 or duplicate
      final id = _getUniqueProductId(originalId);
      // print(
      //     'MenuService: Item original ID: $originalId, assigned unique ID: $id');

      final name = item['name'] ?? item['title'] ?? 'Unknown';
      // print('MenuService: Item name: $name');

      // Handle different price formats
      double price = 0.0;
      if (item['price'] != null) {
        // print('MenuService: Item has price field: ${item['price']}');
        price = item['price'] is double
            ? item['price']
            : double.tryParse(item['price'].toString()) ?? 0.0;
      } else if (item['priceList'] != null &&
          item['priceList']['price'] != null) {
        // print(
        //     'MenuService: Item has priceList field: ${item['priceList']['price']}');
        price = item['priceList']['price'] is double
            ? item['priceList']['price']
            : double.tryParse(item['priceList']['price'].toString()) ?? 0.0;
      } else {
        // print('MenuService: Item has no price field, using default 0.0');
      }
      // print('MenuService: Final price: $price');

      // Handle different image formats
      String? imagePath;

      // Check for images array first (new format)
      if (item['images'] != null &&
          item['images'] is List &&
          (item['images'] as List).isNotEmpty) {
        // print(
        //     'MenuService: Item has images array with ${(item['images'] as List).length} images');
        var firstImage = (item['images'] as List).first;
        if (firstImage is Map && firstImage['url'] != null) {
          imagePath = firstImage['url'].toString();
          // print(
          //     'MenuService: Using first image URL from images array: $imagePath');
        }
      }
      // Fall back to image field
      else if (item['image'] != null) {
        // print('MenuService: Item has image field: ${item['image']}');
        imagePath = item['image'].toString();
      }
      // Fall back to photo field
      else if (item['photo'] != null) {
        // print('MenuService: Item has photo field');
        var photo = item['photo'];
        if (photo['url'] != null) {
          imagePath = photo['url'].toString();
          // print('MenuService: Using photo URL: $imagePath');
        } else if (photo['path'] != null &&
            photo['name'] != null &&
            photo['format'] != null) {
          imagePath =
              'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}';
          // print('MenuService: Constructed image path: $imagePath');
        } else {
          // print('MenuService: Photo field missing required attributes');
        }
      } else {
        // print('MenuService: Item has no images, image, or photo field');
      }

      // Get description
      final description = item['description'] ?? '';
      // print(
      //     'MenuService: Item description length: ${description.toString().length}');

      // Store the original UUID from the API
      String uuid = '';
      if (item['id'] != null) {
        uuid = item['id'].toString();
      }
      // print('MenuService: Original item UUID: $uuid');

      // Parse modifier groups if present
      List<ModifierGroup> modifierGroups = [];
      if (item['modifierGroups'] != null) {
        try {
          modifierGroups = (item['modifierGroups'] as List)
              .map((group) => ModifierGroup.fromJson(group))
              .toList();
          // print(
          //     'MenuService: Found ${modifierGroups.length} modifier groups for item: $name');
        } catch (e) {
          // print('MenuService: Error parsing modifier groups for $name: $e');
        }
      }

      // Handle images array
      List<Map<String, dynamic>>? images;
      if (item['images'] != null) {
        try {
          images = List<Map<String, dynamic>>.from(item['images']);
          // print('MenuService: Found ${images.length} images for item: $name');
        } catch (e) {
          // print('MenuService: Error parsing images for $name: $e');
        }
      }

      // Create the product
      final product = Product(
        id: id,
        uuid: uuid,
        name: name,
        categoryId: categoryId,
        categoryTitle: categoryName,
        price: price,
        imagePath: imagePath,
        description: description,
        modifierGroups: modifierGroups,
        measure: item['measure']?.toString(),
        measureUnit: item['measureUnit']?.toString(),
        sortOrder: item['sortOrder'],
        serviceCodesUz: item['serviceCodesUz'],
        images: images,
      );

      // print(
      //     'MenuService: Created product: ${product.name} (ID: ${product.id})');
      _allProducts.add(product);
      // print(
      //     'MenuService: Added product to allProducts list, new count: ${_allProducts.length}');
    } catch (e, stackTrace) {
      // print('MenuService: Error processing item: $e');
      // print('MenuService: Item data: $item');
      // print('MenuService: Stack trace: $stackTrace');
    }
  }

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
    // print(
    //     'MenuService: Created default data with ${_categories.length} categories and ${_allProducts.length} products');
  }

  // Apply custom sorting to products within each category
  void _applyCategoryProductSorting() {
    // print('MenuService: Applying custom product sorting within categories');

    // Define custom product sorting rules for specific categories
    final Map<String, Map<String, int>> categoryProductSorting = {
      'КОМБО': {
        // Example: Define specific product order for COMBO category
        // Add your specific product names and their desired order
      },
      'АППЕТАЙЗЕРЫ': {
        // Example: Define specific product order for CHICKEN category
        // 'Куриные крылышки': 1,
        // 'Куриные ножки': 2,
        // 'Куриная грудка': 3,
      },
      ' КУРИЦА': {
        '12 куриных сетов не острый':1,
        '12 куриных сетов острый':2,
        '12 куриных сетов микс':3,
        'Диннер мил острый':4,
        'Диннер меал не острый':5,
        'Диннер меал (2 не острый, 1 острый)':6,
        'Диннер меал  (2 не острый, 1 острый)':7,
        'Снек меал острый':8,
        'Снек меал не острый':9,
        'Снек меал':10,
        'Микс меал':11,
        'Микс меал острый':12,
        'острый чикен':13,
        'Чикен не острый':14
      },
      'СПИННЕРЫ': {
        'Дует Мастер':1,
        'Смайл бокс':2,
        'Хрустящий ролл':3,
        'Хрустящий куриный ролл':4,
        'Хрустящий ролл микс':5,
        'Спиннер Тако':6,
        'Спиннер Super Charged':7,
        'Спиннер сальса':8,
        'спиннер снек':9,
        'спиннер без соуса':10
        },
      'БУРГЕРЫ':{
        'Биггер':1,
        'Лонгер':2,
        'Джуниор бургер':3,
        'Чики бургер':4,
        'Твинс бургер курийный':5,
        'Чиз бургер':6,
        'Бееф Лонгер':7,
        'Чили Лонгер':8,
        'Твинс бургер говяжий':9,
        'Пакет':10,
      },
      'ПИЦЦА':{

      },
      'САЛАТЫ': {

      },
      'НАПИТКИ':{
        'Coca Cola':1,
        'Coca-Cola  разлив':2,
        'Фанта':3,
        'Fanta разлив':4,
        'Sprite':5,
        'Sprite разлив':6,
        'Минеральная вода без газа':7,
        'Минеральная вода с газом':8,
        'Апельсиновый сок Tip-Top':9,
        'Абрикосовый сок Tip-Top':10,
        'Ананасовый сок Tip-Top':11,
        'Dinay':12,
        'Айс ти':13,
      },
      'ГОРЯЧИЕ НАПИТКИ':{

      },
      'ДЕСЕРТЫ':{

      },
      'МОРОЖЕНОЕ И МИЛКШЕЙКИ':{
        'Loook мороженое с бинго':1,
        'Loook мороженое с вафли':2,
        'Клубничное мороженое':3,
        'Шоколадное мороженое':4,
        'мороженое (500гр)':5,
        'Банановый милкшейк':6,
        'Молочный коктейль  шоколадный':7,
        'Молочный коктейль клубничный':8
      },
      'ДЕТСКОЕ БЛЮДО':{

      },
      'СОУСЫ':{

      },
      'GENERAL':{

      },
    };

    // Sort products within each category
    for (var category in _categories) {
      // Get all products for this category
      List<Product> categoryProducts = _allProducts
          .where((product) => product.categoryId == category.id)
          .toList();

      if (categoryProducts.isEmpty) continue;

      // Log all products in this category for easy reference
      // print('MenuService: === ${category.name} CATEGORY (${categoryProducts.length} products) ===');
      for (int i = 0; i < categoryProducts.length; i++) {
        var product = categoryProducts[i];
        print('  ${i + 1}. "${product.name}" (ID: ${product.id}, sortOrder: ${product.sortOrder ?? 'null'}, price: ${product.price})');
      }
      // print('MenuService: === End of ${category.name} products ===\n');

      // Check if we have custom sorting rules for this category
      Map<String, int>? customOrder = categoryProductSorting[category.name];

      if (customOrder != null && customOrder.isNotEmpty) {
        // print('MenuService: Found custom sorting rules for ${category.name} category');
        // print('MenuService: Custom order map has ${customOrder.length} entries');
        
        // Debug: Check which products have custom priorities
        for (var product in categoryProducts) {
          int priority = customOrder[product.name] ?? 9999;
          // print('  Product "${product.name}" -> priority: $priority ${priority < 9999 ? "(CUSTOM)" : "(DEFAULT)"}');
        }
        
        // Apply custom sorting based on product names
        categoryProducts.sort((a, b) {
          int priorityA = customOrder[a.name] ?? 9999;
          int priorityB = customOrder[b.name] ?? 9999;

          // If both products have custom priority, sort by priority
          if (priorityA < 9999 && priorityB < 9999) {
            return priorityA.compareTo(priorityB);
          }
          // If only one has custom priority, it comes first
          else if (priorityA < 9999) {
            return -1;
          } else if (priorityB < 9999) {
            return 1;
          }
          // If neither has custom priority, fall back to sortOrder or name
          else {
            // First try to sort by sortOrder if available
            if (a.sortOrder != null && b.sortOrder != null) {
              return a.sortOrder!.compareTo(b.sortOrder!);
            }
            // If sortOrder is not available, sort alphabetically
            return a.name.compareTo(b.name);
          }
        });

        // print('MenuService: Applied custom sorting to ${category.name} category (${categoryProducts.length} products)');
        // print('MenuService: Products after custom sorting:');
        for (int i = 0; i < categoryProducts.length; i++) {
          print('  ${i + 1}. "${categoryProducts[i].name}"');
        }
      } else {
        // Apply default sorting (by sortOrder, then by name)
        categoryProducts.sort((a, b) {
          // First try to sort by sortOrder if available
          if (a.sortOrder != null && b.sortOrder != null) {
            int sortComparison = a.sortOrder!.compareTo(b.sortOrder!);
            if (sortComparison != 0) return sortComparison;
          }
          // If sortOrder is the same or not available, sort alphabetically
          return a.name.compareTo(b.name);
        });

        // print('MenuService: Applied default sorting to ${category.name} category (${categoryProducts.length} products)');
      }

      // Update the products in _allProducts with the sorted order
      // Remove old products for this category
      _allProducts.removeWhere((product) => product.categoryId == category.id);
      // Add back the sorted products
      _allProducts.addAll(categoryProducts);
    }

    print('MenuService: Product sorting completed for all categories');
  }

  // Update the cache with the latest data
  Future<void> _updateCache(dynamic data, {bool isNewApi = true}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(data);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // We now use the same cache keys for all order modes
      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_cacheTimestampKey, currentTime);

      // print('MenuService: Updated cache');
    } catch (e) {
      // print('MenuService: Error updating cache: $e');
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

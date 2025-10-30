import 'dart:convert';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/models/product_group.dart';
import 'package:apploook/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;

  late ApiService _apiService;
  List<Category> _categories = [];
  List<Product> _allProducts = [];
  List<ProductGroup> _productGroups = [];
  bool _isInitialized = false;
  String? _nearestBranchDeliverId;

  static const String _cacheKey = 'cachedCategoryData';
  static const String _cacheTimestampKey = 'lastCacheUpdateTime';
  static const Duration _cacheValidityDuration = Duration(hours: 6);

  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  List<ProductGroup> get productGroups => _productGroups;
  bool get isInitialized => _isInitialized;

  MenuService._internal() {
    _apiService = ApiService(
      clientId: '0cd4095f-cfe5-4852-b18b-d4f97832b653', //Production
      // clientId: '5e5e55a2-30f4-4adb-b929-a27428be9776', //Test

      clientSecret: 'bW9iaWxlQXBwOm1vYmlsZUFwcEU1JCQ=', //Production
      // clientSecret: 'bG9vb2tBcHBBZ2dAMTpsb29va0FwcEFnZ0Ax', //Test
    );
  }

  final Map<String, List<String>> productVariationGroups = {
    // TODO: Add your product variation groups here
    'Hot Wings': ['5208c67b-2ac6-4f43-88ab-65a83f7ebb81', '0c7b899f-d028-4570-8cb4-269672e0accb', '06cb14c5-0562-40b1-a626-9c7cca693277', '9ffac736-6889-4d2b-84ea-2cc42792eee5'],
    'Strips': ['728d38c6-a045-46c2-9f43-05b565752320', 'fe87c6c4-3380-42a0-8037-2fa9fc7c7379', 'ac15b71b-5529-44e9-9dc2-100ce27a3b40', 'b65855ac-b4f1-4323-a706-872a72eb1732'],
    'Cheese Nuggets': ['9300d02a-3058-4b9f-a7c5-7adef6f7d591', '9f1c53f0-f61a-42b1-a27a-244369cc19e4'],
    'Dinner Meal': ['75c0da75-ecf7-431e-855b-87c97cf392f4', '1b61189a-6c50-47cc-baf2-3e7ab608f288', '974ae6b2-be27-4f7c-be95-76203edf8c29', '403cda4a-5d4b-418d-972f-d95d84d63cc6', '9282dcff-0e73-4ca3-91ad-2b17b2e64ef3'],
    'Sneak Meal': ['aeefbdad-b759-4ef0-ba88-62589fb68127', 'f6ff8302-1af3-4308-978f-d15b0579465b', '2a3bef8f-5833-46b9-b233-fcb717813568'],
    'Mix Meal':['fee1bf9f-27c6-40d6-81e0-02e63f9d4730', '5e0873ff-a9fa-4504-beca-3eda42ed886e'],
    'Chicken Set': ['cfb76795-f5fb-4ec6-9a90-6a165ca70563', '0f03c202-033c-4f70-9033-93808d8ac57a', 'ea379f61-4095-4d92-bfa3-f5eff88aed54'],
    'Kids Set':['c423c6e2-f6d8-464c-983c-895136a1f216', 'd67575af-326f-4a6d-a133-e68c73b8a557', '7fad3b0b-92b2-4836-af7c-d9304aac812d', '22d35b88-2346-494c-b815-b75c074a981f'],
    'Crispy Roll':['8d23a259-13c3-4f0e-8c70-4a784a2d0945', '1891f90b-9df6-4523-b3f5-ff755ab71df1', 'b9317bbc-77ed-499e-8e73-760161eebf90'],
    'Fully Combo':['62d6b1c3-f76b-4b95-99aa-fc42b69fdb28', '12d16ac8-f62e-4d41-b0a1-8b70b1e9c637'],
    'Spinner':['062b72b9-5b5c-4d51-9182-a00e6a91f841', '66096ce0-d34f-4ab1-a5c7-4f2f4736a4ca', 'daed46c5-0599-4206-a342-88d40f512247', '7c9ba5db-a76e-41e6-b9c7-0ded9c1a88db', 'b08ac987-14f7-413e-ab3a-d0d26b2d62e1','ba7f3fc3-00bc-4c95-8fb7-7c5c39a557db'],
    'Donuts Choco':['aff2af4d-9963-48d3-9cf3-a1c38b8142c5', 'ef69e862-08cf-4f87-b3c7-d401cda63c12'],
    'Donuts Strawberry':['9b8dd673-72cb-488d-9d9a-6fa1839ae272','e58a54fc-cf44-45a7-afc7-9ff5d97b0576'],
    'Bucket 0.5kg':['ffee92e6-ae79-4d33-8996-5903c060edc6','eb297d99-8276-4d16-bce7-213213a4c726','eb028d52-cf82-456e-9727-65602becaa51'],
    'Bucket 1kg':['4435699c-d08e-45e4-91b8-7998469c5b92','d4d7844e-6d2b-4c63-a8f0-5bc7a24b670f','3e09dabf-c3a1-4b9e-90b1-fe892a29ee75'],
    '24+24':['e2609966-acc6-4b93-971d-b7dd17cd88eb', '11434b02-c4d7-4116-a479-8a924e04c353', '63ad6a59-bd48-4f40-aceb-8706d5f4fb10', '54e87b06-d27f-46a4-af4e-d43ce37648db','5f575cc6-b5b1-465e-a1dd-631ef3abc3af','f90ad28f-9948-49e3-984f-cede71ee32f5',],
    '32+32':['aa8e310f-2a2a-4d34-8622-a83d5f654dca', '4e5e85a6-86f7-4e77-918f-2007b65b4228', '38032505-91de-4f02-912e-a551dbd8690b'],
    'Sok TipTop':['f3ca491b-aae6-41db-ae91-76a6b323797e', '7f4f6fd3-1e1c-45a9-9a9c-f8dca93d3057','e33099c5-218e-4fdf-9e67-c07c1c28ba7e'],
    'Sauce':['96a8d98f-fabd-4ecd-89cb-bd71a60716eb', 'f4e6fe5f-5b2b-431f-bc36-053655dac03d', '93ccb42f-a254-4e15-b3d6-c5292c73bc41', '73fa3cb2-c8c7-4f0e-a165-e412c259e7c0', 'bf057a06-7cc0-4f54-a6b1-d3335f0663c3', '08cdcb00-49c9-4146-a623-1e9a4319e32e', 'a4e74610-4fff-48df-b300-5fbb8f4a50aa'],
  };

  void setNearestBranchDeliverId(String deliverId) {
    _nearestBranchDeliverId = deliverId;
    print('\n======== NEAREST BRANCH INFORMATION ========');
    print('MenuService: Set nearest branch deliver ID: $deliverId');
    print('======== END NEAREST BRANCH INFORMATION ========\n');
  }

  Future<void> initialize() async {
    // print('MenuService: Initializing...');
    if (_isInitialized) {
      // print('MenuService: Already initialized, returning');
      return;
    }


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
      print('MenuService: Stack trace: $stackTrace');
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
    print('\n======== MENU SERVICE REFRESH DATA ========');
    print('MenuService: Starting refreshData');
    try {
      // Set the restaurant ID if we have a nearest branch deliver ID
      if (_nearestBranchDeliverId != null &&
          _nearestBranchDeliverId!.isNotEmpty) {
        print('MenuService: Using nearest branch deliver ID: $_nearestBranchDeliverId');
        ApiService.setRestaurantId(_nearestBranchDeliverId!);
      } else {
        print('MenuService: No nearest branch deliver ID set, using default restaurant ID');
      }

      // Always fetch from the new API regardless of order mode
      print('MenuService: Fetching menu items from API service');
      final menuItems = await _apiService.getMenuItems();
      print('MenuService: Received menu items from API, count: ${menuItems.length}');

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
      // Define custom order priority map
      final Map<String, int> customOrderPriority = {
        'Комбо М':1,
        'КОМБО': 2,
        'АППЕТАЙЗЕРЫ (М)': 3,
        'АППЕТАЙЗЕРЫ': 3,
        'КУРИЦА': 4,
        'СПИННЕРЫ': 5,
        'БУРГЕРЫ': 6,
        'ПИЦЦА': 7,
        'САЛАТЫ': 8,
        'НАПИТКИ': 9,
        'ГОРЯЧИЕ НАПИТКИ': 10,
        'ДЕСЕРТЫ': 11,
        'ВАФЛИ':11,
        'Мороженое и милишайки': 12,
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

      for (var category in categoriesWithSortOrder) {
        print(
            '  - ${category['name']} (sortOrder: ${category['sortOrder']})');
      }

      for (var categoryData in categoriesWithSortOrder) {
        _categories
            .add(Category(id: categoryData['id'], name: categoryData['name']));
      }

      _applyCategoryProductSorting();

      _groupProductVariations();

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
      // print('MenuService: Updating cache');
      await _updateCache(apiData, isNewApi: true);
      // print('MenuService: Cache updated successfully');

      _isInitialized = true;
    } catch (e, stackTrace) {
      // print('MenuService: Error processing new API data: $e');
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
      print('MenuService: Stack trace: $stackTrace');
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
      'Комбо М': {
        'APPMAX':1,
        'Bigger 2=3':2,
      },
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
        // for (var product in categoryProducts) {
        //   int priority = customOrder[product.name] ?? 9999;
          // print('  Product "${product.name}" -> priority: $priority ${priority < 9999 ? "(CUSTOM)" : "(DEFAULT)"}');
        // }
        
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

  /// Group products into ProductGroups based on the configuration map
  void _groupProductVariations() {
    print('MenuService: Starting product variation grouping');
    _productGroups.clear();

    // Create a set to track which products have been grouped
    Set<String> groupedProductUuids = {};

    // Process each group in the configuration
    for (var entry in productVariationGroups.entries) {
      String groupName = entry.key;
      List<String> uuidList = entry.value;

      // Find all products that match the UUIDs in this group
      List<Product> matchingProducts = [];
      for (String uuid in uuidList) {
        var product = _allProducts.firstWhere(
          (p) => p.uuid == uuid,
          orElse: () => Product(
            id: 0,
            uuid: '',
            name: '',
            categoryId: 0,
            categoryTitle: '',
            price: 0,
            description: {},
          ),
        );

        if (product.id != 0) {
          matchingProducts.add(product);
          groupedProductUuids.add(uuid);
        }
      }

      // Only create a group if we found at least 2 matching products
      if (matchingProducts.length >= 2) {
        // Sort variations by price (ascending)
        matchingProducts.sort((a, b) => a.price.compareTo(b.price));

        // Use the first (cheapest) product as the primary variation
        ProductGroup group = ProductGroup(
          groupName: groupName,
          variations: matchingProducts,
          primaryVariation: matchingProducts.first,
        );

        _productGroups.add(group);
        print('MenuService: Created group "$groupName" with ${matchingProducts.length} variations');
      } else if (matchingProducts.length == 1) {
        print('MenuService: Warning - Group "$groupName" only has 1 product, skipping grouping');
        // Remove from grouped set so it appears as a regular product
        groupedProductUuids.remove(matchingProducts.first.uuid);
      } else {
        print('MenuService: Warning - Group "$groupName" has no matching products');
      }
    }

    print('MenuService: Created ${_productGroups.length} product groups');
    print('MenuService: Grouped ${groupedProductUuids.length} products');
  }

  /// Check if a product is part of a variation group
  bool isProductGrouped(String uuid) {
    for (var group in _productGroups) {
      if (group.variations.any((p) => p.uuid == uuid)) {
        return true;
      }
    }
    return false;
  }

  /// Get the product group for a given product UUID
  ProductGroup? getProductGroup(String uuid) {
    for (var group in _productGroups) {
      if (group.variations.any((p) => p.uuid == uuid)) {
        return group;
      }
    }
    return null;
  }

  /// Get all ungrouped products for a category
  List<Product> getUngroupedProductsForCategory(int categoryId) {
    return _allProducts.where((product) {
      return product.categoryId == categoryId && !isProductGrouped(product.uuid);
    }).toList();
  }

  /// Get all product groups for a category
  List<ProductGroup> getProductGroupsForCategory(int categoryId) {
    return _productGroups.where((group) {
      return group.categoryId == categoryId;
    }).toList();
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

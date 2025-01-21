import 'dart:convert';

import 'package:apploook/pages/homenew.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class MenuService {
  static final MenuService _instance = MenuService._internal();
  factory MenuService() => _instance;
  MenuService._internal();

  List<Category> _categories = [];
  List<Product> _allProducts = [];
  bool _isInitialized = false;

  // Getters
  List<Category> get categories => _categories;
  List<Product> get allProducts => _allProducts;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // First try to load from cache
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        _processCategoryData(cachedData);
        _isInitialized = true;
      }

      // Fetch fresh data from server
      await refreshData();
    } catch (e) {
      print('Error initializing MenuService: $e');
      // If both cache and network fail, throw error
      if (!_isInitialized) {
        throw Exception('Failed to initialize menu data');
      }
    }
  }

  Future<List<dynamic>?> _loadFromCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? cachedData = prefs.getString('cachedCategoryData');
      if (cachedData != null) {
        return json.decode(cachedData);
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  Future<void> refreshData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1')
      );

      if (response.statusCode == 200) {
        List<dynamic> categoryData = json.decode(response.body);
        
        // Update memory
        _processCategoryData(categoryData);
        _isInitialized = true;

        // Update cache
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('cachedCategoryData', response.body);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error refreshing data: $e');
      rethrow;
    }
  }

  void _processCategoryData(List<dynamic> categoryData) {
    List<Category> newCategories = [];
    List<Product> mergedProducts = [];

    for (var category in categoryData) {
      String categoryName = category['name'].split('_')[0];
      if (!categoryName.toLowerCase().contains('ava')) {
        List<dynamic> productData = category['products'];
        int categoryId = category['id'];
        
        List<Product> products = productData.map((product) {
          var photo = product['photo'];
          String? imagePath = photo != null
              ? 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}'
              : null;
          
          return Product(
            name: product['name'],
            id: product['id'],
            categoryId: categoryId,
            categoryTitle: categoryName,
            imagePath: imagePath,
            price: product['priceList']['price'].toDouble(),
            description: product['description']
          );
        }).toList();

        mergedProducts.addAll(products);
        newCategories.add(Category(id: categoryId, name: categoryName));
      }
    }

    _categories = newCategories;
    _allProducts = mergedProducts;
  }
}
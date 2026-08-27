import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/app_lat_long.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  List<Product> _products = [];
  bool _hasData = false;

  List<CartItem> get cartItems => _cartItems;
  double latitude = 0.0;
  double longitude = 0.0;

  /// Add a plain (unconfigured) product. Merges with an existing line of the
  /// same product that has no modifiers.
  void addToCart(Product product, int quantity) {
    addToCartWithModifiers(CartItem(product: product, quantity: quantity));
  }

  /// Add a configured product. Lines whose [CartItem.configurationKey] matches
  /// (same product, same modifier IDs, same modifier quantities) are merged by
  /// bumping the quantity; any other configuration becomes its own line.
  void addToCartWithModifiers(CartItem cartItem) {
    if (cartItem.quantity < 1) return;

    final existing = findByConfiguration(cartItem);
    if (existing != null) {
      existing.quantity += cartItem.quantity;
    } else {
      _cartItems.add(cartItem);
    }

    notifyListeners();
  }

  /// The cart line with exactly the same product configuration, if any.
  CartItem? findByConfiguration(CartItem cartItem) {
    final key = cartItem.configurationKey;
    for (final item in _cartItems) {
      if (item.configurationKey == key) return item;
    }
    return null;
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    removeMandatoryPackageIfCartEmpty();
    notifyListeners();
  }

  void setProducts(List<Product> products) {
    _products = products;
    _hasData = true;
    notifyListeners();
  }

  List<Product> getProducts() {
    return List.from(_products);
  }

  bool hasData() {
    return _hasData;
  }

  void addLatLong(lat, long) {
    latitude = lat;
    longitude = long;
  }

  showLat() {
    return latitude;
  }

  showLong() {
    return longitude;
  }

  void updateQuantity(CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(cartItem);
    } else {
      cartItem.quantity = newQuantity;
      notifyListeners();
    }
    removeMandatoryPackageIfCartEmpty();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void logItems() {
    print(_cartItems);
  }

  int showQuantity() {
    int totalQuantity = 0;
    for (var item in _cartItems) {
      totalQuantity += item.quantity;
    }
    return totalQuantity;
  }

  double get totalAmount {
    return _cartItems.fold(
        0, (sum, item) => sum + (item.quantity * item.product.price));
  }

  getTotalPrice() {
    double totalPrice = 0;
    for (var cartItem in _cartItems) {
      totalPrice += cartItem.totalPrice; // Use totalPrice which includes modifiers
    }
    return totalPrice;
  }

  // Check if the mandatory package product exists in cart
  bool hasMandatoryPackage() {
    return _cartItems.any((item) => item.product.name == 'Пакет');
  }

  // Add mandatory package product if cart has items and package is not already added
  void ensureMandatoryPackage(List<Product> allProducts) {
    // Only add package if cart has items (excluding the package itself)
    final nonPackageItems = _cartItems.where((item) => item.product.name != 'Пакет').toList();
    
    if (nonPackageItems.isEmpty) {
      // If cart only has package or is empty, remove the package
      _cartItems.removeWhere((item) => item.product.name == 'Пакет');
      notifyListeners();
      return;
    }

    // Check if package already exists
    if (hasMandatoryPackage()) {
      return; // Package already in cart
    }

    // Find the package product from all products
    final packageProduct = allProducts.firstWhere(
      (product) => product.name == 'Пакет',
      orElse: () => Product(
        name: '',
        id: 0,
        uuid: '',
        categoryId: 0,
        categoryTitle: '',
        price: 0,
        description: {},
      ),
    );

    // Add package if found
    if (packageProduct.id != 0) {
      _cartItems.add(CartItem(product: packageProduct, quantity: 1));
      notifyListeners();
    }
  }

  // Remove mandatory package when cart becomes empty
  void removeMandatoryPackageIfCartEmpty() {
    final nonPackageItems = _cartItems.where((item) => item.product.name != 'Пакет').toList();
    
    if (nonPackageItems.isEmpty) {
      _cartItems.removeWhere((item) => item.product.name == 'Пакет');
      notifyListeners();
    }
  }
}

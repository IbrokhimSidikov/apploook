import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/modifier_models.dart';
import 'package:apploook/models/app_lat_long.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _cartItems = [];
  List<Product> _products = [];
  bool _hasData = false;

  List<CartItem> get cartItems => _cartItems;
  double latitude = 0.0;
  double longitude = 0.0;

  void addToCart(Product product, int quantity) {
    // Check if the product is already in the cart
    var existingItem = _cartItems.firstWhere(
      (item) => item.product.id == product.id && item.selectedModifiers.isEmpty,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    // If the product is already in the cart, update its quantity
    if (existingItem.quantity > 0) {
      existingItem.quantity += quantity;
    } else {
      // Otherwise, add a new item to the cart
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }

    notifyListeners();
  }

  void addToCartWithModifiers(CartItem cartItem) {
    // For products with modifiers, we need to check if the exact same combination exists
    var existingItem = _cartItems.firstWhere(
      (item) => item.product.id == cartItem.product.id && 
                _areModifiersSame(item.selectedModifiers, cartItem.selectedModifiers),
      orElse: () => CartItem(product: cartItem.product, quantity: 0),
    );

    // If the exact same product with same modifiers exists, update quantity
    if (existingItem.quantity > 0) {
      existingItem.quantity += cartItem.quantity;
    } else {
      // Otherwise, add as a new item
      _cartItems.add(cartItem);
    }

    notifyListeners();
  }

  bool _areModifiersSame(List<SelectedModifier> modifiers1, List<SelectedModifier> modifiers2) {
    if (modifiers1.length != modifiers2.length) return false;
    
    // Sort both lists by modifier ID for comparison
    var sorted1 = List<SelectedModifier>.from(modifiers1);
    var sorted2 = List<SelectedModifier>.from(modifiers2);
    
    sorted1.sort((a, b) => a.modifier.id.compareTo(b.modifier.id));
    sorted2.sort((a, b) => a.modifier.id.compareTo(b.modifier.id));
    
    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i].modifier.id != sorted2[i].modifier.id ||
          sorted1[i].quantity != sorted2[i].quantity) {
        return false;
      }
    }
    
    return true;
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
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
}

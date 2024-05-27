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

  void addToCart(Product product, int quantity) {
    // Check if the product is already in the cart
    var existingItem = _cartItems.firstWhere(
      (item) => item.product.id == product.id,
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

  getTotalPrice() {
      double totalPrice = 0;
      for (var cartItem in _cartItems) {
        totalPrice += cartItem.quantity * cartItem.product.price;
      }
      return totalPrice;
    }
  
}

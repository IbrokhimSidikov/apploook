import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cart extends StatefulWidget {
  const Cart({Key? key}) : super(key: key);

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  List<CategoryModel> categories = [];

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  @override
  void initState() {
    super.initState();
    _getCategories();
    // Add mandatory package after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureMandatoryPackage();
    });
  }

  void _ensureMandatoryPackage() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Get all products from MenuService
    try {
      final menuService = MenuService();
      await menuService.initialize();
      final allProducts = menuService.allProducts;

      // Ensure mandatory package is added if cart has items
      cartProvider.ensureMandatoryPackage(allProducts);
    } catch (e) {
      print('Error ensuring mandatory package: $e');
    }
  }

  Future<bool> _isUserSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    final firstName = prefs.getString('firstName');
    return phoneNumber != null &&
        phoneNumber.isNotEmpty &&
        firstName != null &&
        firstName.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();

    var cartProvider = Provider.of<CartProvider>(context);

    int getTotalQuantity(CartProvider cartProvider) {
      int totalQuantity = 0;
      for (var cartItem in cartProvider.cartItems) {
        totalQuantity += cartItem.quantity;
      }
      return totalQuantity;
    }

    double getTotalPrice(CartProvider cartProvider) {
      double totalPrice = 0;
      for (var cartItem in cartProvider.cartItems) {
        totalPrice += cartItem.totalPrice;
      }
      return totalPrice;
    }

    int price = getTotalPrice(cartProvider).toInt();
    int item = getTotalQuantity(cartProvider).toInt();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context).cart,
          style: TextStyle(color: Colors.black, fontSize: 18.sp),
        ),
        elevation: 0.0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeNew()),
            );
          },
          child: Container(
            margin: EdgeInsets.only(left: 10.w),
            child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10.w),
            child: IconButton(
              onPressed: () {
                cartProvider.clearCart();
              },
              icon: const Icon(Icons.delete),
              tooltip: 'Clear Cart',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 15.h),
              Text(
                '$item items ${NumberFormat('#,##0').format(price)} UZS',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5.h),
              SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 1.8,
                  child: ListView.builder(
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartProvider.cartItems[index];
                      final isMandatoryPackage = cartItem.product.name == 'Пакет';

                      return ListTile(
                        leading: Image.network(
                          cartItem.product.imagePath,
                          width: 70.w,
                          height: 70.h,
                          fit: BoxFit.cover,
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cartItem.displayName,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isMandatoryPackage)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEC700),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMandatoryPackage)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                                padding: EdgeInsets.all(8.r),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (cartItem.quantity > 1) {
                                          cartProvider.updateQuantity(
                                            cartItem,
                                            cartItem.quantity - 1,
                                          );
                                        } else {
                                          cartProvider.removeFromCart(cartItem);
                                        }
                                      },
                                      child: const Icon(Icons.remove),
                                    ),
                                    SizedBox(width: 8.w),
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: Center(
                                        child: Text(
                                          cartItem.quantity.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    GestureDetector(
                                      onTap: () {
                                        cartProvider.updateQuantity(
                                          cartItem,
                                          cartItem.quantity + 1,
                                        );
                                      },
                                      child: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                child: Text(
                                  '${cartItem.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          'Total: ${NumberFormat('#,##0').format(cartItem.totalPrice.toInt())} UZS',
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 30.h),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(height: 25.h),
                  TextButton(
                    onPressed: price > 0
                        ? () async {
                            // Log cart items before navigating to checkout
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            print('\n======== CART → CHECKOUT: Cart Items ========');
                            print('Total Items: ${cartProvider.cartItems.length}');
                            print('Total Price: ${cartProvider.getTotalPrice()} UZS');

                            for (int i = 0; i < cartProvider.cartItems.length; i++) {
                              final item = cartProvider.cartItems[i];
                              print('\n--- Item ${i + 1} ---');
                              print('Product ID: ${item.product.id}');
                              print('Product UUID: ${item.product.uuid}');
                              print('Product Name: ${item.product.name}');
                              print('Display Name: ${item.displayName}');
                              print('Quantity: ${item.quantity}');
                              print('Base Price: ${item.product.price} UZS');
                              print('Total Price (with modifiers): ${item.totalPrice} UZS');

                              if (item.selectedModifiers != null && item.selectedModifiers.isNotEmpty) {
                                print('Selected Modifiers (${item.selectedModifiers.length}):');
                                double modifiersTotal = 0.0;
                                for (var modifier in item.selectedModifiers) {
                                  final modPrice = modifier.modifier.price * modifier.quantity;
                                  modifiersTotal += modPrice;
                                  print('  - ${modifier.modifier.name}');
                                  print('    ID: ${modifier.modifier.id}');
                                  print('    Price: ${modifier.modifier.price} UZS');
                                  print('    Quantity: ${modifier.quantity}');
                                  print('    Subtotal: $modPrice UZS');
                                }
                                print('Total Modifiers Cost: $modifiersTotal UZS');
                                print('Item Total (Base + Modifiers) × Quantity: ${(item.product.price + modifiersTotal) * item.quantity} UZS');
                              } else {
                                print('No modifiers selected');
                              }
                            }
                            print('============================================\n');

                            bool isSignedIn = await _isUserSignedIn();
                            Navigator.pushNamed(
                              context,
                              isSignedIn ? '/checkout' : '/signin',
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: price > 0
                          ? const Color(0xFFFEC700)
                          : const Color(0xFFCCCCCC),
                      padding: EdgeInsets.symmetric(
                          vertical: 12.h, horizontal: 24.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context).proceedToCheckout} - ${NumberFormat('#,##0').format(price)} UZS',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

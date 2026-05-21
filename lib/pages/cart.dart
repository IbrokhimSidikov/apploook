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

import '../widgets/recommended_items_section.dart';

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
      backgroundColor: Colors.white,
      // ── Sticky checkout bar ────────────────────────────────────────────────
      bottomNavigationBar: price > 0
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      final cartProvider =
                          Provider.of<CartProvider>(context, listen: false);
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
                        if (item.selectedModifiers.isNotEmpty) {
                          print('Selected Modifiers (${item.selectedModifiers.length}):');
                          double modifiersTotal = 0.0;
                          for (var modifier in item.selectedModifiers) {
                            final modPrice =
                                modifier.modifier.price * modifier.quantity;
                            modifiersTotal += modPrice;
                            print('  - ${modifier.modifier.name}');
                            print('    ID: ${modifier.modifier.id}');
                            print('    Price: ${modifier.modifier.price} UZS');
                            print('    Quantity: ${modifier.quantity}');
                            print('    Subtotal: $modPrice UZS');
                          }
                          print('Total Modifiers Cost: $modifiersTotal UZS');
                          print(
                              'Item Total (Base + Modifiers) × Quantity: ${(item.product.price + modifiersTotal) * item.quantity} UZS');
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
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFEC700),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context).proceedToCheckout} — ${NumberFormat('#,##0').format(price)} UZS',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ColoredBox(
          color: Colors.white,
          child: CustomScrollView(
            slivers: [
              // ── Summary header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$item ${item == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0').format(price)} UZS',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1),
              ),

              // ── Cart items ─────────────────────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cartItem = cartProvider.cartItems[index];
                    final isMandatoryPackage =
                        cartItem.product.name == 'Пакет';

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Product image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.r),
                                child: cartItem.product.imagePath != null
                                    ? Image.network(
                                        cartItem.product.imagePath,
                                        width: 90.w,
                                        height: 64.w,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 64.w,
                                          height: 64.w,
                                          color: Colors.grey[200],
                                          child: const Icon(
                                              Icons.image_not_supported_outlined,
                                              color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        width: 64.w,
                                        height: 64.w,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.grey),
                                      ),
                              ),
                              SizedBox(width: 12.w),

                              // Name + price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cartItem.displayName,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isMandatoryPackage)
                                          Container(
                                            margin: EdgeInsets.only(left: 4.w),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 6.w, vertical: 2.h),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEC700),
                                              borderRadius:
                                                  BorderRadius.circular(4.r),
                                            ),
                                            child: Text(
                                              'Required',
                                              style: TextStyle(
                                                fontSize: 10.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      '${NumberFormat('#,##0').format(cartItem.totalPrice.toInt())} UZS',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8.w),

                              // Quantity control
                              if (!isMandatoryPackage)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(50.r),
                                    border: Border.all(
                                        color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _QtyButton(
                                        icon: cartItem.quantity > 1
                                            ? Icons.remove
                                            : Icons.delete_outline,
                                        iconColor: cartItem.quantity > 1
                                            ? Colors.black
                                            : Colors.red,
                                        onTap: () {
                                          if (cartItem.quantity > 1) {
                                            cartProvider.updateQuantity(
                                                cartItem,
                                                cartItem.quantity - 1);
                                          } else {
                                            cartProvider
                                                .removeFromCart(cartItem);
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 28.w,
                                        child: Center(
                                          child: Text(
                                            '${cartItem.quantity}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _QtyButton(
                                        icon: Icons.add,
                                        onTap: () => cartProvider.updateQuantity(
                                            cartItem, cartItem.quantity + 1),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(50.r),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 8.h),
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
                        ),
                        const Divider(height: 1, thickness: 1, indent: 88),
                      ],
                    );
                  },
                  childCount: cartProvider.cartItems.length,
                ),
              ),

              // ── Recommended items ──────────────────────────────────────
              const SliverToBoxAdapter(child: RecommendedItemsSection()),

              // Bottom padding so content clears the sticky button
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helper widget for quantity +/- buttons ──────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _QtyButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.r),
        child: Icon(icon, size: 18.w, color: iconColor),
      ),
    );
  }
}

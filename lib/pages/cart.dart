import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
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
        totalPrice += cartItem.quantity * cartItem.product.price;
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
          style: TextStyle(color: Colors.black, fontSize: 18),
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
            margin: const EdgeInsets.only(left: 10.0),
            child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10.0),
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
              const SizedBox(height: 15.0),
              Text(
                '$item items ${NumberFormat('#,##0').format(price)} UZS',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5.0),
              SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height / 1.8,
                  child: ListView.builder(
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartProvider.cartItems[index];
                      return ListTile(
                        leading: Image.network(
                          cartItem.product.imagePath,
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          cartItem.product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                              padding: const EdgeInsets.all(8.0),
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
                                  const SizedBox(width: 8.0),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    child: Text(
                                      cartItem.quantity.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
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
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Total: ${NumberFormat('#,##0').format((cartItem.quantity * cartItem.product.price))} UZS',
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30.0),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ElevatedButton(
                  //   onPressed: () {},
                  //   style: ButtonStyle(
                  //     backgroundColor: MaterialStateProperty.all(
                  //       const Color(0xffF1F2F7),
                  //     ),
                  //     foregroundColor: MaterialStateProperty.all(
                  //       Colors.black,
                  //     ),
                  //   ),
                  //   child: const Padding(
                  //     padding: EdgeInsets.all(12.0),
                  //     child: Text(
                  //       'Apply promo code',
                  //       style: TextStyle(
                  //         fontSize: 18,
                  //         fontWeight: FontWeight.w500,
                  //         color: Colors.black26,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 25.0),
                  TextButton(
                    onPressed: price > 0
                        ? () async {
                            bool isSignedIn = await _isUserSignedIn();
                            Navigator.pushReplacementNamed(
                              context,
                              isSignedIn ? '/checkout' : '/signin',
                            );
                          }
                        : null,
                    style: TextButton.styleFrom(
                      backgroundColor: price > 0
                          ? const Color(0xFFFEC700)
                          : const Color(0xFFCCCCCC),
                      padding: const EdgeInsets.only(
                          top: 12.0, bottom: 12.0, left: 24, right: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context).proceedToCheckout} - ${NumberFormat('#,##0').format(price)} UZS',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
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

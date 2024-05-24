import 'package:apploook/cart_provider.dart';
// import 'package:apploook/models/cart_item.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

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

    int price = 0;
    int item = 0;
    item = item + getTotalQuantity(cartProvider).toInt();
    price = price + getTotalPrice(cartProvider).toInt();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Cart',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        elevation: 0.0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomeNew()));
          },
          child: Container(
            margin: const EdgeInsets.only(left: 10.0),
            child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          ),
        ),
        actions: [
          Container(
            margin:  const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () {
                cartProvider.clearCart();
              },
              icon: Icon(Icons.delete),
              tooltip: 'Clear Cart',
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration:
                const BoxDecoration(color: Color.fromARGB(255, 255, 255, 255)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 15.0,
                  ),
                  Text(
                    '$item items ${NumberFormat('#,##0').format(price)} UZS',
                    style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(
                    height: 5.0,
                  ),
                  SingleChildScrollView(
                    child: SizedBox(
                      height: 550, // Set a fixed height
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
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
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
                                                cartItem.quantity - 1);
                                          } else {
                                            cartProvider
                                                .removeFromCart(cartItem);
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
                                              cartItem, cartItem.quantity + 1);
                                        },
                                        child: const Icon(Icons.add),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                                'Total: ${NumberFormat('#,##0').format((cartItem.quantity * cartItem.product.price)).toString()} UZS'),
                          );
                        },
                      ),
                    ),
                  ),
                  // Container(
                  //   height: 250,
                  // ),
                  // SizedBox(
                  //   height: 10.0,
                  // ),
                  // Text(
                  //   'Add it to your order?',
                  //   style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  // ),
                  // SizedBox(
                  //   height: 10.0,
                  // ),
                  // const SizedBox(
                  //   height: 250.0,
                  // ),
                  // Container(
                  //   height: 200,
                  //   color: Colors.white,
                  //   child: ListView.separated(
                  //     itemCount: categories.length,
                  //     scrollDirection: Axis.horizontal,
                  //     padding: EdgeInsets.only(left: 20, right: 20),
                  //     separatorBuilder: (context, index) => SizedBox(
                  //       width: 25.0,
                  //     ),
                  //     itemBuilder: (context, index) {
                  //       return Stack(
                  //         children: [
                  //           Container(
                  //             width: 150,
                  //             height: 200,
                  //             decoration: BoxDecoration(
                  //               color:
                  //                   categories[index].boxColor.withOpacity(0.3),
                  //               borderRadius: BorderRadius.circular(20),
                  //             ),
                  //             child: Stack(
                  //               children: [
                  //                 Image.asset(
                  //                   categories[index].imagePath,
                  //                   fit: BoxFit.fill,
                  //                 ),
                  //                 Positioned(
                  //                   top: 100,
                  //                   left: 15,
                  //                   child: Text(
                  //                     'ITEM NAME',
                  //                     style: TextStyle(
                  //                         fontSize: 15,
                  //                         fontWeight: FontWeight.w700),
                  //                   ),
                  //                 ),
                  //                 Positioned(
                  //                   top: 120,
                  //                   left: 15,
                  //                   child: Text(
                  //                     'Item category',
                  //                     style: TextStyle(
                  //                         fontSize: 15,
                  //                         fontWeight: FontWeight.w300),
                  //                   ),
                  //                 ),
                  //                 Positioned(
                  //                   bottom: 5.0,
                  //                   left: 12.0,
                  //                   child: ElevatedButton(
                  //                       onPressed: () {},
                  //                       style: ButtonStyle(
                  //                           backgroundColor:
                  //                               MaterialStatePropertyAll(
                  //                                   Color(0xffF1F2F7))),
                  //                       child: Text(
                  //                         '32 000 UZS',
                  //                         style: TextStyle(color: Colors.black),
                  //                       )),
                  //                 )
                  //               ],
                  //             ),
                  //           ),
                  //         ],
                  //       );
                  //     },
                  //   ),
                  // ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Positioned(
                    // Position bottom buttons
                    bottom: 25.0, // Adjust spacing from bottom as needed
                    left: 15.0, // Align buttons to left
                    right: 0.0, // Stretch buttons to full width
                    child: Column(
                      // Arrange buttons horizontally
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly, // Distribute evenly
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                const Color(0xffF1F2F7)),
                            foregroundColor:
                                WidgetStateProperty.all(Colors.black),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Apply promo code',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black26),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 25.0,
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                const Color(0xFFFEC700)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacementNamed(context, '/checkout');
                              },
                              child: Text(
                                'Proceed to checkout ${NumberFormat('#,##0').format(price)} UZS',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ], //stack children
      ),
    );
  }
}

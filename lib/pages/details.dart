import 'package:apploook/cart_provider.dart';
import 'package:apploook/models/category-model.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/widget/widget_support.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'dart:convert';

class Details extends StatefulWidget {
  final dynamic product;

  const Details({Key? key, this.product}) : super(key: key);

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int a = 1;
  int quantity = 1;
  double unitPrice = 0;
  double totalPrice = 0;

  List<CategoryModel> categories = [];

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (widget.product.description != null &&
        widget.product.description is String) {
      Map<String, dynamic> descriptionMap =
          json.decode(widget.product.description);
      return descriptionMap[languageCode];
    }
    return null;
  }

  @override
  void initState() {
    _getCategories();
    unitPrice = widget.product.price; // Initialize unitPrice here
    totalPrice = widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();

    var cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white, // Set the background color here
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            ),
            Container(
              height: 650,
              child: Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Image.network(
                          widget.product
                              .imagePath, // Assuming widget.product.imagePath contains the URL
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 2.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              width: 250,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.name,
                                    style: AppWidget.titleTextFieldStyle(),
                                  ),
                                  Text(
                                    widget.product.categoryTitle,
                                    style: AppWidget.HeadlineTextFieldStyle(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              if (quantity > 1) {
                                setState(() {
                                  quantity--;
                                  totalPrice = unitPrice * quantity;
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8)),
                              child:
                                  const Icon(Icons.remove, color: Colors.white),
                            ),
                          ),
                          const SizedBox(
                            width: 20.0,
                          ),
                          Text(
                            quantity.toString(),
                            style: AppWidget.semiboldTextFieldStyle(),
                          ),
                          const SizedBox(
                            width: 20.0,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                quantity++;
                                totalPrice = unitPrice * quantity;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20.0,
                      ),
                      Container(
                        height: 100,
                        child: Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Text(
                              getDescriptionInLanguage('uz') ??
                                  '', // Change 'en' to the desired language code
                              style: AppWidget.LightTextFieldStyle(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      // const Row(
                      //   mainAxisAlignment: MainAxisAlignment.start,
                      //   children: [
                      //     Text(
                      //       'Change drinks',
                      //       style: TextStyle(
                      //         fontSize: 20,
                      //         fontWeight: FontWeight.w500,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      // Change Drinks container goes here
                      // ChangeDrinks(categories: categories)
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            // Row(
            //   children: [
            //     Text(
            //       "Delivery Time",
            //       style: AppWidget.LightTextFieldStyle(),
            //     ),
            //     const SizedBox(
            //       width: 25.0,
            //     ),
            //     Icon(
            //       Icons.alarm,
            //       color: Colors.black54,
            //     ),
            //     const SizedBox(
            //       width: 5.0,
            //     ),
            //     Text(
            //       "30 min",
            //       style: AppWidget.semiboldTextFieldStyle(),
            //     )
            //   ],
            // ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price",
                        style: AppWidget.semiboldTextFieldStyle(),
                      ),
                      Text(
                        "$totalPrice UZS",
                        style: AppWidget.boldTextFieldStyle(),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 215, 31),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            cartProvider.addToCart(widget.product, quantity);
                            cartProvider.logItems();

                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Cart()));
                          },
                          child: const Text(
                            "Add to cart",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                        const SizedBox(
                          width: 30.0,
                        ),
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          width: 10.0,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ChangeDrinks extends StatelessWidget {
  const ChangeDrinks({
    super.key,
    required this.categories,
  });

  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 5.0),
          child: Text(
            'Change drinks',
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(
          height: 5.0,
        ),
        Container(
          height: 180,
          color: const Color.fromARGB(255, 255, 255, 255),
          child: ListView.separated(
            itemCount: categories.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 20),
            separatorBuilder: (context, index) => const SizedBox(
              width: 25,
            ),
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    width: 120,
                    height: 150,
                    decoration: BoxDecoration(
                      color: categories[index].boxColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      categories[index].imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 10, // Adjust the position as needed
                    left: 10, // Adjust the position as needed
                    child: Container(
                      width: 100, // Adjust the width as needed
                      height: 30, // Adjust the height as needed
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 215, 57),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          'change',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

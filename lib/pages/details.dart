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
    super.initState();
    _getCategories();
    unitPrice = widget.product.price; // Initialize unitPrice here
    totalPrice = widget.product.price;
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();

    var cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Image.network(
                        widget.product.imagePath,
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
                            width: MediaQuery.of(context).size.width - 180,
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
                        Container(
                          height: 48,
                          width: 140,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Color(0xFFD9D9D9)),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
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
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: const Icon(Icons.remove,
                                        color: Colors.black),
                                  ),
                                ),
                                SizedBox(width: 20.0),
                                Container(
                                  child: Text(
                                    quantity.toString(),
                                    style: AppWidget.semiboldTextFieldStyle(),
                                  ),
                                ),
                                SizedBox(width: 20.0),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      quantity++;
                                      totalPrice = unitPrice * quantity;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(50)),
                                    child: const Icon(Icons.add,
                                        color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Container(
                      height: 100,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(
                          getDescriptionInLanguage('uz') ?? '',
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    // ChangeDrinks(categories: categories) // Uncomment if ChangeDrinks is needed
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.only(bottom: 50),
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
                    padding:
                        const EdgeInsets.only(top: 15, bottom: 15),
                    decoration: BoxDecoration(
                        color: Color(0xFFFEC700),
                        borderRadius: BorderRadius.circular(50)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            cartProvider.addToCart(widget.product, quantity);
                            cartProvider.logItems();
                           Navigator.pushReplacementNamed(context, '/homeNew');
                          },
                          child: const Text(
                            "Add to cart",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16.0,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600),
                          ),
                        ),
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

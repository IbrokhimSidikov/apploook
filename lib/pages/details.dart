import 'package:apploook/models/category-model.dart';
import 'package:apploook/widget/widget_support.dart';
import 'package:flutter/material.dart';

class Details extends StatefulWidget {
  const Details({super.key});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int a = 1;
  int quantity = 1;
  double unitPrice = 28000;
  double totalPrice = 28000;

  List<CategoryModel> categories = [];

  void _getCategories() {
    categories = CategoryModel.getCategories();
  }

  @override
  void initState() {
    _getCategories();
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_outlined, color: Colors.black),
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
                        child: Image.asset(
                          "images/IMG_3256.png",
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height / 2.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CHICKY BURGER",
                                style: AppWidget.titleTextFieldStyle(),
                              ),
                              Text(
                                "Spinners",
                                style: AppWidget.HeadlineTextFieldStyle(),
                              ),
                            ],
                          ),
                          Spacer(),
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
                              child: Icon(Icons.remove, color: Colors.white),
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
                              child: Icon(Icons.add, color: Colors.white),
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
                              //description for burger
                              "1 each: 495 calories, 23g fat (10g saturated fat), 63mg cholesterol, 1443mg sodium, 48g carbohydrate (10g sugars, 2g fiber), 23g protein.",
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 5.0),
                            child: Text(
                              'Change drinks',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          SizedBox(
                            height: 5.0,
                          ),
                          Container(
                            height: 180,
                            color: Color.fromARGB(255, 255, 255, 255),
                            child: ListView.separated(
                              itemCount: categories.length,
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.only(left: 20, right: 20),
                              separatorBuilder: (context, index) => SizedBox(
                                width: 25,
                              ),
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: categories[index]
                                            .boxColor
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Image.asset(
                                        categories[index].imagePath,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      bottom:
                                          10, // Adjust the position as needed
                                      left: 10, // Adjust the position as needed
                                      child: Container(
                                        width:
                                            100, // Adjust the width as needed
                                        height:
                                            30, // Adjust the height as needed
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              255, 255, 215, 57),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: Center(
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
                      )
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
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 215, 31),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Add to cart",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontFamily: 'Poppins'),
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

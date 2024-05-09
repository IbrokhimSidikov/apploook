import 'package:apploook/models/category-model.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    _getCategories();
  }

  @override
  Widget build(BuildContext context) {
    _getCategories();
    int price = 36000;
    int item = 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cart',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        elevation: 0.0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => HomeNew()));
          },
          child: Container(
            margin: EdgeInsets.only(left: 10.0),
            child: SvgPicture.asset('images/close.svg'),
          ),
        ),
      ),
      backgroundColor: Colors.green,
      body: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration:
                BoxDecoration(color: Color.fromARGB(255, 255, 255, 255)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 15.0,
                  ),
                  Text(
                    ' $item items $price UZS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  Container(
                    height: 250,
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Text(
                    'Add it to your order?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Container(
                    height: 200,
                    color: Colors.white,
                    child: ListView.separated(
                      itemCount: categories.length,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(left: 20, right: 20),
                      separatorBuilder: (context, index) => SizedBox(
                        width: 25.0,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 150,
                              height: 200,
                              decoration: BoxDecoration(
                                color:
                                    categories[index].boxColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    categories[index].imagePath,
                                    fit: BoxFit.fill,
                                  ),
                                  Positioned(
                                    top: 100,
                                    left: 15,
                                    child: Text(
                                      'ITEM NAME',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Positioned(
                                    top: 120,
                                    left: 15,
                                    child: Text(
                                      'Item category',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w300),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 5.0,
                                    left: 12.0,
                                    child: ElevatedButton(
                                        onPressed: () {},
                                        style: ButtonStyle(
                                            backgroundColor:
                                                MaterialStatePropertyAll(
                                                    Color(0xffF1F2F7))),
                                        child: Text(
                                          '32 000 UZS',
                                          style: TextStyle(color: Colors.black),
                                        )),
                                  )
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(
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
                            backgroundColor:
                                MaterialStateProperty.all(Color(0xffF1F2F7)),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.black),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Apply promo code',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25.0,
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                Color.fromARGB(255, 255, 215, 56)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              'Proceed to checkout $price UZS',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
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

import 'package:apploook/cart_provider.dart';
import 'package:apploook/pages/appetizerpage.dart';
import 'package:apploook/pages/burgerpage.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/chickenpage.dart';
import 'package:apploook/pages/combopage.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/pizzapage.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/pages/spinnerpage.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});
}

class Product {
  final String name;
  final int id;
  final int categoryId;
  final String categoryTitle;
  final String? imagePath;
  final double price;
  final dynamic description;

  Product({
    required this.name,
    required this.id,
    required this.categoryId,
    required this.categoryTitle,
    this.imagePath,
    required this.price,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic description = json['description'];
    print(description);
    if (description is String) {
      // Parse the description JSON string into a map if it's a string
      description = jsonDecode(description);
    }

    return Product(
      name: json['name'],
      id: json['id'],
      categoryId: json['categoryId'],
      categoryTitle: json['categoryTitle'],
      imagePath: json['imagePath'],
      price: json['price'].toDouble(),
      description: description,
    );
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (description != null && description is String) {
      Map<String, dynamic> descriptionMap = json.decode(description);
      return descriptionMap[languageCode];
    }
    return null;
  }
}

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew> with TickerProviderStateMixin {
  int selectedTabIndex = 0;
  List<BannerItem> banners = [];

  List<Category> categories = [];
  late TabController _tabController;
  List<Product> allProducts = [];
  Map<int, ScrollController> _categoryScrollControllers = {};

  void _getBanners() {
    banners = BannerItem.getBanners();
  }

  @override
  void initState() {
    _getBanners();
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryScrollControllers.values
        .forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1'));

    if (response.statusCode == 200) {
      List<dynamic> categoryData = json.decode(response.body);
      List<Product> mergedProducts = [];
      for (var category in categoryData) {
        String categoryName = category['name']
            .split('_')[0]; // Get only the first part of the category name
        if (!categoryName.toLowerCase().contains('ava')) {
          List<dynamic> productData = category['products'];
          int categoryId = category['id'];
          // String categoryTitle = category['name'];
          List<Product> products = productData.map((product) {
            var photo = product['photo'];
            String? imagePath = photo != null
                ? 'https://sieveserp.ams3.cdn.digitaloceanspaces.com/${photo['path']}/${photo['name']}.${photo['format']}'
                : null;
            return Product(
                name: product['name'],
                id: product['id'],
                categoryId: categoryId,
                categoryTitle: categoryName,
                imagePath: imagePath,
                price:
                    product['priceList']['price'].toDouble(), // Get the price
                description: product['description']);
          }).toList();
          mergedProducts.addAll(products);
          categories.add(Category(id: categoryId, name: categoryName));
          _categoryScrollControllers[categoryId] = ScrollController();
        }
      }
      setState(() {
        allProducts = mergedProducts;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  final List<String> tabTitles = [
    'Combo',
    'Chicken',
    'Pizza',
    'Burgers',
    'Spinner',
    'Appetizers',
  ];
  final Map<int, Widget> contentPages = {
    0: const ComboPage(),
    1: const ChickenPage(),
    2: const PizzaPage(),
    3: const BurgerPage(),
    4: const SpinnerPage(),
    5: const AppetizerPage(),
  };

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    _getBanners();

    var cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 226, 225, 225),
      body: Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: Stack(
          children: [
            Container(
              //tabs container
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 226, 225, 225),
              ),
            ),
            // Body Container
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 15,
              child: GestureDetector(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => Profile(),
                  //   ),
                  // );
                  _scaffoldKey.currentState!.openDrawer();
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min, // Avoid unnecessary space
                  children: [
                    Icon(Icons.location_on, size: 30),
                    SizedBox(width: 5.0), // Add some horizontal spacing
                    Text("Tashkent"),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 105,
              left: 15,
              child: Text(
                'WHAT`S NEW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            Positioned(
              top: 140,
              left: 15,
              child: Container(
                height: 135,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: ListView.separated(
                  itemCount: banners.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20.0),
                  separatorBuilder: ((context, index) => const SizedBox(
                        width: 25,
                      )),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250,
                      decoration: BoxDecoration(
                          color: banners[index].boxColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16)),
                      child: Image.asset(banners[index].imagePath,
                          fit: BoxFit.contain),
                    );
                  },
                ),
              ),
            ),
            Column(
              children: [
                // Row of buttons with category names
                Container(
                  margin: EdgeInsets.only(top: 307.0), // Add top margin
                  height: 50, // Set the height of the row
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                    color: Colors.transparent,
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal, // Horizontal scroll
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      Category category = categories[index];
                      return Padding(
                        padding: const EdgeInsets.all(0.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _scrollToCategory(category.id);
                          },
                          style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                              return Colors.black;
                            }),
                            backgroundColor: WidgetStateProperty.all<Color>(
                                Colors.transparent),
                            elevation: WidgetStateProperty.all<double>(0),
                            // No elevation
                          ),
                          child: Text(category.name),
                        ),
                      );
                    },
                  ),
                ),
                // List of products for each category
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: categories.map((category) {
                        List<Product> productsInCategory = allProducts
                            .where(
                                (product) => product.categoryId == category.id)
                            .toList();
                        return Column(
                          key: ValueKey<int>(category.id),
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 0),
                              // child: Text(
                              //   category.name,
                              //   style: const TextStyle(
                              //     fontSize: 20,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                            ),
                            ListView.builder(
                              controller:
                                  _categoryScrollControllers[category.id],
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: productsInCategory.length,
                              itemBuilder: (context, productIndex) {
                                Product product =
                                    productsInCategory[productIndex];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          if (productsInCategory.isNotEmpty &&
                                              productIndex <
                                                  productsInCategory.length) {
                                            Product product =
                                                productsInCategory[
                                                    productIndex];
                                            return Details(product: product);
                                          }
                                          // Handle the case where the product list is empty or the index is out of bounds
                                          return Container(); // Or any other fallback widget
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Container(
                                      alignment: Alignment
                                          .center, // Align children vertically
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 10.0),
                                            child: Container(
                                              width: 140.0,
                                              height: 140.0,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                      product.imagePath!),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 5.0),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(3.0),
                                                  child: Text(
                                                    product.getDescriptionInLanguage(
                                                            'uz') ??
                                                        'No Description',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 5.0),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 15.0,
                                                    vertical: 5.0,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0),
                                                    color:
                                                        const Color(0xFFF1F2F7),
                                                  ),
                                                  child: Text(
                                                    '${product.price.toStringAsFixed(0)} UZS',
                                                    style: const TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey,
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
                                );
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // Positioned(
            //   top: 300.0,
            //   left: -40.0,
            //   right: 0.0,
            //   child: DefaultTabController(
            //     length: tabTitles.length,
            //     child: Material(
            //       color: Colors.transparent,
            //       child: TabBar(
            //         isScrollable: true, // Enable horizontal scrolling
            //         labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
            //         indicatorPadding: EdgeInsets.zero, // Adjust spacing
            //         tabs: tabTitles.map((title) => Tab(text: title)).toList(),
            //         onTap: (index) => setState(() => selectedTabIndex = index),
            //       ),
            //     ),
            //   ),
            // ),
            // Positioned(
            //   top: (MediaQuery.of(context).size.height / 2.5) +
            //       10, // Adjust offset
            //   left: 10.0,
            //   right: 10.0,
            //   bottom: 0.0,
            //   child: Container(
            //     height: MediaQuery.of(context).size.height -
            //         (MediaQuery.of(context).size.height / 2.5) -
            //         10,
            //     child: SingleChildScrollView(
            //       child: Container(
            //         decoration: BoxDecoration(
            //           color: Colors.white,
            //         ),
            //         child: Column(
            //           children: [
            //             IndexedStack(
            //               index: selectedTabIndex,
            //               children: contentPages.values.toList(),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            Positioned(
              bottom: 35.0,
              left: 25.0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Cart()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 215, 71),
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          color: Colors.black),
                      const SizedBox(width: 8.0),
                      Text(
                        '${cartProvider.showQuantity()}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Profile(),
      ),
    );
  }

  void _scrollToCategory(int categoryId) {
    ScrollController? controller = _categoryScrollControllers[categoryId];
    print(controller);
    if (controller != null && controller.hasClients) {
      Scrollable.ensureVisible(
        controller.position.context.storageContext,
        alignment: 0.0,
        duration: Duration(milliseconds: 300),
      );
    }
  }
}

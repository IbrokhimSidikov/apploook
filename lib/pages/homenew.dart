import 'package:apploook/cart_provider.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart'; // Import carousel_slider
// import 'package:flutter/material.dart' hide CarouselController;

class Category {
  final int id;
  final String name;
  bool isSelected;

  Category({required this.id, required this.name, this.isSelected = false});
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
  static const cacheValidityDuration = Duration(hours: 6);
  int selectedTabIndex = 0;
  List<BannerItem> banners = [];

  List<Category> categories = [];
  List<Product> allProducts = [];
  Map<int, ScrollController> _categoryScrollControllers = {};
  bool _isLoading = true;

  ValueNotifier<int?> selectedCategoryId = ValueNotifier<int?>(null);
  ScrollController _scrollController = ScrollController();

  void _getBanners() {
    banners = BannerItem.getBanners();
  }

  @override
  void initState() {
    _getBanners();
    super.initState();
    loadData();
  }
  Future<bool> isCacheValid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastUpdateTime = prefs.getInt('lastCacheUpdateTime');
    if (lastUpdateTime == null) return false;
    
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    return (currentTime - lastUpdateTime) < cacheValidityDuration.inMilliseconds;
  }
  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedCategoryData');
    
    bool isValid = await isCacheValid();

    if (cachedData != null && isValid) {
      setState(() {
        processCategoryData(json.decode(cachedData));
        _isLoading = false;
      });
    } else {
      await fetchData();
    }
  }

  @override
  void dispose() {
    selectedCategoryId.dispose();
    _categoryScrollControllers.values
        .forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1'));

    if (response.statusCode == 200) {
      List<dynamic> categoryData = json.decode(response.body);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('cachedCategoryData', response.body);
      // Save the timestamp of this update
      await prefs.setInt('lastCacheUpdateTime', DateTime.now().millisecondsSinceEpoch);

      setState(() {
        processCategoryData(categoryData);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }
  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await fetchData();
  }

  void processCategoryData(List<dynamic> categoryData) {
    List<Product> mergedProducts = [];
    for (var category in categoryData) {
      String categoryName = category['name']
          .split('_')[0]; // Get only the first part of the category name
      if (!categoryName.toLowerCase().contains('ava')) {
        List<dynamic> productData = category['products'];
        int categoryId = category['id'];
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
              price: product['priceList']['price'].toDouble(),
              description: product['description']);
        }).toList();
        mergedProducts.addAll(products);
        categories.add(Category(id: categoryId, name: categoryName));
        _categoryScrollControllers[categoryId] = ScrollController();
      }
    }
    allProducts = mergedProducts;
  }

  void _updateSelectedCategory(double scrollPosition) {
    // Calculate the category id based on the scroll position
    int? newCategoryId;
    for (var entry in _categoryScrollControllers.entries) {
      int categoryId = entry.key;
      ScrollController controller = entry.value;
      if (scrollPosition >= controller.position.pixels &&
          scrollPosition < controller.position.maxScrollExtent) {
        newCategoryId = categoryId;
        break;
      }
    }

    // Update the selected category if it has changed
    if (newCategoryId != null && selectedCategoryId.value != newCategoryId) {
      selectedCategoryId.value = newCategoryId;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    _getBanners();

    var cartProvider = Provider.of<CartProvider>(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF1F2F7),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollUpdateNotification) {
            _updateSelectedCategory(scrollNotification.metrics.pixels);
          }
          return false;
        },
        child: Container(
          margin: const EdgeInsets.only(top: 10.0),
          child: Stack(
            children: [
              Container(
                //tabs container
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
              Positioned(
                top: 40,
                left: 15,
                right: 15,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => Profile(),
                          //   ),
                          // );
                          _scaffoldKey.currentState!.openDrawer();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: SvgPicture.asset('images/profileIconHome.svg'),
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                          Navigator.pushReplacementNamed(context, '/notificationsView');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                          Icons.notifications, // Use any built-in icon here
                          size: 24.0, // Adjust size as needed
                          color: Colors.black, 
                                                ),
                        ),
                      ),
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
              //Carousel Slider Banner
              Positioned(
                top: 135,
                left: 0,
                right: 0,
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 140.0,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 3),
                    enlargeCenterPage: true,
                    enableInfiniteScroll: true,
                  ),
                  items: banners.map((banner) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.symmetric(horizontal: 0.0),
                          decoration: BoxDecoration(
                            color: banner.boxColor.withOpacity(0.0),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Image.asset(
                            banner.imagePath,
                            fit: BoxFit.fill,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              Column(
                children: [
                  // Row of buttons with category names
                  Container(
                    margin: EdgeInsets.only(top: 283.0), // Add top margin
                    height: 50, // Set the height of the row
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                      color: Colors.white,
                    ),
                    child: ValueListenableBuilder<int?>(
                      valueListenable: selectedCategoryId,
                      builder: (context, value, child) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToCategoryBuy(value!);
                        });
                        return ListView.builder(
                          controller: _scrollController,
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
                                      // Check if the button is selected
                                      if (category.id == value) {
                                        // Change the text color when selected
                                        return Color(0xFF000000); // Black
                                      } else {
                                        return Color(0xFFB0B0B0); // Grey
                                      }
                                    },
                                  ),
                                  textStyle: WidgetStateProperty.resolveWith<
                                      TextStyle>(
                                    (states) {
                                      // Check if the button is selected
                                      if (category.id == value) {
                                        // Change the font weight when selected
                                        return TextStyle(
                                          fontWeight: FontWeight.bold,
                                        );
                                      } else {
                                        return TextStyle(
                                          fontWeight: FontWeight.normal,
                                        );
                                      }
                                    },
                                  ),
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith<Color>(
                                    (states) {
                                      return Colors
                                          .transparent; // Set default background color
                                    },
                                  ),
                                  elevation: WidgetStateProperty.all<double>(
                                      0), // No elevation
                                ),
                                child: Text(category.name),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // List of products for each category
                  Container(
                    height: MediaQuery.of(context).size.height - 343,
                    decoration: BoxDecoration(color: Colors.white),
                    child: SingleChildScrollView(
                      child: allProducts.isEmpty
                          ? SizedBox(
                              height: 450,
                              child: Center(
                                child: Container(
                                    child: CircularProgressIndicator()),
                              ),
                            )
                          : Column(
                              children: categories.map((category) {
                                List<Product> productsInCategory = allProducts
                                    .where((product) =>
                                        product.categoryId == category.id)
                                    .toList();
                                return Container(
                                  key: ValueKey<int>(category.id),
                                  child: ListView.builder(
                                    padding: EdgeInsets.only(bottom: 0.0),
                                    controller:
                                        _categoryScrollControllers[category.id],
                                    shrinkWrap: true,
                                    itemCount: productsInCategory.length,
                                    itemBuilder: (context, productIndex) {
                                      Product product =
                                          productsInCategory[productIndex];
                                      return VisibilityDetector(
                                        key: Key(product.id.toString()),
                                        onVisibilityChanged: (visibilityInfo) {
                                          if (visibilityInfo.visibleFraction ==
                                              1) {
                                            selectedCategoryId.value =
                                                product.categoryId;
                                          }
                                        },
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) {
                                                  if (productsInCategory
                                                          .isNotEmpty &&
                                                      productIndex <
                                                          productsInCategory
                                                              .length) {
                                                    Product product =
                                                        productsInCategory[
                                                            productIndex];
                                                    return Details(
                                                        product: product);
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
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
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
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16.0,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 5.0),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(3.0),
                                                        child: Text(
                                                          product.getDescriptionInLanguage(
                                                                  'uz') ??
                                                              'No Description',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.grey,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 5.0),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 15.0,
                                                          vertical: 5.0,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.0),
                                                          color: const Color(
                                                              0xFFF1F2F7),
                                                        ),
                                                        child: Text(
                                                          '${product.price.toStringAsFixed(0)} UZS',
                                                          style:
                                                              const TextStyle(
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
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 50.0,
                left: 25.0,
                child: cartProvider.showQuantity() > 0
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/cart');
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
                      )
                    : SizedBox(), // Render an empty SizedBox if quantity is 0
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Profile(),
      ),
    );
  }

  void _scrollToCategory(int categoryId) {
    // Deselect all categories
    for (var category in categories) {
      category.isSelected = false;
    }

    // Select the category corresponding to categoryId
    Category? selectedCategory;
    for (var category in categories) {
      if (category.id == categoryId) {
        selectedCategory = category;
        break;
      }
    }

    if (selectedCategory != null) {
      selectedCategory.isSelected = true;

      // Scroll to the selected category
      ScrollController? controller = _categoryScrollControllers[categoryId];
      if (controller != null && controller.hasClients) {
        Scrollable.ensureVisible(
          controller.position.context.storageContext,
          alignment: 0.0,
          duration: Duration(milliseconds: 300),
        );
      }
    }

    selectedCategoryId.value = categoryId;
  }

  void _scrollToCategoryBuy(int? categoryId) {
    if (categoryId != null) {
      final index =
          categories.indexWhere((category) => category.id == categoryId);
      if (index != -1) {
        _scrollController.animateTo(
          index * 100.0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}

import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:apploook/widget/cached_product_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/providers/notification_provider.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

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
    return (currentTime - lastUpdateTime) <
        cacheValidityDuration.inMilliseconds;
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
      await prefs.setInt(
          'lastCacheUpdateTime', DateTime.now().millisecondsSinceEpoch);

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
      backgroundColor: Colors.white,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        child: const Profile(),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 270,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFFF1F2F7),
                leading: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SvgPicture.asset('images/profileIconHome.svg'),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    offset: const Offset(0, 25),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEC700),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context
                                .watch<LocaleProvider>()
                                .locale
                                .languageCode
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.black),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'uz',
                        child: Row(
                          children: [
                            Text('🇺🇿', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('O\'zbekcha'),
                          ],
                        ),
                      ),
                      // PopupMenuItem(
                      //   value: 'ru',
                      //   child: Row(
                      //     children: const [
                      //       Text('🇷🇺', style: TextStyle(fontSize: 20)),
                      //       SizedBox(width: 8),
                      //       Text('Русский'),
                      //     ],
                      //   ),
                      // ),
                      const PopupMenuItem(
                        value: 'eng',
                        child: Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('English'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String newLocale) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('selected_language', newLocale);
                      if (!mounted) return;
                      context
                          .read<LocaleProvider>()
                          .setLocale(Locale(newLocale));
                    },
                  ),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return GestureDetector(
                        onTap: () async {
                          await notificationProvider.markAllAsRead();
                          Navigator.pushNamed(context, '/notificationsView');
                        },
                        child: Stack(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 24.0,
                                color: Colors.black,
                              ),
                            ),
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${notificationProvider.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  // const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: Colors.black87),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notification');
                    },
                  ),
                  const SizedBox(width: 10),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      const SizedBox(height: 110),
                      Padding(
                        padding: const EdgeInsets.only(left: 15),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context).whatsNew,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Carousel Slider Banner
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 160.0,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 3),
                          enlargeCenterPage: true,
                          enableInfiniteScroll: true,
                        ),
                        items: banners.map((banner) {
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 0.0),
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
                    ],
                  ),
                ),
              ),
              // Category buttons
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverCategoryHeaderDelegate(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification) {
                        _updateSelectedCategory(
                            scrollNotification.metrics.pixels);
                      }
                      return false;
                    },
                    child: Container(
                      height: 50,
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
                            if (value != null) {
                              _scrollToCategoryBuy(value);
                            }
                          });
                          return ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
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
                                    foregroundColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                      (states) {
                                        return category.id == value
                                            ? const Color(0xFF000000)
                                            : const Color(0xFFB0B0B0);
                                      },
                                    ),
                                    textStyle: MaterialStateProperty
                                        .resolveWith<TextStyle>(
                                      (states) {
                                        return TextStyle(
                                          fontWeight: category.id == value
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        );
                                      },
                                    ),
                                    backgroundColor: MaterialStateProperty
                                        .resolveWith<Color>(
                                      (states) => Colors.transparent,
                                    ),
                                    elevation:
                                        MaterialStateProperty.all<double>(0),
                                  ),
                                  child: Text(category.name),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Products list
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: allProducts.isEmpty
                      ? const SizedBox(
                          height: 450,
                          child: Center(
                            child: CircularProgressIndicator(),
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
                                padding: EdgeInsets.zero,
                                controller:
                                    _categoryScrollControllers[category.id],
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: productsInCategory.length,
                                itemBuilder: (context, productIndex) {
                                  Product product =
                                      productsInCategory[productIndex];
                                  return VisibilityDetector(
                                    key: Key(product.id.toString()),
                                    onVisibilityChanged: (visibilityInfo) {
                                      if (visibilityInfo.visibleFraction == 1) {
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
                                                return Details(
                                                    product: product);
                                              }
                                              return Container();
                                            },
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10.0,
                                          horizontal: 15.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 10.0),
                                              child: CachedProductImage(
                                                imageUrl: product.imagePath!,
                                                width: 135.0,
                                                height: 135.0,
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Consumer<LocaleProvider>(
                                                    builder: (context,
                                                        localeProvider, _) {
                                                      return Text(
                                                        product.getDescriptionInLanguage(
                                                                localeProvider
                                                                    .locale
                                                                    .languageCode) ??
                                                            'No Description',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 35.0,
                                                      vertical: 5.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      color: const Color(
                                                          0xFFF1F2F7),
                                                    ),
                                                    child: Text(
                                                      '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                                                      style: const TextStyle(
                                                        fontSize: 12.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0),
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
                      Navigator.pushNamed(context, '/cart');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEC700),
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
                : const SizedBox(),
          ),
        ],
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
          duration: const Duration(milliseconds: 300),
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
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}

class _SliverCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverCategoryHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 50.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

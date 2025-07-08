import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:apploook/widget/cached_product_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/providers/notification_provider.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/services/payme_transaction_service.dart';
import 'package:apploook/services/order_mode_service.dart';
import 'package:apploook/services/order_tracking_service.dart';

import 'dart:convert';

import '../widget/banner_widget.dart';

class Category {
  final int id;
  final String name;
  bool isSelected;

  Category({required this.id, required this.name, this.isSelected = false});
}

class Product {
  final String name;
  final int id;
  final String uuid; // Original UUID from the API
  final int categoryId;
  final String categoryTitle;
  final String? imagePath;
  final double price;
  final dynamic description;

  Product({
    required this.name,
    required this.id,
    required this.uuid, // Add UUID to constructor
    required this.categoryId,
    required this.categoryTitle,
    this.imagePath,
    required this.price,
    required this.description,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic description = json['description'];
    print('Description type: ${description.runtimeType}, value: $description');

    // Handle description parsing safely
    if (description is String && description.isNotEmpty) {
      try {
        // Try to parse the description JSON string into a map if it's a string
        description = jsonDecode(description);
      } catch (e) {
        print('Error parsing description JSON: $e');
        // If parsing fails, keep it as a string
      }
    }

    // Handle price safely
    double price = 0.0;
    var rawPrice = json['price'];
    if (rawPrice != null) {
      if (rawPrice is double) {
        price = rawPrice;
      } else if (rawPrice is int) {
        price = rawPrice.toDouble();
      } else {
        try {
          price = double.parse(rawPrice.toString());
        } catch (e) {
          print('Error parsing price: $e');
        }
      }
    }

    // Store the original UUID string from the API
    String uuid = '';
    if (json['id'] != null) {
      uuid = json['id'].toString();
    }

    return Product(
      name: json['name'] ?? '',
      id: json['id'] ?? 0,
      uuid: uuid, // Include the UUID string
      categoryId: json['categoryId'] ?? 0,
      categoryTitle: json['categoryTitle'] ?? '',
      imagePath: json['imagePath'], // Keep this nullable
      price: price,
      description: description ?? {},
    );
  }

  String? getDescriptionInLanguage(String languageCode) {
    if (description == null) {
      return null;
    }

    // If description is already a Map, use it directly
    if (description is Map<String, dynamic>) {
      return description[languageCode]?.toString();
    }

    // If description is a String, try to parse it as JSON
    if (description is String && description.isNotEmpty) {
      try {
        Map<String, dynamic> descriptionMap = json.decode(description);
        return descriptionMap[languageCode]?.toString();
      } catch (e) {
        print('Error parsing description in getDescriptionInLanguage: $e');
        // If it's not valid JSON, just return the string itself
        return description;
      }
    }

    // If it's any other type, convert to string
    return description.toString();
  }
}

class HomeNew extends StatefulWidget {
  final OrderMode? initialOrderMode;

  const HomeNew({super.key, this.initialOrderMode});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int selectedTabIndex = 0;
  List<BannerItem> banners = [];
  bool _isLoadingBanners = true;
  final OrderModeService _orderModeService = OrderModeService();

  // Track current order mode to detect changes
  OrderMode? _currentOrderMode;

  List<Category> categories = [];
  List<Product> allProducts = [];
  Map<int, ScrollController> _categoryScrollControllers = {};
  bool _isLoading = true;

  ValueNotifier<int?> selectedCategoryId = ValueNotifier<int?>(null);
  ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;

  Future<void> _getBanners() async {
    try {
      final loadedBanners = await BannerItem.getBanners();
      setState(() {
        banners = loadedBanners;
        _isLoadingBanners = false;
      });
    } catch (e) {
      print('Error loading banners: $e');
      setState(() {
        _isLoadingBanners = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Defer initialization to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndLoadData();
      _checkPendingPaymePayments();
      _initializeOrderMode();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  // Lifecycle observer methods are integrated into the existing dispose method below

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background (like returning from Payme app)
    if (state == AppLifecycleState.resumed) {
      // Check for pending Payme payments
      _checkPendingPaymePayments();
    }
  }

  // Check for pending Payme payments and show loading popup if needed
  Future<void> _checkPendingPaymePayments() async {
    // Use a small delay to ensure the app is fully resumed
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      // Check for pending payments and show loading popup if needed
      PaymeTransactionService.checkPendingOrders(context);
    }
  }

  Future<void> _initializeAndLoadData() async {
    try {
      // First initialize order mode (this will use initialOrderMode if provided)
      await _initializeOrderMode();

      // Then get banners (non-blocking)
      _getBanners();

      // Finally load menu data after order mode is initialized
      // print(
      //     'HomeNew: Loading menu data for order mode: ${_orderModeService.currentMode}');
      await loadData();

      // If we're using an initialOrderMode, force a refresh of the data
      if (widget.initialOrderMode != null) {
        // print(
        //     'HomeNew: Forcing data refresh for initialOrderMode: ${widget.initialOrderMode}');
        await refreshData();
      }

      // Debug print to verify the order mode
      // print(
      //     'HomeNew: Initialization complete with order mode: ${_orderModeService.currentMode}');
    } catch (e) {
      // print('HomeNew: Error during initialization: $e');
      // Still try to load data even if there was an error
      await loadData();
    }
  }

  // Initialize order mode and show selection dialog if needed
  Future<void> _initializeOrderMode() async {
    // First initialize the order mode service
    await _orderModeService.initialize();

    // Check if we have an initialOrderMode from the onboard page
    if (widget.initialOrderMode != null) {
      // print(
      //     'HomeNew: Using initialOrderMode from onboard page: ${widget.initialOrderMode}');
      // Set the order mode directly from the parameter
      await _orderModeService.setOrderMode(widget.initialOrderMode!);

      // Force a refresh of SharedPreferences to ensure it's saved
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('order_mode', widget.initialOrderMode!.index);
      await prefs.setBool('has_user_selected_order_mode', true);
      // print(
      //     'HomeNew: Explicitly saved order mode to SharedPreferences: ${widget.initialOrderMode}');
    }

    // Debug print to verify the order mode was loaded correctly
    // print(
    //     'HomeNew: Order mode initialized to: ${_orderModeService.currentMode}');

    // Store the current mode for reference
    _currentOrderMode = _orderModeService.currentMode;
  }

  // Show order mode selection dialog
  void _showOrderModeSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow closing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button in top-right corner
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 8.0),
                // Title
                Text(
                  AppLocalizations.of(context).orderModeTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16.0),
                // Description
                Text(
                  AppLocalizations.of(context).orderModeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                // Delivery/Takeaway button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () => _setOrderMode(OrderMode.deliveryTakeaway),
                    child: Text(
                      AppLocalizations.of(context).deliveryTakeaway,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                // Carhop button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () => _setOrderMode(OrderMode.carhop),
                    child: Text(
                      AppLocalizations.of(context).carhop,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Set the order mode and refresh data
  void _setOrderMode(OrderMode mode) async {
    // Set the order mode
    await _orderModeService.setOrderMode(mode);

    // Clear the cart
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();

    // Close the dialog
    Navigator.of(context).pop();

    // Refresh the menu data based on the new order mode
    refreshData();
  }

  Future<void> loadData() async {
    try {
      // Use MenuService which handles caching internally
      final menuService = MenuService();
      await menuService.initialize();

      setState(() {
        // Get categories and products from the service
        categories = menuService.categories;
        allProducts = menuService.allProducts;

        // Dispose existing controllers first
        for (var controller in _categoryScrollControllers.values) {
          if (controller.hasClients) {
            controller.dispose();
          }
        }
        _categoryScrollControllers.clear();

        // Initialize scroll controllers for each category with valid IDs
        for (var category in categories) {
          if (category.id > 0) {
            // Only create controllers for valid category IDs
            _categoryScrollControllers[category.id] = ScrollController();
          } else {
            print(
                'Warning: Skipping scroll controller for category with invalid ID: ${category.id}');
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      await fetchData();
    }
  }

  @override
  void dispose() {
    // Unregister observer when disposing
    WidgetsBinding.instance.removeObserver(this);
    selectedCategoryId.dispose();
    _scrollController.dispose();
    _categoryScrollControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      // Use the MenuService to fetch data
      final menuService = MenuService();
      await menuService.initialize();

      setState(() {
        // Get categories and products from the service
        categories = menuService.categories;
        allProducts = menuService.allProducts;

        // Dispose existing controllers first
        for (var controller in _categoryScrollControllers.values) {
          if (controller.hasClients) {
            controller.dispose();
          }
        }
        _categoryScrollControllers.clear();

        // Initialize scroll controllers for each category with valid IDs
        for (var category in categories) {
          if (category.id > 0) {
            // Only create controllers for valid category IDs
            _categoryScrollControllers[category.id] = ScrollController();
          } else {
            print(
                'Warning: Skipping scroll controller for category with invalid ID: ${category.id}');
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the MenuService to refresh data
      final menuService = MenuService();
      await menuService.refreshData();

      setState(() {
        // Get updated categories and products from the service
        categories = menuService.categories;
        allProducts = menuService.allProducts;

        // Dispose existing controllers first
        for (var controller in _categoryScrollControllers.values) {
          if (controller.hasClients) {
            controller.dispose();
          }
        }
        _categoryScrollControllers.clear();

        // Initialize scroll controllers for each category with valid IDs
        for (var category in categories) {
          if (category.id > 0) {
            // Only create controllers for valid category IDs
            _categoryScrollControllers[category.id] = ScrollController();
          } else {
            // print(
            //     'Warning: Skipping scroll controller for category with invalid ID: ${category.id}');
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      // print('Error refreshing data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // processCategoryData has been moved to MenuService for better organization

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

  // Define scaffoldKey as a class field
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

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
                  // Order mode selection icon
                  IconButton(
                    icon: Icon(
                      _orderModeService.currentMode ==
                              OrderMode.deliveryTakeaway
                          ? Icons.delivery_dining
                          : Icons.directions_car,
                      color: Colors.black,
                    ),
                    tooltip: 'Select Order Mode',
                    onPressed: () async {
                      // Show the order mode selection dialog
                      _showOrderModeSelectionDialog();
                    },
                  ),
                  // Language selection dropdown
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
                      const PopupMenuItem(
                        value: 'en',
                        child: Row(
                          children: [
                            Text('🇬🇧', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('English'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ru',
                        child: Row(
                          children: [
                            Text('🇷🇺', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text('Русский'),
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
                  // Consumer<NotificationProvider>(
                  //   builder: (context, notificationProvider, child) {
                  //     return GestureDetector(
                  //       onTap: () async {
                  //         await notificationProvider.markAllOrdersAsRead();
                  //         Navigator.pushNamed(context, '/notificationsView');
                  //       },
                  //       child: Stack(
                  //         children: [
                  //           const Padding(
                  //             padding: EdgeInsets.all(15.0),
                  //             child: Icon(
                  //               Icons.shopping_bag_outlined,
                  //               size: 24.0,
                  //               color: Colors.black,
                  //             ),
                  //           ),
                  //           if (notificationProvider.unreadOrderCount > 0)
                  //             Positioned(
                  //               right: 10,
                  //               top: 10,
                  //               child: Container(
                  //                 padding: const EdgeInsets.all(4),
                  //                 decoration: BoxDecoration(
                  //                   color: Colors.red,
                  //                   borderRadius: BorderRadius.circular(10),
                  //                 ),
                  //                 constraints: const BoxConstraints(
                  //                   minWidth: 16,
                  //                   minHeight: 16,
                  //                 ),
                  //                 child: Text(
                  //                   '${notificationProvider.unreadOrderCount}',
                  //                   style: const TextStyle(
                  //                     color: Colors.white,
                  //                     fontSize: 10,
                  //                   ),
                  //                   textAlign: TextAlign.center,
                  //                 ),
                  //               ),
                  //             ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                  // const SizedBox(width: 10),
                  // Order tracking button
                  Builder(
                    builder: (context) {
                      final orderTrackingService = OrderTrackingService();
                      return GestureDetector(
                        onTap: () {
                          // Mark orders as read when navigating to tracking page
                          orderTrackingService.markOrdersAsRead();
                          Navigator.pushNamed(context, '/unifiedOrderTracking');
                        },
                        child: Stack(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Icon(
                                Icons.receipt_long,
                                size: 24.0,
                                color: Colors.black,
                              ),
                            ),
                            // Show notification badge if there are new orders
                            if (orderTrackingService.hasNewOrders)
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
                                    '${orderTrackingService.newOrdersCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                  const SizedBox(width: 10),
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      return GestureDetector(
                        onTap: () async {
                          await notificationProvider.markAllAsRead();
                          Navigator.pushNamed(context, '/notification');
                        },
                        child: Stack(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(15.0),
                              child: Icon(
                                Icons.notifications_outlined,
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
                  const SizedBox(width: 10),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    children: [
                      const SizedBox(height: 100),
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
                      _isLoadingBanners
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          // : CarouselSlider(
                          //     options: CarouselOptions(
                          //       height: 160.0,
                          //       autoPlay: true,
                          //       autoPlayInterval: const Duration(seconds: 3),
                          //       enlargeCenterPage: true,
                          //       enableInfiniteScroll: true,
                          //     ),
                          //     items: banners.map((banner) {
                          //       return Builder(
                          //         builder: (BuildContext context) {
                          //           return Container(
                          //             width: MediaQuery.of(context).size.width,
                          //             margin: const EdgeInsets.symmetric(
                          //                 horizontal: 0.0),
                          //             decoration: BoxDecoration(
                          //               color: banner.boxColor.withOpacity(0.0),
                          //               borderRadius:
                          //                   BorderRadius.circular(16.0),
                          //             ),
                          //             child: Image.asset(
                          //               banner.imagePath,
                          //               fit: BoxFit.fill,
                          //             ),
                          //           );
                          //         },
                          //       );
                          //     }).toList(),
                          //   ),
                          : BannerCarouselWidget(
                              banners: banners,
                              isLoading: _isLoadingBanners,
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
                                    key: Key(
                                        '${category.id}_${productIndex}_${product.id}'),
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
                                              child: SizedBox(
                                                width: 135.0,
                                                child: AspectRatio(
                                                  aspectRatio: 3 /
                                                      2, // Exact 600x400 ratio (3:2)
                                                  child: product.imagePath !=
                                                          null
                                                      ? CachedProductImage(
                                                          imageUrl: product
                                                              .imagePath!,
                                                          width: 135.0,
                                                          height: 90.0,
                                                        )
                                                      : Container(
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Center(
                                                            child: Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                size: 40,
                                                                color: Colors
                                                                    .grey),
                                                          ),
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
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16.0,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5.0),
                                                  Consumer<LocaleProvider>(
                                                    builder: (context,
                                                        localeProvider, _) {
                                                      final description = product
                                                          .getDescriptionInLanguage(
                                                              localeProvider
                                                                  .locale
                                                                  .languageCode);

                                                      return Text(
                                                        description != null &&
                                                                description
                                                                    .isNotEmpty
                                                            ? description
                                                            : 'No Description',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
          // // Simple Menu Button
          // Positioned(
          //   top: 100.0,
          //   right: 20.0,
          //   child: FloatingActionButton(
          //     heroTag: 'simpleMenuButton',
          //     backgroundColor: const Color(0xFFFEC700),
          //     child: const Icon(Icons.menu_book, color: Colors.black),
          //     onPressed: () {
          //       Navigator.pushNamed(context, '/simpleMenu');
          //     },
          //   ),
          // ),

          // Cart Button
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
    if (categories.isEmpty) return;

    // Throttle scroll events
    if (_isScrolling) return;
    _isScrolling = true;
    Future.delayed(
        const Duration(milliseconds: 200), () => _isScrolling = false);

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

      // Ensure we have a controller for this category
      if (!_categoryScrollControllers.containsKey(categoryId)) {
        print('Creating missing scroll controller for category $categoryId');
        _categoryScrollControllers[categoryId] = ScrollController();
      }

      // Scroll to the selected category with additional safety checks
      ScrollController? controller = _categoryScrollControllers[categoryId];
      if (controller != null) {
        // Only attempt to scroll if the controller is attached to a scroll view
        if (controller.hasClients) {
          try {
            Scrollable.ensureVisible(
              controller.position.context.storageContext,
              alignment: 0.0,
              duration: const Duration(milliseconds: 300),
            );
          } catch (e) {
            print('Error scrolling to category $categoryId: $e');
          }
        } else {
          print(
              'ScrollController for category $categoryId is not attached to any scroll views');
        }
      }
    } else {
      print('Category with ID $categoryId not found');
    }

    selectedCategoryId.value = categoryId;
  }

  void _scrollToCategoryBuy(int? categoryId) {
    if (categoryId == null || categories.isEmpty) {
      return;
    }

    final index =
        categories.indexWhere((category) => category.id == categoryId);
    if (index != -1) {
      // Only attempt to scroll if the controller is attached to a scroll view
      if (_scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            index * 100.0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } catch (e) {
          print('Error scrolling to category $categoryId: $e');
        }
      } else {
        print('Main ScrollController is not attached to any scroll views');
      }
    } else {
      print('Category with ID $categoryId not found in the list');
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

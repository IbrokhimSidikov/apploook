import 'package:apploook/cart_provider.dart';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:apploook/pages/details.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:apploook/widget/cached_product_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/providers/notification_provider.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/services/nearest_branch_service.dart';
import 'package:apploook/services/payme_transaction_service.dart';
import 'package:apploook/services/order_tracking_service.dart';
import 'package:apploook/services/order_history_service.dart';
import 'package:apploook/services/version_checker_service.dart';
import 'package:apploook/services/location_permission_guard.dart';

import 'dart:convert';
import '../models/modifier_models.dart';
import '../models/product_group.dart';
import '../widget/app_bottom_sheet.dart';
import '../widget/banner_widget.dart';
import '../widget/review_bottom_sheet.dart';
import '../widget/variation_selector_sheet.dart';
import '../widget/menu_shimmer.dart';
import '../features/reorder/application/reorder_controller.dart';
import '../features/reorder/presentation/reorder_fab.dart';

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
  final List<ModifierGroup> modifierGroups;
  final String? measure;
  final String? measureUnit;
  final int? sortOrder;
  final Map<String, dynamic>? serviceCodesUz;
  final List<Map<String, dynamic>>? images;
  final bool isPinned;
  final bool outOfStock;

  Product({
    required this.name,
    required this.id,
    required this.uuid, // Add UUID to constructor
    required this.categoryId,
    required this.categoryTitle,
    this.imagePath,
    required this.price,
    required this.description,
    this.modifierGroups = const [],
    this.measure,
    this.measureUnit,
    this.sortOrder,
    this.serviceCodesUz,
    this.images,
    this.isPinned = false,
    this.outOfStock = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    dynamic description = json['description'];
    // print('Description type: ${description.runtimeType}, value: $description');

    if (description is String && description.isNotEmpty) {
      try {
        description = jsonDecode(description);
      } catch (e) {
        print('Error parsing description JSON: $e');
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

    // Parse modifier groups
    List<ModifierGroup> modifierGroups = [];
    if (json['modifierGroups'] != null) {
      modifierGroups = (json['modifierGroups'] as List)
          .map((group) => ModifierGroup.fromJson(group))
          .toList();
    }

    // Handle images array
    List<Map<String, dynamic>>? images;
    if (json['images'] != null) {
      images = List<Map<String, dynamic>>.from(json['images']);
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
      modifierGroups: modifierGroups,
      measure: json['measure']?.toString(),
      measureUnit: json['measureUnit']?.toString(),
      sortOrder: json['sortOrder'],
      serviceCodesUz: json['serviceCodesUz'],
      images: images,
      isPinned: json['isPinned'] ?? false,
      outOfStock: json['outOfStock'] ?? false,
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
        // print('Error parsing description in getDescriptionInLanguage: $e');
        // If it's not valid JSON, just return the string itself
        return description;
      }
    }

    // If it's any other type, convert to string
    return description.toString();
  }
}

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int selectedTabIndex = 0;
  List<BannerItem> banners = [];
  bool _isLoadingBanners = true;

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
      // Kick off the last-order lookup so the reorder FAB can appear once
      // the menu is loaded. Uses cached data on warm starts.
      context.read<ReorderController>().load();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
      // Ensure location permission is granted (mandatory for app usage)
      final permissionGuard = LocationPermissionGuard();
      await permissionGuard.requireLocationPermission(context);
      
      // Get banners (non-blocking)
      _getBanners();

      // Check for app updates first
      _checkForAppUpdates();

      // Check and update nearest branch (non-blocking, runs in background)
      _updateNearestBranch();

      // Load menu data
      await loadData();
    } catch (e) {
      // Still try to load data even if there was an error
      await loadData();
    }
  }

  // Check for app updates
  Future<void> _checkForAppUpdates() async {
    try {
      // Add a small delay to ensure the context is ready
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        final versionChecker = VersionCheckerService();
        await versionChecker.checkForUpdates(context);
      }
    } catch (e) {
      print('HomeNew: Error checking for updates: $e');
    }
  }

  // Update nearest branch in background (non-blocking)
  // This runs every time the app is relaunched to ensure menu is always for the nearest branch
  Future<void> _updateNearestBranch() async {
    try {
      print('HomeNew: Checking for nearest branch on app launch');
      
      final nearestBranchService = NearestBranchService();
      // Skip permission check since user already granted it during onboarding
      await nearestBranchService.findNearestBranch(skipPermissionCheck: true);
      
      final nearestBranchDeliverId = await nearestBranchService.getSavedNearestBranchDeliverId();
      
      if (nearestBranchDeliverId != null && nearestBranchDeliverId.isNotEmpty) {
        print('HomeNew: Updated nearest branch deliver ID: $nearestBranchDeliverId');
        
        // Update MenuService with new branch
        final menuService = MenuService();
        menuService.setNearestBranchDeliverId(nearestBranchDeliverId);
        
        // Check if we have menu data from backend
        final menuData = nearestBranchService.getLatestMenuData();
        
        if (menuData != null) {
          print('HomeNew: Using menu data from backend response');
          await menuService.loadMenuDataFromBackend(menuData);
        } else {
          print('HomeNew: No menu data from backend, refreshing traditionally');
          await menuService.refreshData();
        }
        
        // Reload UI with new menu
        if (mounted) {
          await loadData();
        }
      }
    } catch (e) {
      print('HomeNew: Error updating nearest branch: $e');
      // Don't block the app if branch detection fails
    }
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
      final menuService = MenuService();
      await menuService.initialize();

      setState(() {
        categories = menuService.categories;
        allProducts = menuService.allProducts;

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
      
      // Check if controller is attached before accessing position
      if (controller.hasClients && 
          scrollPosition >= controller.position.pixels &&
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
                expandedHeight: 270.h,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFFF1F2F7),
                leading: GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(10.r),
                    child: SvgPicture.asset('images/profileIconHome.svg'),
                  ),
                ),
                actions: [
                  // ElevatedButton(
                  //   onPressed: () async {
                  //     const testOrderId = 7371189;
                  //     Map<String, dynamic>? orderData;
                  //     try {
                  //       final response = await OrderHistoryService()
                  //           .fetchOrderHistory(page: 1, limit: 50, forceRefresh: true);
                  //       final orders = (response['data'] as List<dynamic>? ?? [])
                  //           .cast<Map<String, dynamic>>();
                  //       orderData = orders.firstWhere(
                  //         (o) => o['id'] == testOrderId,
                  //         orElse: () => <String, dynamic>{},
                  //       );
                  //       if (orderData?.isEmpty == true) orderData = null;
                  //     } catch (_) {}
                  //
                  //     if (!mounted) return;
                  //     await AppBottomSheet.show(
                  //       context: context,
                  //       isDismissible: false,
                  //       enableDrag: false,
                  //       child: ReviewBottomSheet(
                  //         orderId: testOrderId,
                  //         orderData: orderData,
                  //       ),
                  //     );
                  //   },
                  //   child: const Text("Test"),
                  // ),
                  // Language selection dropdown
                  PopupMenuButton<String>(
                    offset: const Offset(0, 25),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      margin: EdgeInsets.only(right: 10.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEC700),
                        borderRadius: BorderRadius.circular(4.r),
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
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
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
                            Padding(
                              padding: EdgeInsets.all(15.r),
                              child: Icon(
                                Icons.receipt_long,
                                size: 24.w,
                                color: Colors.black,
                              ),
                            ),
                            // Show notification badge if there are new orders
                            if (orderTrackingService.hasNewOrders)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16.w,
                                    minHeight: 16.h,
                                  ),
                                  child: Text(
                                    '${orderTrackingService.newOrdersCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
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
                            Padding(
                              padding: EdgeInsets.all(15.r),
                              child: Icon(
                                Icons.notifications_outlined,
                                size: 24.w,
                                color: Colors.black,
                              ),
                            ),
                            if (notificationProvider.unreadCount > 0)
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: EdgeInsets.all(4.r),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16.w,
                                    minHeight: 16.h,
                                  ),
                                  child: Text(
                                    '${notificationProvider.unreadCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
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
                      SizedBox(height: 100.h),
                      Padding(
                        padding: EdgeInsets.only(left: 15.w),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context).whatsNew,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18.sp),
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Carousel Slider Banner
                      _isLoadingBanners
                          ? Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 160.h,
                          margin: EdgeInsets.symmetric(horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                      )
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
                      height: 50.h,
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
                      ? const MenuShimmer()
                      : Column(
                          children: categories.map((category) {
                            // Get MenuService instance
                            final menuService = MenuService();
                            
                            // Get ungrouped products and product groups for this category
                            List<Product> ungroupedProducts = menuService
                                .getUngroupedProductsForCategory(category.id);
                            List<ProductGroup> productGroups = menuService
                                .getProductGroupsForCategory(category.id);
                            
                            // Debug logging
                            if (productGroups.isNotEmpty) {
                              print('🎯 UI: Category "${category.name}" has ${productGroups.length} product groups');
                              for (var group in productGroups) {
                                print('  • ${group.groupName} (${group.variations.length} variations)');
                              }
                            }
                            
                            // Combine groups and ungrouped products into a single list
                            // We'll use a list of dynamic items (either Product or ProductGroup)
                            List<dynamic> displayItems = [];
                            
                            // Separate pinned and non-pinned products
                            List<Product> pinnedProducts = ungroupedProducts.where((p) => p.isPinned).toList();
                            List<Product> nonPinnedProducts = ungroupedProducts.where((p) => !p.isPinned).toList();
                            
                            // Add items in priority order: pinned products first, then groups, then other products
                            displayItems.addAll(pinnedProducts);
                            displayItems.addAll(productGroups);
                            displayItems.addAll(nonPinnedProducts);
                            
                            return Container(
                              key: ValueKey<int>(category.id),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                controller:
                                    _categoryScrollControllers[category.id],
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayItems.length,
                                itemBuilder: (context, itemIndex) {
                                  final item = displayItems[itemIndex];
                                  
                                  // Check if this is a ProductGroup or a regular Product
                                  if (item is ProductGroup) {
                                    return _buildProductGroupCard(
                                      context,
                                      item,
                                      category,
                                      itemIndex,
                                    );
                                  } else if (item is Product) {
                                    return _buildProductCard(
                                      context,
                                      item,
                                      category,
                                      itemIndex,
                                    );
                                  }
                                  
                                  return const SizedBox.shrink();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
          // Cart Button
          Positioned(
            bottom: 50.h,
            left: 25.w,
            child: cartProvider.showQuantity() > 0
                ? TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEC700),
                          borderRadius: BorderRadius.circular(50.r),
                          border: Border.all(color: Colors.white),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.w, vertical: 10.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.black,
                                  size: 28.w,
                                ),
                                Positioned(
                                  right: 0,
                                  top: -2,
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${cartProvider.showQuantity()}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              AppLocalizations.of(context).cart,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox(),
          ),
          // Reorder FAB (right side, mirrors the cart pill on the left)
          Positioned(
            bottom: 50.h,
            right: 25.w,
            child: const ReorderFab(),
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

  /// Build a card for a product group (with variations)
  Widget _buildProductGroupCard(
    BuildContext context,
    ProductGroup productGroup,
    Category category,
    int itemIndex,
  ) {
    return VisibilityDetector(
      key: Key('${category.id}_group_${itemIndex}_${productGroup.primaryVariation.id}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1) {
          selectedCategoryId.value = productGroup.categoryId;
        }
      },
      child: GestureDetector(
        onTap: productGroup.allOutOfStock ? null : () {
          // Show variation selector bottom sheet
          VariationSelectorSheet.show(context, productGroup);
        },
        child: Opacity(
          opacity: productGroup.allOutOfStock ? 0.5 : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 10.h,
              horizontal: 15.w,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Product image with variation badge
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 135.w,
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: productGroup.imagePath != null
                              ? CachedProductImage(
                                  imageUrl: productGroup.imagePath!,
                                  width: 135.w,
                                  height: 90.h,
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40.w,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Out of stock overlay
                      if (productGroup.allOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                'OUT OF\nSTOCK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productGroup.groupName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14.w,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Consumer<LocaleProvider>(
                      builder: (context, localeProvider, _) {
                        final description = productGroup.primaryVariation
                            .getDescriptionInLanguage(
                                localeProvider.locale.languageCode);

                        return Text(
                          description != null && description.isNotEmpty
                              ? description
                              : 'Multiple variations available',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 35.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: const Color(0xFFFEC700),
                      ),
                      child: Text(
                        '${productGroup.getPriceRange().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 11, 11, 11),
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
      ),
    );
  }

  /// Build a card for a regular product (no variations)
  Widget _buildProductCard(
    BuildContext context,
    Product product,
    Category category,
    int itemIndex,
  ) {
    return VisibilityDetector(
      key: Key('${category.id}_${itemIndex}_${product.id}'),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction == 1) {
          selectedCategoryId.value = product.categoryId;
        }
      },
      child: GestureDetector(
        onTap: product.outOfStock ? null : () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => Details(product: product),
            ),
          );
        },
        child: Opacity(
          opacity: product.outOfStock ? 0.5 : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 10.h,
              horizontal: 15.w,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 135.w,
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: product.imagePath != null
                              ? CachedProductImage(
                                  imageUrl: product.imagePath!,
                                  width: 135.w,
                                  height: 90.w,
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: 40.w,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Pin badge for pinned products
                      if (product.isPinned)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEC700),
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.push_pin,
                              size: 14.w,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      // Out of stock overlay
                      if (product.outOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                'OUT OF\nSTOCK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Consumer<LocaleProvider>(
                      builder: (context, localeProvider, _) {
                        final description = product.getDescriptionInLanguage(
                            localeProvider.locale.languageCode);

                        return Text(
                          description != null && description.isNotEmpty
                              ? description
                              : 'No Description',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    SizedBox(height: 5.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 35.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                        color: const Color(0xFFFEC700),
                      ),
                      child: Text(
                        '${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} UZS',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color.fromARGB(255, 11, 11, 11),
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
      ),
    );
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
  double get maxExtent => 50.h;

  @override
  double get minExtent => 50.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

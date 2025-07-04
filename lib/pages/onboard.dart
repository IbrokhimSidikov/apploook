import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/services/order_mode_service.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/services/nearest_branch_service.dart';
import 'package:apploook/pages/homenew.dart';

class Onboard extends StatefulWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _showContent = false;
  late AnimationController _animationController;
  bool isEnglishSelected = false;
  bool isUzbekSelected = false;
  bool _isMenuLoaded = false;
  bool _isLoading = false;

  // Order mode selection
  final OrderModeService _orderModeService = OrderModeService();
  final MenuService _menuService = MenuService();
  final NearestBranchService _nearestBranchService = NearestBranchService();
  OrderMode? _selectedOrderMode =
      OrderMode.deliveryTakeaway; // Default selection
  String? _nearestBranchDeliverId;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _initializeOrderMode();
    _findNearestBranch(); // Find the nearest branch before initializing video
    _initializeVideo(); // This will call _preloadMenuData() after video starts
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    print('Onboard initState: Order mode initialized to $_selectedOrderMode');
  }
  
  // Find the nearest branch based on user's location
  Future<void> _findNearestBranch() async {
    try {
      // Find the nearest branch
      await _nearestBranchService.findNearestBranch();
      
      // Get the deliver ID for the nearest branch
      _nearestBranchDeliverId = await _nearestBranchService.getSavedNearestBranchDeliverId();
      print('Nearest branch deliver ID: $_nearestBranchDeliverId');
    } catch (e) {
      print('Error finding nearest branch: $e');
    }
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language');
    if (savedLanguage != null) {
      setState(() {
        isEnglishSelected = savedLanguage == 'en';
        isUzbekSelected = savedLanguage == 'uz';
      });
    }
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset('assets/videos/loader.mp4');
    await _videoController?.initialize();
    if (!mounted) return;
    setState(() {});
    _videoController?.play();

    // Start preloading menu data as soon as video starts playing
    _preloadMenuData();

    // Wait for video to complete
    _videoController?.addListener(() {
      final controller = _videoController;
      if (controller != null &&
          controller.value.position >= controller.value.duration) {
        if (!_showContent && mounted) {
          setState(() => _showContent = true);
          _animationController.forward();
        }
      }
    });
  }

  Future<void> _preloadMenuData({OrderMode? specificOrderMode}) async {
    print('Onboard: Starting menu preloading during video playback');

    try {
      // First, initialize the order mode service to ensure we have a valid order mode
      await _orderModeService.initialize();

      // Use the specified order mode, current order mode, or default to delivery/takeaway
      OrderMode orderMode = specificOrderMode ?? _orderModeService.currentMode;
      print('Onboard: Preloading menu data for order mode: $orderMode');

      // If a specific order mode is provided, set it in the service
      if (specificOrderMode != null) {
        await _orderModeService.setOrderMode(specificOrderMode);
      }

      // Set the nearest branch deliver ID in the menu service if available
      if (_nearestBranchDeliverId != null && _nearestBranchDeliverId!.isNotEmpty) {
        print('Onboard: Setting nearest branch deliver ID: $_nearestBranchDeliverId');
        _menuService.setNearestBranchDeliverId(_nearestBranchDeliverId!);
      }

      // Preload the menu data for the current order mode
      await _menuService.initialize();
      await _menuService.refreshData(); // Use the correct method name

      print('Onboard: Menu data preloading completed successfully');

      if (!mounted) return;
      setState(() {
        _isMenuLoaded = true;
      });
    } catch (e) {
      print('Onboard: Error preloading menu data: $e');
      // Even if there's an error, we'll mark as loaded to not block the UI
      if (!mounted) return;
      setState(() {
        _isMenuLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeOrderMode() async {
    await _orderModeService.initialize();
    // Set the default order mode to what's in the service if available
    setState(() {
      _selectedOrderMode = _orderModeService.currentMode;
    });
    print('OrderMode initialized from service: $_selectedOrderMode');
  }

  Future<void> _continue() async {
    if (!mounted) return;

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    print('Continue button pressed');
    print(
        'Language selection: English=$isEnglishSelected, Uzbek=$isUzbekSelected');
    print('Order mode selection: $_selectedOrderMode');

    // Check if language is selected
    if (!isEnglishSelected && !isUzbekSelected) {
      print('No language selected, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Order mode should always have a default value now, but check just in case
    if (_selectedOrderMode == null) {
      print('No order mode selected, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an order mode'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Save the selected language
    final selectedLocale = isEnglishSelected ? 'eng' : 'uz';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', selectedLocale);
    print('Saved language: $selectedLocale');

    if (!mounted) return;
    context.read<LocaleProvider>().setLocale(Locale(selectedLocale));

    // Save the selected order mode and reload menu data for this specific order mode
    print('Saving order mode: $_selectedOrderMode');

    // Reset menu loaded flag since we need to load for the specific order mode
    setState(() {
      _isMenuLoaded = false;
    });

    // Preload menu data specifically for the selected order mode
    await _preloadMenuData(specificOrderMode: _selectedOrderMode);

    // Force a refresh of the SharedPreferences to ensure it's saved
    if (_selectedOrderMode == OrderMode.carhop) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('order_mode', OrderMode.carhop.index);
      await prefs.setBool('has_user_selected_order_mode', true);
      print('Explicitly saved carhop mode to SharedPreferences');
    }

    if (!mounted) return;

    print('Menu loaded, navigating to HomeNew with mode: $_selectedOrderMode');
    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeNew(initialOrderMode: _selectedOrderMode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LocaleProvider>().locale.languageCode;

    if (!isEnglishSelected && !isUzbekSelected) {
      isEnglishSelected = currentLocale == 'eng';
      isUzbekSelected = currentLocale == 'uz';
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          // Video Loader
          if (!_showContent && _videoController!.value.isInitialized ?? false)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController?.value.size.width ?? 0,
                  height: _videoController?.value.size.height ?? 0,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          // Main Content
          FadeTransition(
            opacity: _animationController,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Background Image
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Image.asset(
                          'images/look-gradient.png',
                          fit: BoxFit.fitWidth,
                          width: double.infinity,
                        ),
                      ),
                      Column(
                        children: [
                          const Spacer(
                              flex: 70), // Adjust flex to control spacing
                          Center(
                            child: SvgPicture.asset(
                              'images/smile-loook.svg',
                              width: 150,
                              height: 120,
                            ),
                          ),
                          const Spacer(
                              flex: 5), // Adjust flex to control spacing
                          const Text(
                            'Order Now \nNot Only Chicken',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(
                              flex: 10), // Adjust flex to control spacing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      'images/suitable-for-all-basket.svg'),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Suitable For\nEveryone',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      'images/solar--sale-linear.svg'),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Promos\nOffer & Deals',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      'images/heroicons--device-phone-mobile.svg'),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Easy\nOrdering',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(
                              flex: 5), // Adjust flex to control spacing
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 30.0),
                              child: Text(
                                'Choose Language',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const Spacer(
                              flex: 2), // Adjust flex to control spacing
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isEnglishSelected = true;
                                        isUzbekSelected = false;
                                      });
                                      context
                                          .read<LocaleProvider>()
                                          .setLocale(const Locale('en'));
                                    },
                                    child: Container(
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isEnglishSelected
                                            ? const Color.fromARGB(
                                                255, 255, 210, 57)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'English',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isUzbekSelected = true;
                                        isEnglishSelected = false;
                                      });
                                      context
                                          .read<LocaleProvider>()
                                          .setLocale(const Locale('uz'));
                                    },
                                    child: Container(
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isUzbekSelected
                                            ? const Color.fromARGB(
                                                255, 255, 210, 57)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Uzbek',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2),

                          // Order Mode Selection Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16, bottom: 12),
                                child: Text(
                                  'Select Order Mode:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Delivery/Takeaway Option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        print(
                                            'Delivery/Takeaway option tapped');
                                        setState(() {
                                          _selectedOrderMode =
                                              OrderMode.deliveryTakeaway;
                                          print(
                                              'Selected order mode updated: $_selectedOrderMode');
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: BoxDecoration(
                                          color: _selectedOrderMode ==
                                                  OrderMode.deliveryTakeaway
                                              ? const Color.fromARGB(
                                                  255, 255, 210, 57)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.delivery_dining,
                                              size: 32,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Delivery/Takeaway',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Carhop Option
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        print('Carhop option tapped');
                                        setState(() {
                                          _selectedOrderMode = OrderMode.carhop;
                                          print(
                                              'Selected order mode updated: $_selectedOrderMode');
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: BoxDecoration(
                                          color: _selectedOrderMode ==
                                                  OrderMode.carhop
                                              ? const Color.fromARGB(
                                                  255, 255, 210, 57)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 3,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.directions_car,
                                              size: 32,
                                              color: Colors.black,
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Carhop',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const Spacer(flex: 4),
                          TextButton(
                            onPressed: _isLoading ? null : _continue,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: _isLoading
                                      ? const Color(0xFFE0E0E0)
                                      : const Color(0xFFFEC700),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: _isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.black),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : const Text(
                                        "Continue",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                      ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 1),
                          const Text(
                            'PRIVACY POLICY',
                            style: TextStyle(
                              color: Color.fromRGBO(95, 94, 94, 1),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Spacer(
                              flex: 6), // Adjust flex to control spacing
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

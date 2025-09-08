import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:apploook/providers/locale_provider.dart';
import 'package:apploook/services/order_mode_service.dart';
import 'package:apploook/services/menu_service.dart';
import 'package:apploook/services/nearest_branch_service.dart';
import 'package:apploook/services/version_checker_service.dart';
import 'package:apploook/pages/homenew.dart';

enum HapticFeedbackType { light, medium, heavy, selection }

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

  Timer? _hapticTimer;
  Timer? _videoSyncTimer;
  bool _hapticEnabled = true;
  int _hapticPatternIndex = 0;
  bool _isIOS = false;

  final List<int> _exactHapticTimings = [
    1030, // 1.03 seconds
    1180, // 1.18 seconds
    2080, // 2.08 seconds
    2240, // 2.24 seconds
  ];

  final List<HapticFeedbackType> _hapticIntensities = [
    HapticFeedbackType.light,
    HapticFeedbackType.medium,
    HapticFeedbackType.light,
    HapticFeedbackType.heavy,
    HapticFeedbackType.medium,
  ];

  final List<List<int>> _hapticPatterns = [
    [120, 100, 50, 100, 30, 1650],
    //vibrate, pause, vibrate, pause, vibrate, longer pause
  ];

  final OrderModeService _orderModeService = OrderModeService();
  final MenuService _menuService = MenuService();
  final NearestBranchService _nearestBranchService = NearestBranchService();
  final VersionCheckerService _versionChecker = VersionCheckerService();
  OrderMode? _selectedOrderMode =
      OrderMode.deliveryTakeaway; // Default selection
  String? _nearestBranchDeliverId;

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _initializeOrderMode();
    _findNearestBranch();
    _initializeHapticFeedback();
    _initializeVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // print('Onboard initState: Order mode initialized to $_selectedOrderMode');
  }

  void _initializeHapticFeedback() {
    _isIOS = Platform.isIOS;
    // print('✅ iOS device detected: $_isIOS');
    _hapticEnabled = _isIOS;

    // if (_isIOS) {
    //   HapticFeedback.lightImpact();
    //   print('✅ Haptic feedback test successful');
    // } else {
    //   print('ℹ️ Haptic feedback is iOS-only and disabled on this device');
    // }
  }

  void _executeHapticFeedback(HapticFeedbackType type) {
    if (!_hapticEnabled || !_isIOS) return;

    switch (type) {
      case HapticFeedbackType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
        break;
    }
  }

  void _startVideoSyncedHaptic() {
    if (!_hapticEnabled || !_isIOS) return;
    if (_videoController == null || !_videoController!.value.isInitialized)
      return;

    _stopHaptic();

    // print(
    //     '🎬 Video duration: ${_videoController!.value.duration.inMilliseconds}ms');
    // print('🎬 Haptic timings: $_exactHapticTimings');

    for (int i = 0; i < _exactHapticTimings.length; i++) {
      final timing = _exactHapticTimings[i];
      final intensity = _hapticIntensities[i % _hapticIntensities.length];

      Timer(Duration(milliseconds: timing), () {
        if (_videoController == null || !_videoController!.value.isInitialized)
          return;
        if (!_hapticEnabled || !_isIOS) return;

        // print('🔊 HAPTIC TAP ${i + 1}: Executing at ${timing}ms');
        _executeHapticFeedback(intensity);
      });
    }

    _videoSyncTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        timer.cancel();
        return;
      }
      // Get video position in milliseconds
      // final videoPositionMs = _videoController!.value.position.inMilliseconds;

      // print('🎬 Video position: ${videoPositionMs}ms');
    });
  }

  void _startRhythmicalHaptic() {
    if (!_hapticEnabled || !_isIOS) return;

    _stopHaptic();

    final pattern =
        _hapticPatterns[_hapticPatternIndex % _hapticPatterns.length];

    _executeHapticPattern(pattern);
  }

  void _executeHapticPattern(List<int> pattern) {
    if (!_hapticEnabled || !_isIOS) return;

    _hapticTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_hapticEnabled || !_isIOS) return;
      HapticFeedback.lightImpact();
      // print('🔊 HAPTIC TAP 1: Light impact at 200ms');
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!_hapticEnabled || !_isIOS) return;
      HapticFeedback.mediumImpact();
      // print('🔊 HAPTIC TAP 2: Medium impact at 1500ms');
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!_hapticEnabled || !_isIOS) return;
      HapticFeedback.selectionClick();
      // print('🔊 HAPTIC TAP 3: Selection click at 3000ms');
    });

    Future.delayed(const Duration(milliseconds: 4500), () {
      if (!_hapticEnabled || !_isIOS) return;
      HapticFeedback.mediumImpact();
      // print('🔊 HAPTIC TAP 4: Medium impact at 4500ms');
    });

    // For debugging
    // print(
    // '🔊 Starting haptic pattern with specific timings: 200ms, 1500ms, 3000ms, 4500ms');
  }

  void _stopHaptic() {
    _hapticTimer?.cancel();
    _hapticTimer = null;

    _videoSyncTimer?.cancel();
    _videoSyncTimer = null;
  }

  void _nextHapticPattern() {
    _hapticPatternIndex = (_hapticPatternIndex + 1) % _hapticPatterns.length;
    if (_hapticEnabled && _isIOS) {
      _startRhythmicalHaptic();
    }
  }
  // Test qilish uchun ios only, haptic tap

  // void _toggleHaptic() {
  //   if (!_isIOS) return;

  //   setState(() {
  //     _hapticEnabled = !_hapticEnabled;
  //   });

  //   if (_hapticEnabled) {
  //     _startRhythmicalHaptic();
  //   } else {
  //     _stopHaptic();
  //   }
  // }

  // Find the nearest branch based on user's location
  Future<void> _findNearestBranch() async {
    try {
      await _nearestBranchService.findNearestBranch();

      _nearestBranchDeliverId =
          await _nearestBranchService.getSavedNearestBranchDeliverId();
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

    // print(
    //     '🎬 Video initialized: ${_videoController!.value.duration.inSeconds} seconds');

    setState(() {});
    _videoController?.play();

    _startVideoSyncedHaptic();

    _preloadMenuData();

    _videoController?.addListener(() {
      final controller = _videoController;
      if (controller != null &&
          controller.value.position >= controller.value.duration) {
        if (!_showContent && mounted) {
          _stopHaptic();
          setState(() => _showContent = true);
          _animationController.forward();
        }
      }
    });
  }

  Future<void> _preloadMenuData({OrderMode? specificOrderMode}) async {
    // print('Onboard: Starting menu preloading during video playback');

    try {
      await _orderModeService.initialize();

      OrderMode orderMode = specificOrderMode ?? _orderModeService.currentMode;
      // print('Onboard: Preloading menu data for order mode: $orderMode');

      if (specificOrderMode != null) {
        await _orderModeService.setOrderMode(specificOrderMode);
      }

      if (_nearestBranchDeliverId != null &&
          _nearestBranchDeliverId!.isNotEmpty) {
        // print(
        //     'Onboard: Setting nearest branch deliver ID: $_nearestBranchDeliverId');
        _menuService.setNearestBranchDeliverId(_nearestBranchDeliverId!);
      }

      await _menuService.initialize();
      await _menuService.refreshData();

      // print('Onboard: Menu data preloading completed successfully');

      if (!mounted) return;
      setState(() {
        _isMenuLoaded = true;
      });
    } catch (e) {
      print('Onboard: Error preloading menu data: $e');
      // Even if there's an error, mark as loaded to not block the UI
      if (!mounted) return;
      setState(() {
        _isMenuLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _stopHaptic();
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeOrderMode() async {
    await _orderModeService.initialize();
    setState(() {
      _selectedOrderMode = _orderModeService.currentMode;
    });
    // print('OrderMode initialized from service: $_selectedOrderMode');
  }

  Future<void> _continue() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Check for app updates first
    print('Checking for app updates before proceeding...');
    final bool updateRequired = await _versionChecker.checkForUpdates(context);
    
    // If update is required, the dialog will be shown and we should not proceed
    if (updateRequired) {
      print('Update required, blocking navigation to HomeNew');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    print('No update required, continuing with app flow');

    // Check if language is selected
    if (!isEnglishSelected && !isUzbekSelected) {
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

    if (_selectedOrderMode == null) {
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

    if (!mounted) return;
    context.read<LocaleProvider>().setLocale(Locale(selectedLocale));

    setState(() {
      _isMenuLoaded = false;
    });

    await _preloadMenuData(specificOrderMode: _selectedOrderMode);

    // Force a refresh of the SharedPreferences to ensure it's saved
    if (_selectedOrderMode == OrderMode.carhop) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('order_mode', OrderMode.carhop.index);
      await prefs.setBool('has_user_selected_order_mode', true);
    }

    if (!mounted) return;

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
      floatingActionButton: _showContent
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Haptic feedback toggle button (iOS only)
                // if (_isIOS)
                //   FloatingActionButton(
                //     mini: true,
                //     backgroundColor:
                //         _hapticEnabled ? Colors.orange : Colors.grey,
                //     onPressed: _toggleHaptic,
                //   child: Icon(
                //     _hapticEnabled ? Icons.touch_app : Icons.mobile_off,
                //     color: Colors.white,
                //     size: 20,
                //   ),
                // ),
                // if (_isIOS) const SizedBox(height: 8),
                // // Pattern cycle button (iOS only)
                // if (_isIOS && _hapticEnabled)
                //   FloatingActionButton(
                //     mini: true,
                //     backgroundColor: Colors.deepOrange,
                //     onPressed: _nextHapticPattern,
                //     child: Text(
                //       '${_hapticPatternIndex + 1}',
                //       style: const TextStyle(
                //         color: Colors.white,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
              ],
            )
          : null,
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
                          const Spacer(flex: 70),
                          Center(
                            child: SvgPicture.asset(
                              'images/smile-loook.svg',
                              width: 150,
                              height: 120,
                            ),
                          ),
                          const Spacer(flex: 5),
                          Text(
                            AppLocalizations.of(context).orderNowNotOnlyChicken,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(flex: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      'images/suitable-for-all-basket.svg'),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context)
                                        .suitableForEveryone,
                                    style: const TextStyle(
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
                                  Text(
                                    AppLocalizations.of(context)
                                        .promosOfferDeals,
                                    style: const TextStyle(
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
                                  Text(
                                    AppLocalizations.of(context).easyOrdering,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(flex: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Text(
                                AppLocalizations.of(context).chooseLanguage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 2),
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
                          // const Spacer(flex: 2),

                          // Order Mode Selection
                          // Column(
                          //   crossAxisAlignment: CrossAxisAlignment.start,
                          //   children: [
                          //     Padding(
                          //       padding:
                          //           const EdgeInsets.only(left: 16, bottom: 12),
                          //       child: Text(
                          //         AppLocalizations.of(context).selectOrderMode,
                          //         style: const TextStyle(
                          //           color: Colors.white,
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.w500,
                          //         ),
                          //       ),
                          //     ),
                          //     Row(
                          //       mainAxisAlignment:
                          //           MainAxisAlignment.spaceEvenly,
                          //       children: [
                          //         Expanded(
                          //           child: GestureDetector(
                          //             onTap: () {
                          //               // print(
                          //               //     'Delivery/Takeaway option tapped');
                          //               setState(() {
                          //                 _selectedOrderMode =
                          //                     OrderMode.deliveryTakeaway;
                          //                 // print(
                          //                 //     'Selected order mode updated: $_selectedOrderMode');
                          //               });
                          //             },
                          //             child: Container(
                          //               margin: const EdgeInsets.symmetric(
                          //                   horizontal: 8),
                          //               padding: const EdgeInsets.symmetric(
                          //                   vertical: 16),
                          //               decoration: BoxDecoration(
                          //                 color: _selectedOrderMode ==
                          //                         OrderMode.deliveryTakeaway
                          //                     ? const Color.fromARGB(
                          //                         255, 255, 210, 57)
                          //                     : Colors.white,
                          //                 borderRadius:
                          //                     BorderRadius.circular(10),
                          //                 boxShadow: [
                          //                   BoxShadow(
                          //                     color:
                          //                         Colors.black.withOpacity(0.2),
                          //                     spreadRadius: 1,
                          //                     blurRadius: 3,
                          //                     offset: const Offset(0, 2),
                          //                   ),
                          //                 ],
                          //               ),
                          //               child: Column(
                          //                 children: [
                          //                   const Icon(
                          //                     Icons.delivery_dining,
                          //                     size: 32,
                          //                     color: Colors.black,
                          //                   ),
                          //                   const SizedBox(height: 8),
                          //                   Text(
                          //                     AppLocalizations.of(context)
                          //                         .deliveryTakeaway,
                          //                     textAlign: TextAlign.center,
                          //                     style: const TextStyle(
                          //                       color: Colors.black,
                          //                       fontSize: 14,
                          //                       fontWeight: FontWeight.w500,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ),

                          //         // Carhop Option
                          //         Expanded(
                          //           child: GestureDetector(
                          //             onTap: () {
                          //               // print('Carhop option tapped');
                          //               setState(() {
                          //                 _selectedOrderMode = OrderMode.carhop;
                          //                 // print(
                          //                 //     'Selected order mode updated: $_selectedOrderMode');
                          //               });
                          //             },
                          //             child: Container(
                          //               margin: const EdgeInsets.symmetric(
                          //                   horizontal: 8),
                          //               padding: const EdgeInsets.symmetric(
                          //                   vertical: 16),
                          //               decoration: BoxDecoration(
                          //                 color: _selectedOrderMode ==
                          //                         OrderMode.carhop
                          //                     ? const Color.fromARGB(
                          //                         255, 255, 210, 57)
                          //                     : Colors.white,
                          //                 borderRadius:
                          //                     BorderRadius.circular(10),
                          //                 boxShadow: [
                          //                   BoxShadow(
                          //                     color:
                          //                         Colors.black.withOpacity(0.2),
                          //                     spreadRadius: 1,
                          //                     blurRadius: 3,
                          //                     offset: const Offset(0, 2),
                          //                   ),
                          //                 ],
                          //               ),
                          //               child: Column(
                          //                 children: [
                          //                   const Icon(
                          //                     Icons.directions_car,
                          //                     size: 32,
                          //                     color: Colors.black,
                          //                   ),
                          //                   const SizedBox(height: 8),
                          //                   Text(
                          //                     AppLocalizations.of(context)
                          //                         .carhop,
                          //                     textAlign: TextAlign.center,
                          //                     style: const TextStyle(
                          //                       color: Colors.black,
                          //                       fontSize: 14,
                          //                       fontWeight: FontWeight.w500,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ],
                          // ),

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
                                    : Text(
                                        AppLocalizations.of(context)
                                            .continueButton,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
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
                          const Spacer(flex: 6),
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

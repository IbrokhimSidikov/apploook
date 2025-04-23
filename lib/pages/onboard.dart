import 'package:flutter/material.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
    _initializeVideo();
    _preloadMenuData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
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

    // Wait for video to complete
    _videoController?.addListener(() {
      final controller = _videoController;
      if (controller != null && controller.value.position >= controller.value.duration) {
        if (!_showContent && mounted) {
          setState(() => _showContent = true);
          _animationController.forward();
        }
      }
    });
  }

  Future<void> _preloadMenuData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cachedCategoryData');
    bool isValid = false;
    
    if (cachedData != null) {
      final lastUpdateTime = prefs.getInt('lastCacheUpdateTime');
      if (lastUpdateTime != null) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        isValid = (currentTime - lastUpdateTime) < const Duration(hours: 6).inMilliseconds;
      }
    }

    if (!isValid) {
      try {
        final response = await http.get(
          Uri.parse('https://api.sievesapp.com/v1/public/pos-category?photo=1&product=1')
        );
        if (response.statusCode == 200) {
          await prefs.setString('cachedCategoryData', response.body);
          await prefs.setInt('lastCacheUpdateTime', DateTime.now().millisecondsSinceEpoch);
        }
      } catch (e) {
        print('Error pre-loading menu data: $e');
      }
    }
    if (!mounted) return;
    setState(() {
      _isMenuLoaded = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!mounted) return;
    
    // Save the selected language
    if (isEnglishSelected || isUzbekSelected) {
      final selectedLocale = isEnglishSelected ? 'eng' : 'uz';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', selectedLocale);
      
      if (!mounted) return;
      context.read<LocaleProvider>().setLocale(Locale(selectedLocale));
    }

    if (_isMenuLoaded) {
      Navigator.pushReplacementNamed(context, '/homeNew');
    } else {
      // Show loading indicator if menu is not ready
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFEC700)),
            ),
          );
        },
      );
      
      // Wait for menu to load
      while (!_isMenuLoaded) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog
      Navigator.pushReplacementNamed(context, '/homeNew');
    }
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                            ? const Color.fromARGB(255, 255, 210, 57)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                            ? const Color.fromARGB(255, 255, 210, 57)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
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
                          const Spacer(
                              flex: 1), // Adjust flex to control spacing
                          TextButton(
                            onPressed: _continue,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.85, // Responsive width
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              margin: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEC700),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Text(
                                "Continue",
                                textAlign: TextAlign.center, // Center the text
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Fixed font size
                                ),
                                maxLines: 1, // Prevent text wrapping
                                overflow: TextOverflow.visible, // Show all text
                              ),
                            ),
                          ),
                          const Spacer(
                              flex: 1), // Adjust flex to control spacing
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

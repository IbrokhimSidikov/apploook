import 'package:apploook/pages/home.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Onboard extends StatefulWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  late PageController _controller;
  bool isEnglishSelected = false;
  bool isuzbekSelected = false;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
     _initializeLanguage();
  }

  Future<void> _initializeLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language');
    if (savedLanguage != null) {
      setState(() {
        isEnglishSelected = savedLanguage == 'en';
        isuzbekSelected = savedLanguage == 'uz';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() async {
    if (isEnglishSelected || isuzbekSelected) {
      final selectedLocale = isEnglishSelected ? 'en' : 'uz';
      
      // Save the selected language in shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', selectedLocale);

      // Update the app's locale using LocaleProvider
      if (!mounted) return;
      context.read<LocaleProvider>().setLocale(Locale(selectedLocale));

      // Navigate to the next page
      Navigator.pushReplacementNamed(context, '/homeNew');
    } else {
      // Show a message if no language is selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a language')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.watch<LocaleProvider>().locale.languageCode;

    if (!isEnglishSelected && !isuzbekSelected) {
      isEnglishSelected = currentLocale == 'en';
      isuzbekSelected = currentLocale == 'uz';
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
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
                    Spacer(flex: 70), // Adjust flex to control spacing
                    Center(
                      child: SvgPicture.asset(
                        'images/smile-loook.svg',
                        width: 150,
                        height: 120,
                      ),
                    ),
                    Spacer(flex: 5), // Adjust flex to control spacing
                    Text(
                      'Order Now \nNot Only Chicken',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Spacer(flex: 10), // Adjust flex to control spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                                'images/suitable-for-all-basket.svg'),
                            SizedBox(width: 4),
                            Text(
                              'Suitable For\nEveryone',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SvgPicture.asset('images/solar--sale-linear.svg'),
                            SizedBox(width: 4),
                            Text(
                              'Promos\nOffer & Deals',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SvgPicture.asset(
                                'images/heroicons--device-phone-mobile.svg'),
                            SizedBox(width: 4),
                            Text(
                              'Easy\nOrdering',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(flex: 5), // Adjust flex to control spacing
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30.0),
                        child: Text(
                          'Choose Language',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                    Spacer(flex: 2), // Adjust flex to control spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isEnglishSelected = true;
                              isuzbekSelected = false;
                            });
                            context.read<LocaleProvider>().setLocale(Locale('en'));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 60),
                            margin: EdgeInsets.only(
                                top: 10, bottom: 10, right: 5, left: 15),
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
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'English',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isuzbekSelected = true;
                              isEnglishSelected = false;
                            });
                            context.read<LocaleProvider>().setLocale(Locale('uz'));
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 60),
                            margin: EdgeInsets.only(
                                top: 10, bottom: 10, right: 15, left: 5),
                            decoration: BoxDecoration(
                              color: isuzbekSelected
                                  ? const Color.fromARGB(255, 255, 210, 57)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Uzbek',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Spacer(flex: 1), // Adjust flex to control spacing
                    TextButton(
                      onPressed: _continue,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // Remove default padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 150),
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEC700),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Spacer(flex: 1), // Adjust flex to control spacing
                    Text(
                      'PRIVACY POLICY',
                      style: TextStyle(
                        color: Color.fromRGBO(95, 94, 94, 1),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Spacer(flex: 6), // Adjust flex to control spacing
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

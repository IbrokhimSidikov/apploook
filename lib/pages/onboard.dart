import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Onboard extends StatefulWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  late PageController _controller;
  bool isEnglishSelected = false;
  bool isTurkishSelected = false;

  @override
  void initState() {
    _controller = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background Image
                Positioned(
                  child: Container(
                    // decoration: BoxDecoration(boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.5),
                    //     spreadRadius: 5,
                    //     blurRadius: 10,
                    //     offset: Offset(0, 3), // changes position of shadow
                    //   )
                    // ]),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7), // Start color
                          Colors.transparent, // End color (fully transparent)
                        ],
                      ),
                    ),
                    child: Image.asset(
                      'images/onboard_cover.png',
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
                  ),
                ),
                // Loook Smile logo
                Positioned(
                  bottom: 395, // Adjust the position as needed
                  left: 70, // Adjust the position as needed
                  child: SvgPicture.asset(
                    'images/smile-loook.svg',
                    width: 150, // Adjust the size as needed
                    height: 120, // Adjust the size as needed
                  ),
                ),
                // Gradient Container
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 150, // Adjust the height as needed
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Text under SVG
                const Positioned(
                  bottom: 340, // Adjust the position as needed
                  left: 150, // Adjust the position as needed
                  child: Text(
                    '      Order Now  \nNot Only Chicken',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(
                  height: 10.0,
                ),
                Positioned(
                  bottom: 275, // Adjust the position as needed
                  left: 18, // Adjust the position as needed
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SvgPicture.asset('images/suitable-for-all-basket.svg'),
                      SizedBox(width: 8),
                      Text(
                        'Suitable For\nEveryone',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      SizedBox(
                        width: 50,
                      ),
                      // Add more icon and text pairs here if needed
                      SvgPicture.asset('images/solar--sale-linear.svg'),
                      SizedBox(width: 8),
                      Text(
                        'Promos\nOffer & Deals',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      SizedBox(
                        width: 50,
                      ),
                      SvgPicture.asset(
                          'images/heroicons--device-phone-mobile.svg'),
                      SizedBox(width: 8),
                      Text(
                        'Easy\nOrdering',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      // Positioned widget for "Choose Language" text
                    ],
                  ),
                ),
                Positioned(
                  bottom: 230,
                  left: 15,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Language',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 52,
                ),
                //language text fields
                Positioned(
                  bottom: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isEnglishSelected = true;
                            isTurkishSelected = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 65),
                          margin: EdgeInsets.all(10),
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
                          child: Text(
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
                            isTurkishSelected = true;
                            isEnglishSelected = false;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 65),
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isTurkishSelected
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
                          child: Text(
                            'Turkish',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 10,
                  child: Row(
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 150),
                        margin: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 210, 57),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          "Continue",
                          style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold),
                        ),
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

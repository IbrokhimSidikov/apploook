import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Onboard extends StatefulWidget {
  const Onboard({Key? key}) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  late PageController _controller;

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
      body: Stack(
        children: [
          // Background Image
          Positioned(
            child: Container(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: Offset(0, 3), // changes position of shadow
                )
              ]),
              child: Image.asset(
                'images/onboard_cover.png',
                fit: BoxFit.fitWidth,
                width: double.infinity,
              ),
            ),
          ),
          // Loook Smile logo
          Positioned(
            bottom: 195, // Adjust the position as needed
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
            bottom: 145, // Adjust the position as needed
            left: 160, // Adjust the position as needed
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
            bottom: 50, // Adjust the position as needed
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
                SvgPicture.asset('images/heroicons--device-phone-mobile.svg'),
                SizedBox(width: 8),
                Text(
                  'Easy\nOrdering',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

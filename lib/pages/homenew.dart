import 'package:apploook/pages/appetizerpage.dart';
import 'package:apploook/pages/burgerpage.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/chickenpage.dart';
import 'package:apploook/pages/combopage.dart';
import 'package:apploook/pages/pizzapage.dart';
import 'package:apploook/pages/signup.dart';
import 'package:apploook/pages/spinnerpage.dart';
import 'package:apploook/widget/banner_item.dart';
import 'package:flutter/material.dart';

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew> {
  int selectedTabIndex = 0;
  List<BannerItem> banners = [];

  void _getBanners() {
    banners = BannerItem.getBanners();
  }

  @override
  void initState() {
    _getBanners();
  }

  final List<String> tabTitles = [
    'Combo',
    'Chicken',
    'Pizza',
    'Burgers',
    'Spinner',
    'Appetizers',
  ];
  final Map<int, Widget> contentPages = {
    0: const ComboPage(),
    1: const ChickenPage(),
    2: const PizzaPage(),
    3: const BurgerPage(),
    4: const SpinnerPage(),
    5: const AppetizerPage(),
  };

  @override
  Widget build(BuildContext context) {
    _getBanners();
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: Stack(
          children: [
            Container(
              //tabs container
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 226, 225, 225),
              ),
            ),
            // Body Container
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: 15,
              child: GestureDetector(
                onDoubleTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignUp()));
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 15,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Avoid unnecessary space
                  children: [
                    Icon(Icons.location_on, size: 30),
                    SizedBox(width: 5.0), // Add some horizontal spacing
                    Text("Istanbul"),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 105,
              left: 15,
              child: Container(
                child: Text(
                  'WHAT`S NEW',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            // Positioned(
            //   top: 140,
            //   left: 15,
            //   child: Container(
            //     child: SingleChildScrollView(
            //       scrollDirection: Axis.horizontal,
            //       child: Row(
            //         children: [
            //           Container(
            //             margin: EdgeInsets.symmetric(horizontal: 5),
            //             width: 250, // Adjust the width as needed
            //             child: Image.asset(
            //               'images/sale50offburgers.png',
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           SizedBox(width: 10.0),
            //           Container(
            //             margin: EdgeInsets.symmetric(horizontal: 5),
            //             width: 250, // Adjust the width as needed
            //             child: Image.asset(
            //               'images/sale50offburgers.png',
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           SizedBox(width: 10.0),
            //           Container(
            //             margin: EdgeInsets.symmetric(horizontal: 5),
            //             width: 250, // Adjust the width as needed
            //             child: Image.asset(
            //               'images/sale50offburgers.png',
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           SizedBox(width: 10.0),
            //           Container(
            //             margin: EdgeInsets.symmetric(horizontal: 5),
            //             width: 250, // Adjust the width as needed
            //             child: Image.asset(
            //               'images/sale50offburgers.png',
            //               fit: BoxFit.cover,
            //             ),
            //           ),
            //           // Add more images here if needed
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            Positioned(
              top: 140,
              left: 15,
              child: Container(
                height: 135,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: ListView.separated(
                  itemCount: banners.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(right: 20.0),
                  separatorBuilder: ((context, index) => SizedBox(
                        width: 25,
                      )),
                  itemBuilder: (context, index) {
                    return Container(
                      width: 250,
                      decoration: BoxDecoration(
                          color: banners[index].boxColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16)),
                      child: Image.asset(banners[index].imagePath,
                          fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ),

            Positioned(
              top: 300.0,
              left: -40.0,
              right: 0.0,
              child: DefaultTabController(
                length: tabTitles.length,
                child: Material(
                  color: Colors.transparent,
                  child: TabBar(
                    isScrollable: true, // Enable horizontal scrolling
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                    indicatorPadding: EdgeInsets.zero, // Adjust spacing
                    tabs: tabTitles.map((title) => Tab(text: title)).toList(),
                    onTap: (index) => setState(() => selectedTabIndex = index),
                  ),
                ),
              ),
            ),
            Positioned(
              top: (MediaQuery.of(context).size.height / 2.5) +
                  10, // Adjust offset
              left: 10.0,
              right: 10.0,
              bottom: 0.0,
              child: Container(
                height: MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).size.height / 2.5) -
                    10,
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        IndexedStack(
                          index: selectedTabIndex,
                          children: contentPages.values.toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 35.0,
              left: 25.0,
              child: FloatingActionButton(
                child: const Icon(Icons.shopping_bag_outlined),
                backgroundColor: const Color.fromARGB(255, 255, 215, 71),
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => Cart()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

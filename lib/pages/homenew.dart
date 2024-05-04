import 'package:apploook/pages/appetizerpage.dart';
import 'package:apploook/pages/burgerpage.dart';
import 'package:apploook/pages/chickenpage.dart';
import 'package:apploook/pages/combopage.dart';
import 'package:apploook/pages/pizzapage.dart';
import 'package:apploook/pages/spinnerpage.dart';
import 'package:flutter/material.dart';

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew> {
  int selectedTabIndex = 0;
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 10.0),
        child: Stack(
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 226, 225, 225),
              ),
            ),
            // Body Container
            Container(
              margin:
                  EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
            ),
            Positioned(
              top: 40,
              left: 15,
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
            Positioned(
              top: 140,
              left: 15,
              child: Container(
                child: Row(
                  children: [
                    Image.asset('images/sale50offburgers.png'),
                    SizedBox(width: 10.0),
                    Image.asset('images/sale50offburgers.png')
                  ],
                ),
              ),
            ),
            Positioned(
              top: 300.0,
              left: 0.0,
              right: 10.0,
              child: DefaultTabController(
                length: tabTitles.length,
                child: Material(
                  color: Colors.transparent,
                  child: TabBar(
                    isScrollable: true, // Enable horizontal scrolling
                    labelPadding: const EdgeInsets.symmetric(
                        horizontal: 10.0), // Adjust spacing
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
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255),
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
          ],
        ),
      ),
    );
  }
}

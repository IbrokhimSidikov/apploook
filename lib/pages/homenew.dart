import 'package:flutter/material.dart';

import 'data.dart';

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew> {
  int selectedTabIndex = 0;
  // final List<String> tabTitles = [
  //   'Combo',
  //   'Chicken',
  //   'Pizza',
  //   'Burgers',
  //   'Spinner',
  //   'Appetizers',
  // ];
  // final List<List<String>> itemsList = [
  //   // Add items for Tab 1 here
  //   ['Item 1.1', 'Item 1.2', 'Item 1.3'],
  //   // Add items for Tab 2 here
  //   ['Item 2.1', 'Item 2.2'],
  //   // Add items for Tab 3 here
  //   ['Item 2.1', 'Item 2.2'],
  //   ['Item 2.1', 'Item 2.2'],
  //   ['Item 2.1', 'Item 2.2'],
  //   ['Item 2.1', 'Item 2.2'], // Empty list for demonstration
  // ];
  final List<String> imagePaths = [
    'images/sale50offburgers.png',
    'images/sale50offburgers.png',
    'images/sale50offburgers.png',
  ];
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
                  // gradient: LinearGradient(
                  //   begin: Alignment.topLeft,
                  //   end: Alignment.bottomRight,
                  //   colors: [
                  //     Colors.white,
                  //     Colors.yellow,
                  //   ],
                  // ),
                  color: Color.fromARGB(255, 226, 225, 225),
                ),
              ),
              // Body Container
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 3),
                height: MediaQuery.of(context).size.height / 2,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
              ),
              Positioned(
                top: 40,
                left: 15,
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.black,
                  ), // Profile Icon
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
                      onTap: (index) =>
                          setState(() => selectedTabIndex = index),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: (MediaQuery.of(context).size.height / 3) +
                    50.0, // Adjust offset
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // Display selected list items
                      Visibility(
                        visible: selectedTabIndex >= 0 &&
                            selectedTabIndex < itemsList.length,
                        child: Expanded(
                          child: ListView.builder(
                            itemCount: itemsList[selectedTabIndex].length,
                            itemBuilder: (context, index) => ListTile(
                              title: Text(itemsList[selectedTabIndex][index]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
  }
}

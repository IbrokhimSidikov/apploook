import 'package:apploook/pages/details.dart';
import 'package:apploook/widget/widget_support.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool burger = false,
      pizza = false,
      cheeseburger = false,
      duetmaster = false,
      drumstick = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(210, 30, 30, 0.886),
      body: Container(
        margin: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hello ho`randa',
                  style: AppWidget.boldTextFieldStyle(),
                ),
                Container(
                  margin: EdgeInsets.only(right: 10.0),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: Colors.black,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 20.0,
            ),
            Text(
              'Mazali LoOoK',
              style: AppWidget.HeadlineTextFieldStyle(),
            ),
            Text(
              'Ta`tib korin, you`ll eat your fingers',
              style: AppWidget.LightTextFieldStyle(),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Container(
              margin: EdgeInsets.only(right: 20.0),
              child: showItem(),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Details()));
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      child: Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.asset(
                                'images/IMG_3238.png',
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                              Text(
                                "Chicky Burger",
                                style: AppWidget.semiboldTextFieldStyle(),
                              ),
                              const SizedBox(
                                height: 5.0,
                              ),
                              Text(
                                "Tasty and Crusty",
                                style: AppWidget.LightTextFieldStyle(),
                              ),
                              Text(
                                "27 000 UZS",
                                style: AppWidget.semiboldTextFieldStyle(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'images/IMG_3245.png',
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                            Text(
                              "CheeseBurger",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              "Cheese and Juicy",
                              style: AppWidget.LightTextFieldStyle(),
                            ),
                            Text(
                              "30 000 UZS",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'images/IMG_3311.png',
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                            Text(
                              "Duet Master",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              "Delicious Turkey",
                              style: AppWidget.LightTextFieldStyle(),
                            ),
                            Text(
                              "31 000 UZS",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15.0,
                  ),
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'images/IMG_3231.png',
                              height: 200,
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                            Text(
                              "Steak Pizza",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              "Juicy and Spicy Beef",
                              style: AppWidget.LightTextFieldStyle(),
                            ),
                            Text(
                              "59 000 UZS",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            Container(
              margin: EdgeInsets.only(right: 5.0),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Image.asset(
                        'images/IMG_3257.png',
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(width: 20.0),
                      Column(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              "Dinner Meal Normal",
                              style: AppWidget.semiboldTextFieldStyle(),
                            ),
                          ),
                          const SizedBox(
                            width: 20.0,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 2,
                            child: Text(
                              "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                              style: AppWidget.LightTextFieldStyle(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget showItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            burger = true;
            pizza = false;
            cheeseburger = false;
            duetmaster = false;
            drumstick = false;
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: burger ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'images/burger_icon.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                color: burger
                    ? Colors.white
                    : const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            burger = false;
            pizza = true;
            cheeseburger = false;
            duetmaster = false;
            drumstick = false;
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: pizza ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'images/pizza_icon.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                color: pizza
                    ? Colors.white
                    : const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            burger = false;
            pizza = false;
            cheeseburger = true;
            duetmaster = false;
            drumstick = false;
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: cheeseburger ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'images/salad.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                color: cheeseburger
                    ? Colors.white
                    : const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            burger = false;
            pizza = false;
            cheeseburger = false;
            duetmaster = false;
            drumstick = true;
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: drumstick ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'images/chicken_drumstick.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                color: drumstick
                    ? Colors.white
                    : const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            burger = false;
            pizza = false;
            cheeseburger = false;
            duetmaster = true;
            drumstick = false;
            setState(() {});
          },
          child: Material(
            elevation: 5.0,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: duetmaster ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'images/sodass.png',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
                color: duetmaster
                    ? Colors.white
                    : const Color.fromARGB(255, 80, 79, 79),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:apploook/widget/widget_support.dart';
import 'package:flutter/material.dart';

class ChickenPage extends StatefulWidget {
  const ChickenPage({super.key});

  @override
  State<ChickenPage> createState() => _ChickenPageState();
}

class _ChickenPageState extends State<ChickenPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3200.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "12 CHICKEN SET MIX",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 12pcs, Coca-Cola 1.5L, Coleslaw 4pcs",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3200.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "12 CHICKEN SET NORMAL",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 12pcs, Coca-Cola 1.5L, Coleslaw 4pcs",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3298.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "DINNER MEAL SPICY",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3257.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Dinner Meal Normal",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3257.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Dinner Meal Normal",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3257.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Dinner Meal Normal",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
          margin: EdgeInsets.only(
            right: 5.0,
          ),
          child: Material(
            elevation: 0.0,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  Image.asset(
                    'images/IMG_3257.png',
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10.0),
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Dinner Meal Normal",
                          style: AppWidget.semiboldTextFieldStyle(),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 2,
                        child: Text(
                          "Chicken 3pcs, Coca-cCola 0.5L, Coleslaw",
                          style: AppWidget.LightTextFieldStyle(),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Material(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFFF1F2F7),
                        elevation: 1.0,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          width: MediaQuery.sizeOf(context).width / 4,
                          child: Text('46000 UZS'),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

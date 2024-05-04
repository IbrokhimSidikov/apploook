import 'package:apploook/widget/widget_support.dart';
import 'package:flutter/material.dart';

class ComboPage extends StatefulWidget {
  const ComboPage({super.key});

  @override
  State<ComboPage> createState() => _ComboPageState();
}

class _ComboPageState extends State<ComboPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          //fooditem1
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
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
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
        ),
        SizedBox(
          height: 10,
        ),
        Container(
          //fooditem1
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
        ),
      ],
    ));
  }
}

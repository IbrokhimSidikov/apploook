import 'package:apploook/widget/widget_support.dart';
import 'package:flutter/material.dart';

class Details extends StatefulWidget {
  const Details({super.key});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  int a = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back_outlined, color: Colors.black)),
            Image.asset(
              "images/IMG_3238.png",
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              fit: BoxFit.cover,
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Chicky",
                      style: AppWidget.semiboldTextFieldStyle(),
                    ),
                    Text(
                      "Burger",
                      style: AppWidget.HeadlineTextFieldStyle(),
                    ),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    if (a > 1) {
                      --a;
                    }
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.remove, color: Colors.white),
                  ),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                Text(
                  a.toString(),
                  style: AppWidget.semiboldTextFieldStyle(),
                ),
                const SizedBox(
                  width: 20.0,
                ),
                GestureDetector(
                  onTap: () {
                    ++a;
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20.0,
            ),
            Container(
              height: 200,
              child: Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text(
                    //description for burger
                    "Погрузитесь в великолепное наслаждение с нашим аппетитным фастфудом - Куриный бургер. Погрузите зубы в хрустящий, золотисто-коричневый куриный котлет, искусно пряно приправленный и обжаренный до идеального состояния. Первый укус сопровождается приятным хрустом, сменяясь нежным, сочным курицей, обволакивающейся мягкой, поджаренной булочкой.",
                    style: AppWidget.LightTextFieldStyle(),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Row(
              children: [
                Text(
                  "Delivery Time",
                  style: AppWidget.LightTextFieldStyle(),
                ),
                const SizedBox(
                  width: 25.0,
                ),
                Icon(
                  Icons.alarm,
                  color: Colors.black54,
                ),
                const SizedBox(
                  width: 5.0,
                ),
                Text(
                  "30 min",
                  style: AppWidget.semiboldTextFieldStyle(),
                )
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price",
                        style: AppWidget.semiboldTextFieldStyle(),
                      ),
                      Text(
                        "28 000 UZS",
                        style: AppWidget.boldTextFieldStyle(),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width / 2,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          "Add to cart",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.0,
                              fontFamily: 'Poppins'),
                        ),
                        const SizedBox(
                          width: 30.0,
                        ),
                        Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(
                          width: 10.0,
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

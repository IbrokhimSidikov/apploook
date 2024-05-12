import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Checkout extends StatefulWidget {
  const Checkout({super.key});

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  int _selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 15.0,
                ),
                Text(
                  'Choose your order type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  width: 170,
                ),
                SvgPicture.asset('images/error_outline.svg')
              ],
            ),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 0
                          ? Color(0xffFEC700)
                          : Color(0xffF1F2F7),
                    ),
                  ),
                  child: Text(
                    'DELIVERY',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 1
                          ? Color(0xffFEC700)
                          : Color(0xffF1F2F7),
                    ),
                  ),
                  child: Text(
                    'SELF-PICKUP',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 2
                          ? Color(0xffFEC700)
                          : Color(0xffF1F2F7),
                    ),
                  ),
                  child: Text(
                    'CARHOP',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
            SizedBox(
              height: 15.0,
            ),
            Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(15.0),
              child: Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    Container(
                      height: 140,
                      width: 360,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.amberAccent),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text('data1'),
                      ),
                    ),
                    Container(
                      height: 140,
                      width: 360,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.amberAccent),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text('data2'),
                      ),
                    ),
                    Container(
                      height: 140,
                      width: 360,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.amberAccent),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text('data3'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 25.0,
            ),
            Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                width: 360,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('68 000 UZS'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('68 000 UZS'),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('68 000 UZS'),
                        ],
                      ),
                    ),
                  ],
                ),
              ), //price
            ),
            SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                  height: 15.0,
                ),
                Container(
                  height: 48,
                  width: 363,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      // Fixed country code widget
                      SizedBox(
                        width: 15.0,
                      ),
                      Text(
                        '+998',
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(width: 10.0),

                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType
                              .phone, // Set keyboard type for phone numbers
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 25.0,
                ),
                Text(
                  'Comments',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 15.0,
                ),
                Container(
                  height: 100,
                  width: 363,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder
                            .none, // Remove the default border of TextField
                      ),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 50.0,
            ),
            ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                  backgroundColor:
                      MaterialStatePropertyAll(const Color(0xffFEC700))),
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 15.0, bottom: 15.0, left: 125.0, right: 125.0),
                child: Text(
                  'Order',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.black),
                ),
              ),
            ),
            SizedBox(
              height: 25.0,
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: Text(
        'Checkout',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {},
        child: Container(
          child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          height: 25,
          width: 25,
        ),
      ),
    );
  }
}

import 'package:apploook/pages/cart.dart';
import 'package:apploook/models/view/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:apploook/cart_provider.dart';

class Checkout extends StatefulWidget {
  final int price;
  const Checkout({Key? key, required this.price}) : super(key: key);

  @override
  State<Checkout> createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  int _selectedIndex = 0;
  late int orderPrice = 0;
  String firstName = '';
  String phoneNumber = '';
  String clientComment = '';
  String clientCommentPhone = '';
  late String commented;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    _loadCustomerName();
    orderPrice = widget.price; // Initialize orderPrice in initState
  }

  Future<void> _loadPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      phoneNumber = prefs.getString('phoneNumber') ?? 'No number';
    });
  }

  num total = 0;

  Future<void> _loadCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Anonymous';
    });
  }

  void _updateCommented() {
    setState(() {
      commented = (clientComment.isNotEmpty ? clientComment + ', ' : '') +
          (clientCommentPhone.isNotEmpty
              ? 'Additional Number: ' + clientCommentPhone
              : '');
    });
  }

  String? selectedAddress;
  String? selectedBranch;

  List<String> branches = [
    'Loook Chilanzar',
    'Loook Yunusobod',
    'Loook Maksim Gorkiy',
    'Loook Boulevard',
  ];

  @override
  Widget build(BuildContext context) {
    var cartProvider = Provider.of<CartProvider>(context);

    List<String> orderItems = cartProvider.cartItems.map((item) {
      var itemTotal = item.quantity * item.product.price;
      total += itemTotal;

      return '${item.product.name}\n ${item.quantity} x ${NumberFormat('#,##0').format(item.product.price)} = ${NumberFormat('#,##0').format(item.quantity * item.product.price)} сум\n';
    }).toList();

    return Scaffold(
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20.0),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 15.0,
                ),
                Text(
                  'Choose your order type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  width: 170,
                ),
                // SvgPicture.asset('images/error_outline.svg')
              ],
            ),
            const SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 0
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                  ),
                  child: const Text(
                    'DELIVERY',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 1),
                  style: ButtonStyle(
                    backgroundColor:MaterialStateProperty.all(
                      _selectedIndex == 1
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                  ),
                  child: const Text(
                    'SELF-PICKUP',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      _selectedIndex == 2
                          ? const Color(0xffFEC700)
                          : const Color(0xffF1F2F7),
                    ),
                  ),
                  child: const Text(
                    'CARHOP',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 15.0,
            ),
            Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(15.0),
              child: Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MapScreen()));
                        if (result != null) {
                          setState(() {
                            selectedAddress = result;
                          });
                        }
                      },
                      child: Container(
                        height: 140,
                        width: 360,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Text(
                                  'Your Delivery Location!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 15.0,
                                    right: 15.0,
                                    bottom: 15.0,
                                    top: 10),
                                child: Text(
                                  selectedAddress ??
                                      'Manzilingizni Tanlang -->',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 140,
                      width: 360,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose branch to pick up',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 20),
                            ),
                            SizedBox(height: 10),
                            DropdownButton<String>(
                              value: selectedBranch,
                              hint: Text('Select Branch'),
                              isExpanded: true,
                              items: branches.map((String branch) {
                                return DropdownMenuItem<String>(
                                  value: branch,
                                  child: Text(branch),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedBranch = newValue;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 140,
                      width: 360,
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.amberAccent),
                        child: const Padding(
                          padding: EdgeInsets.all(15.0),
                          child: Text('data3'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Order Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                              '${NumberFormat('#,##0').format(orderPrice)} UZS'),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Delivery Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('Неизвестно'),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price :',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                              '${NumberFormat('#,##0').format(orderPrice)} UZS'),
                        ],
                      ),
                    ),
                  ],
                ),
              ), //price
            ),
            const SizedBox(
              height: 20,
            ),
            const SizedBox(
              height: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 15.0,
                ),
                Container(
                  height: 48,
                  width: 363,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
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
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            clientCommentPhone = value;
                            _updateCommented();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                const Text(
                  'Comments',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(
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
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        clientComment = value;
                        _updateCommented();
                      },
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 50.0,
            ),
            ElevatedButton(
              onPressed: () {
                sendOrderToTelegram(
                  selectedAddress, // address
                  "Неизвестно", // branchName
                  firstName, // name
                  phoneNumber, // phone
                  "Cash", // paymentType
                  commented,
                  orderItems, // orderItems
                  orderPrice, // total
                  41.313678, // latitude
                  69.242824, // longitude
                );
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(const Color(0xffFEC700)),
              ),
              child: const Padding(
                padding:
                    EdgeInsets.symmetric(vertical: 15.0, horizontal: 125.0),
                child: Text(
                  'Order',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 25.0,
            )
          ],
        ),
      ),
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text(
        'Checkout',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => const Cart()));
        },
        child: SizedBox(
          height: 25,
          width: 25,
          child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
        ),
      ),
    );
  }

  Future<void> sendOrderToTelegram(
    String? address,
    String branchName,
    String name,
    String phone,
    String paymentType,
    String comment,
    List orderItems,
    int total,
    double latitude,
    double longitude,
  ) async {
    try {
      // Format order details
      final orderDetails = "Адрес: $address\n" +
          "Филиал: $branchName\n" +
          "Имя: $name\n" +
          "Тел: $phone\n" +
          "Тип платежа: $paymentType\n\n" +
          "Заметка: ${comment.isEmpty ? 'Нет заметки' : comment}\n\n" +
          "🛒 <b>Корзина:</b>\n${orderItems.join("\n")}\n\n" +
          "<b>Итого:</b> ${NumberFormat('#,##0').format(total).toString()} сум\n\n" +
          "-----------------------\n" +
          "Источник: Mobile App\n";

      final encodedOrderDetails = Uri.encodeQueryComponent(orderDetails);

      final telegramDebUrl =
          "https://api.sievesapp.com/v1/public/make-post?chat_id=-1002074915184&text=$encodedOrderDetails&latitude=$latitude&longitude=$longitude";

      // Send order details to Telegram
      final response = await http.get(
        Uri.parse(telegramDebUrl),
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode != 200) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to send order');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}

import 'dart:convert';
import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  final String orderId;
  final String branchName;
  final List<Map<String, dynamic>> items;
  final double totalPrice;
  final String orderType;
  final String status;
  final DateTime orderTime;
  final String? customerName;
  final String? phoneNumber;
  final String? paymentType;

  Order({
    required this.orderId,
    required this.branchName,
    required this.items,
    required this.totalPrice,
    required this.orderType,
    required this.status,
    required this.orderTime,
    this.customerName,
    this.phoneNumber,
    this.paymentType,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'branchName': branchName,
        'items': items,
        'totalPrice': totalPrice,
        'orderType': orderType,
        'status': status,
        'orderTime': orderTime.toIso8601String(),
        'customerName': customerName,
        'phoneNumber': phoneNumber,
        'paymentType': paymentType,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId'],
        branchName: json['branchName'],
        items: List<Map<String, dynamic>>.from(json['items']),
        totalPrice: (json['totalPrice'] is int)
            ? (json['totalPrice'] as int).toDouble()
            : json['totalPrice'] as double,
        orderType: json['orderType'],
        status: json['status'],
        orderTime: DateTime.parse(json['orderTime']),
        customerName: json['customerName'],
        phoneNumber: json['phoneNumber'],
        paymentType: json['paymentType'],
      );

  static Future<void> saveOrder(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final orderStrings = prefs.getStringList('orders') ?? [];

    // Convert the new order to JSON string
    final orderJson = jsonEncode(order.toJson());

    // Add the new order to the beginning of the list
    orderStrings.insert(0, orderJson);

    // Save the updated list
    await prefs.setStringList('orders', orderStrings);
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final orderStrings = prefs.getStringList('orders') ?? [];
    setState(() {
      _orders =
          orderStrings.map((str) => Order.fromJson(jsonDecode(str))).toList();
    });
  }

  Future<void> _notifyArrival(Order order) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrival Confirmed'),
        content: Text(
            'Thank you for letting us know you\'ve arrived for order #${order.orderId}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderId}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                order.status.toUpperCase(),
                style: TextStyle(
                  color: order.status == 'preparing'
                      ? Colors.orange
                      : order.status == 'ready'
                          ? Colors.green
                          : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: ${order.orderTime.toString().substring(0, 16)}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text('Branch: ${order.branchName}'),
          Text('Type: ${order.orderType}'),
          if (order.paymentType != null) Text('Payment: ${order.paymentType}'),
          if (order.customerName != null)
            Text('Customer: ${order.customerName}'),
          if (order.phoneNumber != null) Text('Phone: ${order.phoneNumber}'),
          const Divider(),
          ...order.items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('\$${item['price']}'),
                      ],
                    ),
                  ))
              .toList(),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${order.totalPrice}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (order.status == 'preparing' &&
              order.orderType.toLowerCase() == 'carhop') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _notifyArrival(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFEC700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'I\'ve Arrived',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F2F7),
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).notifications,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/homeNew');
          },
          child: SizedBox(
            height: 25,
            width: 25,
            child: SvgPicture.asset('images/keyboard_arrow_left.svg'),
          ),
        ),
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('images/noNotifications.svg'),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noNotifications,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
            ),
    );
  }
}

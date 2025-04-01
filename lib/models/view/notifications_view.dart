import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:apploook/providers/notification_provider.dart';
import 'package:http/http.dart' as http;
import 'package:apploook/services/socket_service.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String?
      updatingOrderId; // Add this line to track which order is being updated
  static const int pageSize = 10;
  int currentPage = 0;
  bool _hasShownArrivedHint = false;
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    // _socketService.initSocket();
    _loadOrders();
    // Mark notifications as read when viewing
    Provider.of<NotificationProvider>(context, listen: false).markAllAsRead();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showArrivedHintIfNeeded();
    });
  }

  void _showArrivedHintIfNeeded() {
    if (!_hasShownArrivedHint) {
      _hasShownArrivedHint = true;
      // Show the hint after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).arrivedButtonHint,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      });
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final savedOrders = prefs.getStringList('carhop_orders') ?? [];

    setState(() {
      orders = savedOrders
          .map((order) => jsonDecode(order) as Map<String, dynamic>)
          .toList()
        ..sort((a, b) => DateTime.parse(b['timestamp'])
            .compareTo(DateTime.parse(a['timestamp'])));
      isLoading = false;
    });
  }

  Future<void> updateOrderStatus(String orderId) async {
    setState(() {
      updatingOrderId = orderId;
    });

    final String url =
        'https://app.sievesapp.com/v1/order/$orderId?isDelever=1';

    final Map<String, dynamic> requestBody = {
      "id": orderId,
      "customer_arrived": 1,
      "is_sync": 0,
    };

    const String bearerToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJiZWFyZXIiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.fo1-6HkjCqoQ_m4cCO6laUgHHBBqktz0SAgmOi6axqQ";
    const String xApiKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4ODk4ODkiLCJuYW1lIjoiZGVsZXZlciIsImlhdCI6ODg5ODg5fQ.twqu6OB88osWslaoMr6UDH8RNuSX095LlEf0OVdDglY";

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'x-api': xApiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        print("Order status updated successfully!");
      } else {
        print("Failed to update order status: ${response.body}");
      }
    } catch (e) {
      print("Error updating order status: $e");
    } finally {
      if (mounted) {
        setState(() {
          updatingOrderId = null;
        });
      }
    }
  }

  // void _handleArrival(String orderId) {
  //   print('🚀 _handleArrival called with orderId: $orderId');
  //   try {
  //     final parsedOrderId = int.parse(orderId);
  //     print('✅ Successfully parsed orderId to int: $parsedOrderId');

  //     _socketService.notifyArrival(parsedOrderId);
  //     print(
  //         '📤 Notification sent to socket service for orderId: $parsedOrderId');

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(AppLocalizations.of(context).arrivalNotificationSent),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //     print('✨ SnackBar shown to user for orderId: $parsedOrderId');
  //   } catch (e) {
  //     print('❌ Error in _handleArrival: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error: ${e.toString()}'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  List<Map<String, dynamic>> get paginatedOrders {
    final startIndex = currentPage * pageSize;
    final endIndex = (currentPage + 1) * pageSize;
    if (startIndex >= orders.length) return [];
    return orders.sublist(startIndex, endIndex.clamp(0, orders.length));
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
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
              : NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo is ScrollEndNotification &&
                        scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                      // Load more when reaching the end if there are more orders
                      if ((currentPage + 1) * pageSize < orders.length) {
                        setState(() {
                          currentPage++;
                        });
                      }
                    }
                    return true;
                  },
                  child: ListView.builder(
                    // Only show loading indicator if we have more items to load
                    itemCount: paginatedOrders.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final order = paginatedOrders[index];
                      final timestamp = DateTime.parse(order['timestamp']);
                      final formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm').format(timestamp);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Order Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${order['id']}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      updateOrderStatus(order['id'].toString());
                                    },
                                    child: Tooltip(
                                      message: AppLocalizations.of(context)
                                          .arrivedButtonTooltip,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEC700),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (updatingOrderId ==
                                                order['id'].toString())
                                              const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.black,
                                                  ),
                                                ),
                                              )
                                            else
                                              const Icon(
                                                Icons.directions_car,
                                                size: 18,
                                                color: Colors.black,
                                              ),
                                            const SizedBox(width: 6),
                                            Text(
                                              AppLocalizations.of(context)
                                                  .arrived,
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Order Items
                            if (order['orderItems'] != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    ...List<Widget>.from(
                                      (order['orderItems'] as List)
                                          .map((item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${item['quantity']}x',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '${item['name']}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      '${(item['price'] * item['quantity']).toStringAsFixed(0)} UZS',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context).totalAmount,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${order['paid']} UZS',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  @override
  void dispose() {
    _socketService.socket.dispose();
    super.dispose();
  }
}

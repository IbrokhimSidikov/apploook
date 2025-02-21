import 'package:apploook/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:apploook/providers/notification_provider.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  static const int pageSize = 10;
  int currentPage = 0;
  bool _hasShownArrivedHint = false;

  @override
  void initState() {
    super.initState();
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
                                      // You can implement the onTap functionality
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
}

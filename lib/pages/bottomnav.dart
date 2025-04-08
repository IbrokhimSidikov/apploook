import 'package:apploook/pages/home.dart';
import 'package:apploook/pages/notification.dart';
import 'package:apploook/pages/order.dart';
import 'package:apploook/pages/profile.dart';
import 'package:apploook/pages/wallet.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int currentTabIndex = 0;

  late List<Widget> pages;
  late Widget currentPage;
  late Home homepage;
  late Profile profile;
  late Order order;
  late Wallet wallet;
  late NotificationPage notificationPage;

  @override
  void initState() {
    homepage = Home();
    order = Order();
    profile = Profile();
    wallet = Wallet();
    notificationPage = NotificationPage();
    pages = [homepage, order, notificationPage, wallet, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Scaffold(
          bottomNavigationBar: CurvedNavigationBar(
            height: 65,
            backgroundColor: const Color.fromRGBO(210, 30, 30, 0.886),
            color: Colors.yellow,
            animationDuration: Duration(milliseconds: 500),
            onTap: (int index) {
              setState(() {
                currentTabIndex = index;
              });
            },
            items: [
              Icon(
                Icons.home_outlined,
                color: Colors.black,
              ),
              Icon(
                Icons.shopping_bag_outlined,
                color: Colors.black,
              ),
              Stack(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: Colors.black,
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              Icon(
                Icons.wallet_outlined,
                color: Colors.black,
              ),
              Icon(
                Icons.person_outlined,
                color: Colors.black,
              ),
            ],
          ),
          body: pages[currentTabIndex],
        );
      },
    );
  }
}

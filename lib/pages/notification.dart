import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<NotificationItem> notifications = [
    NotificationItem(
      title: 'Order Delivered',
      message: 'Your order #123456 has been delivered successfully',
      time: '2 hours ago',
      type: NotificationType.success,
      isRead: false,
    ),
    NotificationItem(
      title: 'New Offer',
      message: 'Get 20% off on your next order! Limited time offer',
      time: '5 hours ago',
      type: NotificationType.promotion,
      isRead: true,
    ),
    NotificationItem(
      title: 'Order Update',
      message: 'Your order #123457 is out for delivery',
      time: '1 day ago',
      type: NotificationType.info,
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Add clear all functionality
            },
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_outlined,
                    size: 70,
                    color: Colors.black12,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(notification: notification);
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const _NotificationCard({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : const Color.fromARGB(255, 255, 215, 56).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Handle notification tap
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIcon(type: notification.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            notification.time,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final NotificationType type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case NotificationType.success:
        iconData = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case NotificationType.promotion:
        iconData = Icons.local_offer_outlined;
        iconColor = const Color.fromARGB(255, 255, 215, 56);
        break;
      case NotificationType.info:
        iconData = Icons.info_outline;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.isRead,
  });
}

enum NotificationType {
  success,
  promotion,
  info,
}

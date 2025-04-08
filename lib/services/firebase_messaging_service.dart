import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../providers/notification_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This will be called when the app is in the background or terminated
  debugPrint("Handling a background message: ${message.messageId}");
  // We'll load and update notifications when app is opened
}

class FirebaseMessagingService {
  final NotificationProvider notificationProvider;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  FirebaseMessagingService(this.notificationProvider) {
    _initMessaging();
  }

  Future<void> _initMessaging() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for iOS devices
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get any messages that caused the app to open from a terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle messages when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    notificationProvider.addNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      messageId: message.messageId ?? '',
    );
  }
}

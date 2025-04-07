import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    print('🔔 Initializing Firebase Messaging...');

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 Notifications authorized');

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      print('🔔 Foreground notification options set');

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iOSSettings =
          DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iOSSettings,
      );
      await _localNotifications.initialize(initSettings);
      print('🔔 Local notifications initialized');

      String? token = await _fcm.getToken();
      print('🔔 FCM Token: $token');

      String? apnsToken = await _fcm.getAPNSToken();
      print('🔔 APNS Token: $apnsToken');

      _fcm.onTokenRefresh.listen((token) {
        print('🔔 New Token: $token');
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      print('🔔 Foreground message handler set');

      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      print('🔔 Background message handler set');
    } else {
      print(
          '❌ Notification permissions denied: ${settings.authorizationStatus}');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 Received foreground message:');
    print('🔔 Message ID: ${message.messageId}');
    print('🔔 Title: ${message.notification?.title}');
    print('🔔 Body: ${message.notification?.body}');
    print('🔔 Data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      try {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data.toString(),
        );
        print('🔔 Local notification displayed successfully');
      } catch (e) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    print('🔔 Handling background message:');
    print('🔔 Message ID: ${message.messageId}');
    print('🔔 Title: ${message.notification?.title}');
    print('🔔 Body: ${message.notification?.body}');
    print('🔔 Data: ${message.data}');
  }
}

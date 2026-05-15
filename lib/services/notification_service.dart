import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  late NotificationProvider _notificationProvider;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void setProvider(NotificationProvider provider) {
    _notificationProvider = provider;
  }

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

      // Get both FCM and APNS tokens
      String? token = await _fcm.getToken();
      String? apnsToken = await _fcm.getAPNSToken();

      print('🔔 FCM Token for testing: $token'); // Use this token for testing
      print('🔔 APNS Token: $apnsToken');

      // Subscribe to a test topic for development
      await FirebaseMessaging.instance.subscribeToTopic('dev_test');
      print('🔔 Subscribed to dev_test topic');

      _fcm.onTokenRefresh.listen((newToken) {
        print('🔔 New Token for testing: $newToken');
        // You might want to send this token to your server
      });

      // Get initial messages that opened the app
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleMessage);
      print('🔔 Foreground message handler set');

      // Handle when app is opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      print('🔔 Background message handler set');
    } else {
      print(
          '❌ Notification permissions denied: ${settings.authorizationStatus}');
    }
  }

  /// Shows a local notification immediately (independent of Firebase).
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      await _localNotifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      print('🔔 Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  void _handleMessage(RemoteMessage message) async {
    print('🔔 Handling message:');
    print('🔔 Message ID: ${message.messageId}');
    print('🔔 Title: ${message.notification?.title}');
    print('🔔 Body: ${message.notification?.body}');

    // Add to provider
    _notificationProvider.addNotification(
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      messageId: message.messageId ?? '',
    );

    // Show local notification
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
}

// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       const DarwinInitializationSettings iOSSettings =
//           DarwinInitializationSettings();
//       const InitializationSettings initSettings = InitializationSettings(
//         android: androidSettings,
//         iOS: iOSSettings,
//       );
//       await _localNotifications.initialize(initSettings);

//       String? token = await _fcm.getToken();
//       print('FCM Token: $token');

//       _fcm.onTokenRefresh.listen((token) {
//         print('New Token: $token');
//       });

//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//       FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
//     }
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     print('Handling foreground message: ${message.messageId}');

//     RemoteNotification? notification = message.notification;
//     AndroidNotification? android = message.notification?.android;

//     if (notification != null && android != null) {
//       await _localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'high_importance_channel',
//             'High Importance Notifications',
//             importance: Importance.max,
//             priority: Priority.high,
//           ),
//         ),
//         payload: message.data.toString(),
//       );
//     }
//   }

//   void _handleBackgroundMessage(RemoteMessage message) {
//     print('Handling background message: ${message.messageId}');
//   }
// }
import 'package:apploook/api/firebase_api.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/consent_screen.dart';
import 'package:apploook/models/view/notifications_view.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/pages/onboard.dart';
import 'package:apploook/pages/signin.dart';
import 'package:apploook/widget/custom_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_delegate.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseApi().initNotifications();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // print("FCMToken $fcmToken");
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  runApp(MyLoaderApp());
}

class MyLoaderApp extends StatefulWidget {
  @override
  _MyLoaderAppState createState() => _MyLoaderAppState();
}

class _MyLoaderAppState extends State<MyLoaderApp> {
  bool? _acceptedPrivacyPolicy;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('accepted_privacy_policy'); //to check the privacy policy
    _acceptedPrivacyPolicy = prefs.getBool('accepted_privacy_policy');
    CachedNetworkImage.logLevel = CacheManagerLogLevel.warning;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 100;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _acceptedPrivacyPolicy == true
          ? const MyApp()
          : ConsentScreen(onAccept: () {
              runApp(
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (_) => CartProvider()),
                    ChangeNotifierProvider(create: (_) => LocaleProvider()),
                    ChangeNotifierProvider(
                        create: (_) => NotificationProvider()),
                  ],
                  child: const MyApp(),
                ),
              );
            }),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'LOOOK MOBILE',
          theme: ThemeData(
            fontFamily: 'Poppins',
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontFamily: 'Poppins'),
              bodyMedium: TextStyle(fontFamily: 'Poppins'),
              displayLarge: TextStyle(fontFamily: 'Poppins'),
              displayMedium: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
          // Add localization support
          locale: localeProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('uz'),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: InitialScreen(),
          routes: {
            '/homeNew': (context) => HomeNew(),
            '/signin': (context) => SignIn(),
            '/cart': (context) => Cart(),
            '/checkout': (context) => Checkout(),
            '/onboard': (context) => Onboard(),
            '/notificationsView': (context) => NotificationsView(),
          },
        );
      },
    );
  }
}

class InitialScreen extends StatefulWidget {
  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      return '/homeNew';
    } else {
      return '/onboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, snapshot.data!);
          });
          return Scaffold();
        }
      },
    );
  }
}

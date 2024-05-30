import 'dart:math';

import 'package:apploook/api/firebase_api.dart';
import 'package:apploook/cart_provider.dart';
import 'package:apploook/pages/cart.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:apploook/pages/login.dart';
import 'package:apploook/pages/onboard.dart';
import 'package:apploook/pages/signin.dart';
import 'package:apploook/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apploook/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  // FirebaseApi().initNotifications();
  // await FirebaseMessaging.instance.setAutoInitEnabled(true);
  // final fcmToken = await FirebaseMessaging.instance.getToken();
  // print("FCMToken $fcmToken");
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          displayLarge: TextStyle(fontFamily: 'Poppins'),
          displayMedium: TextStyle(fontFamily: 'Poppins'),
        ),
      ),
      home: InitialScreen(),
      routes: {
        '/homeNew': (context) => HomeNew(),
        '/signin': (context) => SignIn(),
        '/cart': (context) => Cart(),
        '/checkout': (context) => Checkout(),
        '/onboard': (context) => Onboard(),
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
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

void main() {
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
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // Define the default font family for the entire app
        fontFamily: 'Poppins',

        // Optionally, you can customize specific text styles
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Poppins'),
          bodyMedium: TextStyle(fontFamily: 'Poppins'),
          displayLarge: TextStyle(fontFamily: 'Poppins'),
          displayMedium: TextStyle(fontFamily: 'Poppins'),
          // Add other text styles as needed
        ),
      ),
      // home: Onboard(),
      initialRoute: '/',
      routes: {
        '/': (context) => Onboard(),
        '/homeNew': (context) => HomeNew(),
        '/signin':(context)=>SignIn(),
        '/cart':(context)=>Cart(),
        '/checkout':(context)=>Checkout(),
        
      },
    
    );
  }
}

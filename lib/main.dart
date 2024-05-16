import 'package:apploook/models/view/map_screen.dart';
import 'package:apploook/pages/checkout.dart';
import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        home: MapScreen());
  }
}
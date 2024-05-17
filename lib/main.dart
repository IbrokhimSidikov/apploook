import 'package:apploook/pages/homenew.dart';
import 'package:flutter/material.dart';
import 'package:apploook/models/view/map_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: HomeNew(),
    );
  }
}

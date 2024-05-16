import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapScreen extends StatefulWidget {
 const MapScreen({Key? key}) : super(key: key);

 @override
 State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
final mapControllerCompleter = Completer<YandexMapController>();
 @override
 Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(title: Text('ishlavotti'),centerTitle: true,),
    body: YandexMap(onMapCreated: (controller) {
         mapControllerCompleter.complete(controller);
       },),
   );
 }}
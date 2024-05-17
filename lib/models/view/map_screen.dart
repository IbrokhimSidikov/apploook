import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapControllerCompleter = Completer<YandexMapController>();
  YandexMapController? mapController;
  Point? tappedLocation;

  final bool nightModeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Pick Your Location',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true),
      body: Stack( // Use Stack to overlay marker on the map
        children: [
          Expanded(
            child: YandexMap(
              mapType: MapType.vector,
              nightModeEnabled: nightModeEnabled,
              cameraBounds: const CameraBounds(
                minZoom: 1,
                maxZoom: 20,
                latLngBounds: BoundingBox(
                  northEast: Point(
                    latitude: 41.4245,
                    longitude: 69.3567,
                  ),
                  southWest: Point(
                    latitude: 41.2,
                    longitude: 69.1,
                  ),
                ),
              ),
              onMapLongTap: (Point argument) {
                setState(() {
                  tappedLocation = argument;
                });
              },
            ),
          ),
          if (tappedLocation != null) // Conditionally display marker
            Positioned(
              top: screenHeight(context) / 2 - 20, // Adjust marker position
              left: screenWidth(context) / 2 - 10, // Adjust marker position
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30.0,
              ),
            ),
        ],
      ),
      bottomNavigationBar: tappedLocation != null
          ? Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text(
                    'Latitude: ${tappedLocation!.latitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  Spacer(),
                  Text(
                    'Longitude: ${tappedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
}

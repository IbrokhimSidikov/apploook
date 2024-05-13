// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart';

// class MapScreen extends StatefulWidget {
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   YandexMapController? _mapController;
//   bool _locationPermissionGranted = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkLocationPermission();
//   }

//   Future<void> _checkLocationPermission() async {
//     // ... code to check and request location permission
//   }

  
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('User Location'),
//       ),
//       body: Stack(
//         children: [
//           YandexMap(
//             onMapCreated: (YandexMapController controller) =>
//                 _mapController = controller,
//           ),
//           Center(
//             child: ElevatedButton(
//               onPressed: _locationPermissionGranted ? _getUserLocation : null,
//               child: Text('Show My Location'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Future<void> _getUserLocation() async {
//     if (_locationPermissionGranted) {
//       final position = await Geolocator.getCurrentPosition();
//       final cameraPosition = CameraPosition(
//         target:
//             Point(latitude: position.latitude, longitude: position.longitude),
//         zoom: 15.0, // Adjust zoom level as needed
//       );
//       await _mapController?.move(
//         cameraPosition,
//         new Animation(
//           type: AnimationType.SMOOTH,
//           duration: Duration(milliseconds: 500),
//         ),
//       ); // Added animation
//     } else {
//       // Handle cases where location permission is denied
//       print('Location permission denied');
//     }
//   }
// }

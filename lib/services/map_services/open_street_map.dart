import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double?> getDistanceInMeters({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) async {
  const String apiKey =
      '5b3ce3597851110001cf6248951970ee49bc442b98e223b2c04b83cb';
  const String baseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';

  // For OpenRouteService API, we need to convert from lat/long to long/lat format
  final response = await http.post(Uri.parse(baseUrl),
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'coordinates': [
          [startLng, startLat], // Convert to [longitude, latitude] for API
          [endLng, endLat],     // Convert to [longitude, latitude] for API
        ]
      }));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('API Response: ${response.body}');
    // Extract distance from the routes summary section
    final distanceInMeters = data['routes'][0]['summary']['distance'];
    return distanceInMeters / 1000; // Convert to kilometers
  } else {
    print('Failed to get the distance, ${response.statusCode}');
    print('Response body: ${response.body}');
    return null;
  }
}

List<Map<String, double>> branches = [
  {'lat': 41.313691, 'lng': 69.244055},
  {'lat': 41.346379, 'lng': 69.206030},
  {'lat': 41.366780, 'lng': 69.293222},
  {'lat': 41.326421, 'lng': 69.327426},
  {'lat': 41.276810, 'lng': 69.201880}
];

Future<Map<String, dynamic>?> findNearestBranch(
    double clientLat, double clientLng) async {
  double shortestDistance = double.infinity;
  Map<String, dynamic>? nearestBranch;
  
  // Print client coordinates for debugging
  print('Client coordinates: Lat: $clientLat, Long: $clientLng');

  for (var branch in branches) {
    // Using consistent lat/long parameter order throughout the code
    final distance = await getDistanceInMeters(
      startLat: clientLat,
      startLng: clientLng,
      endLat: branch['lat']!,
      endLng: branch['lng']!,
    );
    
    print('Branch at Lat: ${branch['lat']}, Long: ${branch['lng']}, Distance: ${distance ?? 'calculation failed'} km');

    if (distance != null && distance < shortestDistance) {
      shortestDistance = distance;
      nearestBranch = {
        'lat': branch['lat'],
        'lng': branch['lng'],
        'distance': distance,
      };
    }
  }

  return nearestBranch;
}

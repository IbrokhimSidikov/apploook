import 'dart:convert';
import 'package:http/http.dart' as http;

// Delivery fee calculation constants
const int baseDeliveryFee = 12000;

final List<Map<String, dynamic>> deliveryFeeRules = [
  {'from': 2, 'to': 3, 'fee': 14000},
  {'from': 3, 'to': 4, 'fee': 16000},
  {'from': 4, 'to': 5, 'fee': 18000},
  {'from': 5, 'to': 6, 'fee': 20000},
  {'from': 6, 'to': 7, 'fee': 22000},
  {'from': 7, 'to': 8, 'fee': 24000},
  {'from': 8, 'to': 9, 'fee': 26000},
  {'from': 9, 'to': 10, 'fee': 28000},
  {'from': 10, 'to': 11, 'fee': 30000},
  {'from': 11, 'to': 12, 'fee': 32000},
  {'from': 12, 'to': 13, 'fee': 34000},
  {'from': 13, 'to': 14, 'fee': 36000},
  {'from': 14, 'to': 15, 'fee': 38000},
  {'from': 15, 'to': 16, 'fee': 40000},
  {'from': 16, 'to': 17, 'fee': 42000},
  {'from': 17, 'to': 18, 'fee': 44000},
];

// Calculate delivery fee based on distance in kilometers
int calculateDeliveryFee(double distanceKm) {
  // If distance is less than 2 km, use base fee
  if (distanceKm < 2) {
    return baseDeliveryFee;
  }
  
  // Check each rule to find the appropriate fee
  for (var rule in deliveryFeeRules) {
    if (distanceKm >= rule['from'] && distanceKm < rule['to']) {
      return rule['fee'];
    }
  }
  
  // If distance is beyond our rules, use the highest fee + extra
  if (distanceKm >= 18) {
    // Add 2000 for each km beyond 18
    int extraKm = (distanceKm - 18).ceil();
    return 44000 + (extraKm * 2000);
  }
  
  // Fallback to base fee (shouldn't reach here)
  return baseDeliveryFee;
}

Future<double?> getDistanceInMeters({
  required double startLat,
  required double startLng,
  required double endLat,
  required double endLng,
}) async {
  // OSRM API doesn't require an API key for the public demo server
  // Using the OSRM demo server - for production, consider hosting your own OSRM instance
  final String baseUrl = 'https://router.project-osrm.org/route/v1/car';

  // OSRM uses longitude,latitude format in the URL path
  // Format: /route/v1/car/{longitude},{latitude};{longitude},{latitude}
  final String coordinates = '$startLng,$startLat;$endLng,$endLat';
  final String url =
      '$baseUrl/$coordinates?annotations=false&geometries=polyline6&overview=false&steps=false';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('OSRM API Response: ${response.body}');

      // Check if the route was found
      if (data['code'] == 'Ok' &&
          data['routes'] != null &&
          data['routes'].isNotEmpty &&
          data['routes'][0]['legs'] != null &&
          data['routes'][0]['legs'].isNotEmpty) {
        // Extract distance from the legs section (in meters)
        final distanceInMeters = data['routes'][0]['legs'][0]['distance'];
        return distanceInMeters / 1000; // Convert to kilometers
      } else {
        print('Route not found or invalid response format');
        return null;
      }
    } else {
      print('Failed to get the distance, ${response.statusCode}');
      print('Response body: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Error calling OSRM API: $e');
    return null;
  }
}

List<Map<String, double>> branches = [
  {'lng': 69.244055, 'lat': 41.313691}, //Boulevard
  {'lng': 69.206030, 'lat': 41.346379}, //Beruniy
  {'lng': 69.293222, 'lat': 41.366780}, //Yunusobod
  {'lng': 69.327426, 'lat': 41.326421}, //Maksim Gorkiy
  {'lng': 69.201888, 'lat': 41.276812}, //Chilanzar
  {'lng': 69.060309, 'lat': 41.120050}, //Yangiyol
];

Future<Map<String, dynamic>?> findNearestBranch(
    double clientLat, double clientLng) async {
  double shortestDistance = double.infinity;
  Map<String, dynamic>? nearestBranch;

  // Print client coordinates for debugging
  print('Client coordinates: Lat: $clientLat, Long: $clientLng');

  for (var branch in branches) {
    // Calculate distance from branch to client (branch is start, client is destination)
    final distance = await getDistanceInMeters(
      startLat: branch['lat']!,  // Branch latitude as starting point
      startLng: branch['lng']!,  // Branch longitude as starting point
      endLat: clientLat,        // Client latitude as destination
      endLng: clientLng,        // Client longitude as destination
    );

    print(
        'From Branch (${branch['lat']}, ${branch['lng']}) to Client: ${distance ?? 'calculation failed'} km');

    if (distance != null && distance < shortestDistance) {
      shortestDistance = distance;
      // Calculate delivery fee based on distance
      int deliveryFee = calculateDeliveryFee(distance);
      
      nearestBranch = {
        'lat': branch['lat'],
        'lng': branch['lng'],
        'distance': distance,
        'deliveryFee': deliveryFee,
      };
    }
  }

  return nearestBranch;
}

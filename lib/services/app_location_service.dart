import 'package:apploook/models/app_lat_long.dart';
import 'package:geolocator/geolocator.dart';

abstract class AppLocation {
  Future<AppLatLong> getCurrentLocation();

  Future<bool> requestPermission();

  Future<bool> checkPermission();
  
  Future<bool> isPermissionPermanentlyDenied();
}

class LocationService implements AppLocation {
  final defLocation = const TashkentLocation();
  
  @override
  Future<AppLatLong> getCurrentLocation() async {
    // getCurrentPosition has no deadline of its own and can wait indefinitely
    // without a GPS fix (indoors, weak signal), which left the menu unloaded.
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      return AppLatLong(lat: pos.latitude, long: pos.longitude);
    } catch (_) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return AppLatLong(lat: last.latitude, long: last.longitude);
        }
      } catch (_) {}
      return defLocation;
    }
  }

  @override
  Future<bool> requestPermission() {
    return Geolocator.requestPermission()
        .then((value) =>
            value == LocationPermission.always ||
            value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }

  @override
  Future<bool> checkPermission() {
    return Geolocator.checkPermission()
        .then((value) =>
            value == LocationPermission.always ||
            value == LocationPermission.whileInUse)
        .catchError((_) => false);
  }
  
  @override
  Future<bool> isPermissionPermanentlyDenied() {
    return Geolocator.checkPermission()
        .then((value) => value == LocationPermission.deniedForever)
        .catchError((_) => false);
  }
}

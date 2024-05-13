class AppLatLong {
  final double lat;
  final double long;

  const AppLatLong({
    required this.lat,
    required this.long,
  });
}

class TashkentLocation extends AppLatLong {
  const TashkentLocation({
    super.lat = 41.311081,
    super.long = 69.240562,
  });
}

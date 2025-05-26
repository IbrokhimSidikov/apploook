import 'package:url_launcher/url_launcher.dart';

class BranchLocations {
  static final Map<String, String> branchCoordinates = {
    "Loook Boulevard": "41.313691, 69.244055",
    "Loook Beruniy": "41.346379, 69.206030",
    "Loook Yunusobod": "41.366780, 69.293222",
    "Loook Maksim Gorkiy": "41.326421, 69.327426",
    "Loook Chilanzar": "41.276810, 69.201880",
    "Loook YangiYo'l": "41.120050, 69.060309",
  };

  static String? getBranchCoordinates(String? branch) {
    return branch != null && branchCoordinates.containsKey(branch)
        ? branchCoordinates[branch]
        : null;
  }

  static Future<void> openMap(String? branch) async {
    final coordinates = getBranchCoordinates(branch);
    if (coordinates != null) {
      final url =
          "https://www.google.com/maps/search/?api=1&query=$coordinates";
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw "Could not open the map.";
      }
    }
  }
}

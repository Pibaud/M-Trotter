import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AmenitiesService {
  late Map<String, String> _amenities = {};

  AmenitiesService();

  Future<void> loadAmenities() async {
    String data = await rootBundle.loadString('assets/amenities.json');
    _amenities = json.decode(data).cast<String, String>();
  }

  List<String> searchAmenities(String query) {
    if (_amenities.isEmpty || query.isEmpty) return [];
    query = query.toLowerCase();
    return _amenities.keys
        .where((key) => key.toLowerCase().startsWith(query))
        .toList();
  }

  String getRealAmenityName(String amenity) {
    return _amenities[amenity] ?? '';
  }
}

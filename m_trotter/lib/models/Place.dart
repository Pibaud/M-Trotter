import 'package:logger/logger.dart';
import '../utils/GlobalData.dart'; // Import de vos données globales

class Place {
  static final logger = Logger();
  final int id;
  final String placeTable;
  final String name;
  final double latitude;
  final double longitude;
  final int houseNumber;
  final double avgStars;
  final int numReviews;
  final Map<String, String> tags;
  final String? amenity;

  Place(
      {required this.id,
      required this.placeTable,
      required this.name,
      required this.tags,
      required this.amenity,
      required this.latitude,
      required this.longitude,
      required this.houseNumber,
      required this.avgStars,
      required this.numReviews});

  static Place fromJson(Map<String, dynamic> json) {
    // Traitement des tags
    Map<String, String> tags = {};
    if (json['tags'] != null && json['tags'] is String) {
      for (String entry in json['tags'].split(", ")) {
        List<String> keyValue = entry.split("=>");
        if (keyValue.length == 2) {
          tags[keyValue[0].replaceAll('"', '').trim()] =
              keyValue[1].replaceAll('"', '').trim();
        }
      }
    }

    String? foundAmenity;
    String? amenityValue = json['amenity'];
    if (amenityValue == null) {
      foundAmenity = "Inconnu";
    } else {
      foundAmenity = GlobalData.getAmenityKey(amenityValue);
    }

    return Place(
        id: int.parse(json['id']),
        placeTable: json['place_table'],
        name: json['name'],
        amenity: foundAmenity,
        latitude: json['latitude'] ?? json['lat'] ?? 0.0,
        longitude: json['longitude'] ?? json['lon'] ?? 0.0,
        houseNumber: json['addr:housenumber'] != null
            ? int.parse(json['addr:housenumber'].toString())
            : -1,
        avgStars: (json['avg_stars'] != null)
            ? double.parse(json['avg_stars'].toString())
            : 0.0,
        numReviews: (json['nb_avis_stars'] != null)
            ? int.parse(json['nb_avis_stars'].toString())
            : 0,
        tags: tags);
  }

  @override
  String toString() {
    return 'Place{id: $id, placeTable: $placeTable, name: $name, latitude: $latitude, longitude: $longitude, avgStars: $avgStars, numReviews: $numReviews, tags: $tags, amenity: $amenity}';
  }
}

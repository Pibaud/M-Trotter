import 'package:logger/logger.dart';

class Place {
  static final logger = Logger();
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double avgStars;
  final int numReviews;

  // Attributs facultatifs
  final String? amenity;
  final String? phone;
  final String? cuisine;
  final String? website;
  final String? email;
  final String? city;
  final String? street;
  final String? postcode;
  final String? openingHours;
  final bool? wheelchairAccessible;
  final bool? outdoorSeating;
  final bool? airConditioning;
  final String? facebook;
  final String? operator;

  Place({
    required this.id,
    required this.name,
    required this.amenity,
    required this.latitude,
    required this.longitude,
    required this.avgStars,
    required this.numReviews,
    this.phone,
    this.cuisine,
    this.website,
    this.email,
    this.city,
    this.street,
    this.postcode,
    this.openingHours,
    this.wheelchairAccessible,
    this.outdoorSeating,
    this.airConditioning,
    this.facebook,
    this.operator,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
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

    return Place(
      id: int.parse(json['id']),
      name: json['name'] ?? 'Unknown',
      amenity: json['amenity'] ?? 'Unknown',
      latitude: json['latitude'] ?? json['lat'] ?? 0.0,
      longitude: json['longitude'] ?? json['lon'] ?? 0.0,
      avgStars: json['avg_stars'] ?? 0.0,
      numReviews: int.parse(json['nb_avis_stars']),
      phone: tags['phone'],
      cuisine: tags['cuisine'],
      website: tags['website'],
      email: tags['email'],
      city: tags['addr:city'],
      street: tags['addr:street'],
      postcode: tags['addr:postcode'],
      openingHours: tags['opening_hours'],
      wheelchairAccessible: tags['wheelchair'] == 'yes',
      outdoorSeating: tags['outdoor_seating'] == 'yes',
      airConditioning: tags['air_conditioning'] == 'yes',
      facebook: tags['contact:facebook'],
      operator: tags['operator:wikipedia'],
    );
  }

  @override
  String toString() {
    List<String> details = [];

    details.add('Name: $name');
    details.add('Amenity: $amenity');
    details.add('Latitude: $latitude');
    details.add('Longitude: $longitude');

    if (phone != null) details.add('Phone: $phone');
    if (cuisine != null) details.add('Cuisine: $cuisine');
    if (website != null) details.add('Website: $website');
    if (email != null) details.add('Email: $email');
    if (city != null) details.add('City: $city');
    if (street != null) details.add('Street: $street');
    if (postcode != null) details.add('Postcode: $postcode');
    if (openingHours != null) details.add('Opening Hours: $openingHours');
    if (wheelchairAccessible != null) {
      details.add(
          'Wheelchair Accessible: ${wheelchairAccessible! ? "Yes" : "No"}');
    }

    if (outdoorSeating != null) {
      details.add('Outdoor Seating: ${outdoorSeating! ? "Yes" : "No"}');
    }

    if (airConditioning != null) {
      details.add('Air Conditioning: ${airConditioning! ? "Yes" : "No"}');
    }

    if (facebook != null) details.add('Facebook: $facebook');
    if (operator != null) details.add('Operator: $operator');

    return details.join('\n');
  }
}

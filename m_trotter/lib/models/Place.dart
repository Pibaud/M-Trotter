class Place {
  final String name;
  final String amenity;
  final double latitude;
  final double longitude;

  // Attributs facultatifs
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
    required this.name,
    required this.amenity,
    required this.latitude,
    required this.longitude,
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
    // Extraction et nettoyage des tags sous forme de Map
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
      name: json['name'] ?? 'Unknown',
      amenity: json['amenity'] ?? 'Unknown',
      latitude: json['latitude'] ?? 0.0,
      longitude: json['longitude'] ?? 0.0,
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
}
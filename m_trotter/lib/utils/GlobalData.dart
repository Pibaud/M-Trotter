import 'dart:convert';
import 'package:flutter/services.dart';

class GlobalData {
  static Map<String, String> amenities = {};
  static Map<String, String> tags = {};

  static Future<void> loadAmenities() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/amenities.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Convertir toutes les valeurs en String
      amenities = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      print('Amenities loaded: ${amenities.length} entries');
    } catch (e) {
      print('Error loading amenities: $e');
      amenities = {}; // Initialiser avec un dictionnaire vide en cas d'erreur
    }
  }

  static String getAmenityKey(String amenityValue) {
    if (amenities.containsValue(amenityValue)) {
      return amenities.keys.firstWhere((key) => amenities[key] == amenityValue,
          orElse: () => "Inconnu");
    } else {
      return "Inconnu";
    }
  }

  static Future<void> loadTags() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/tags.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Convertir toutes les valeurs en String
      tags = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      print('Tags loaded: ${tags.length} entries');
    } catch (e) {
      print('Error loading tags: $e');
      tags = {}; // Initialiser avec un dictionnaire vide en cas d'erreur
    }
  }

  static String getTagKey(String tagValue) {
    if (tags.containsValue(tagValue)) {
      return tags.keys.firstWhere((key) => tags[key] == tagValue,
          orElse: () => "Inconnu");
    } else {
      return "Inconnu";
    }
  }
}

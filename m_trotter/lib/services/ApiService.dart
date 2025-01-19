import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<String>> fetchPlaces(String input) async {
    final String url = '$baseUrl/api/places';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': input}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('places')) {
          return List<String>.from(responseData['places']);
        }
        return [];
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  Future<Map<String, dynamic>> fetchRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    String mode = 'car',
  }) async {
    final String url =
        '$baseUrl/api/routes?startLat=$startLat&startLon=$startLon&endLat=$endLat&endLon=$endLon&mode=$mode';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'path': responseData['path'],
            'distance': responseData['distance'],
            'duration': responseData['duration'],
          };
        } else {
          throw Exception('Erreur dans la réponse : ${responseData['status']}');
        }
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }
}
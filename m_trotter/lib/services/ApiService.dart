import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? dotenv.env['BASE_URL']!;

  Future<List<String>> fetchPlaces(String input) async {
    final String url = '$baseUrl/api/places/';

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

  //Inscription
  Future<Map<String, dynamic>> signUp(
      String email, String username, String password) async {
    print("demande d'inscription du service à $baseUrl");
    try {
      final url = Uri.parse('$baseUrl/comptes/inscription');
      final body = jsonEncode({
        'email': email,
        'username': username,
        'password': password,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Erreur inconnue'
        };
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  // Connexion
  Future<Map<String, dynamic>> logIn(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/comptes/connexion');
      final body = jsonEncode({
        'email': email,
        'password': password,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['message'] ?? 'Erreur inconnue'
        };
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }
}

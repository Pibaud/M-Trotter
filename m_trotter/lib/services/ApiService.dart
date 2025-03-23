import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'AuthService.dart';
import '../models/Photo.dart';

// Instancier FlutterSecureStorage
final FlutterSecureStorage secureStorage = FlutterSecureStorage();

class ApiService {
  final String baseUrl;
  final logger = Logger();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? dotenv.env['BASE_URL']!;

  Future<List<dynamic>> fetchPlaces(String input) async {
    final String url = '$baseUrl/api/places/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'search': input}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> pointsData = responseData['points'];
        print("je reçois les points suivants :");
        logger.i(pointsData);
        for (var point in pointsData) {
          point['place_table'] = "planet_osm_point";
        }
        return pointsData;
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  Future<List<dynamic>> fetchPlacesFittingAmenity(String amenity) async {
    final String url = '$baseUrl/api/amenityList/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amenity': amenity}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        for (var point in responseData) {
          point['place_table'] = "planet_osm_point";
        }
        return responseData;
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  Future<List<dynamic>> fetchPlacesBbox(LatLng min, LatLng max) async {
    final String url = '$baseUrl/api/placesbbox';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'minlat': min.latitude,
          'minlon': min.longitude,
          'maxlat': max.latitude,
          'maxlon': max.longitude
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        for (var point in responseData) {
          point['place_table'] = "planet_osm_point";
        }
        return responseData;
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  Future<String> getNameFromLatLng(LatLng coord) async {
    print("appel à getNeamFromLatLong avec $coord");
    final String url = '$baseUrl/api/depart';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json
            .encode({'latitude': coord.latitude, 'longitude': coord.longitude}),
      );

      if (response.statusCode == 200) {
        final String responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
  }

  Future<List<dynamic>> fetchTransitRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required String startName,
    required String endName,
    required String date,
    required String time,
  }) async {
    final String url =
        '$baseUrl/api/routes?startLat=$startLat&startLon=$startLon'
        '&endLat=$endLat&endLon=$endLon&mode=transit'
        '&startName=$startName&endName=$endName&date=$date&time=$time';

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData;
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
        '$baseUrl/api/routes?startLat=$startLat&startLon=$startLon'
        '&endLat=$endLat&endLon=$endLon&mode=$mode';

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          return {
            'path': responseData['path'],
            'distance': responseData['distance'],
            'duration': responseData['duration'],
            'instructions': responseData['instructions'],
            'ascend': responseData['ascend'],
            'descend': responseData['descend'],
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
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        print("je recois ca de inscription ${response.body}");
        final String? accessToken = responseData['accessToken'];
        final String? refreshToken = responseData['refreshToken'];
        print("accessToken : $accessToken");
        print("refreshToken : $refreshToken");

        if (accessToken != null) {
          await AuthService.saveToken(accessToken);
        }
        if (refreshToken != null) {
          await AuthService.saveRefreshToken(refreshToken);
        }
        print("j'essaye de recuperer access token et refresh token ");
        AuthService.getToken().then((token) {
          print("Access Token: $token");
        });

        AuthService.getRefreshToken().then((refreshToken) {
          print("Refresh Token: $refreshToken");
        });

        return {'success': true, 'data': responseData};
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
        'EorU': email,
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
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? accessToken = responseData['accessToken'];
        final String? refreshToken = responseData['refreshToken'];
        if (accessToken != null) {
          await AuthService.saveToken(accessToken);
        }
        if (refreshToken != null) {
          await AuthService.saveRefreshToken(refreshToken);
        }
        return {'success': true, 'data': responseData};
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

  //recuperer profil
  Future<Map<String, dynamic>> getProfile() async {
    var url = Uri.parse('$baseUrl/comptes/getProfil');
    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        // Vérifier si l'image est renvoyée en Base64
        String? base64Image = jsonResponse['profile_image'];

        // Convertir l'image Base64 en Uint8List pour pouvoir l'afficher
        Uint8List? imageBytes =
            base64Image != null ? base64Decode(base64Image) : null;

        // Retourner le profil avec l'image en binaire
        return {
          'success': true,
          'pseudo': jsonResponse['pseudo'],
          'age': jsonResponse['age'],
          'profile_image': imageBytes, // L'image en Uint8List
        };
      } else {
        return {"error": "Erreur de récupération des données du profil."};
      }
    } catch (e) {
      return {"error": "Erreur de connexion"};
    }
  }

  // Mise à jour du profil
  Future<Map<String, dynamic>> updateProfile({
    required String pseudo,
    String? age,
    File? profileImage,
  }) async {
    var url = Uri.parse('$baseUrl/comptes/updateProfil');
    var request = http.MultipartRequest('POST', url)..fields['pseudo'] = pseudo;

    if (age != null && age.isNotEmpty) {
      request.fields['age'] = age;
    }

    if (profileImage != null) {
      List<int> imageBytes = await profileImage.readAsBytes();
      String base64Image = base64Encode(imageBytes); // Conversion en Base64
      request.fields['profile_image'] = base64Image;
    }

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);
      return jsonResponse;
    } catch (e) {
      return {"error": "Erreur de connexion"};
    }
  }

  //recuperer l'access token
  Future<Map<String, dynamic>> recupAccessToken() async {
    String? refreshToken = await AuthService.getRefreshToken();

    if (refreshToken == null) {
      return {'success': false, 'error': 'Aucun refresh token trouvé'};
    }
    try {
      final url = Uri.parse('$baseUrl/comptes/recupAccessToken');
      final body = jsonEncode({'refreshToken': refreshToken});

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final String? accessToken = responseData['accessToken'];
        if (accessToken != null) {
          await AuthService.saveToken(accessToken);
        } else {
          await AuthService.logout();
          return {
            'success': false,
            'error': 'Refresh token invalide, veuillez vous reconnecter'
          };
        }

        return {'success': true, 'data': responseData};
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

  Future<List<Photo>> fetchImagesByPlaceId(String placeId) async {
    final String url = '$baseUrl/api/image';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'place_id': placeId}),
      );

      if (response.statusCode == 200) {
        if (json.decode(response.body)['photos'].isNotEmpty) {
          final List<dynamic> responseData =
              json.decode(response.body)['photos']['photos'];

          return Future.wait(responseData.map<Future<Photo>>((data) async {
            final String imageUrl = 'http://217.182.79.84:3000${data['url']}';
            return Photo(
              imageData: (await http.get(Uri.parse(imageUrl))).bodyBytes,
              tag: data['tag'] != null ? data['tag'] as String : null,
            );
          }).toList());
        } else {
          return [];
        }
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            'Erreur serveur : ${response.statusCode} - ${errorResponse['message'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la requête de recup des images de apiservice : $e');
    }
  }

  Future<Map<String, dynamic>> uploadImage(File imageFile, String placeId,
      {String? reviewId}) async {
    final String url = '$baseUrl/api/upload';

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['id_lieu'] = placeId
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      if (reviewId != null) {
        request.fields['id_avis'] = reviewId;
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de l\'upload de l\'image dans ApiService : $e');
    }
  }

  Future<Map<String, dynamic>> postReview({
    required String placeId,
    required String placeTable,
    required String comment,
    File? imageFile,
    int? parentId,
    int? rating,
  }) async {
    final String url = '$baseUrl/api/postavis';
    final String? token = await AuthService.getToken();

    if (token == null) {
      return {'success': false, 'error': 'Token non trouvé'};
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['accesstoken'] = token
        ..fields['place_id'] = placeId
        ..fields['place_table'] = placeTable
        ..fields['lavis'] = comment;

      if (parentId != null) {
        request.fields['avis_parent'] = parentId.toString();
      }

      if (rating != null) {
        request.fields['nb_etoile'] = rating.toString();
      }

      if (imageFile != null) {
        request.files
            .add(await http.MultipartFile.fromPath('file', imageFile.path));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final Map<String, dynamic> jsonResponse = json.decode(responseData);

      if (response.statusCode == 201 && jsonResponse['success'] == true) {
        return {'success': true, 'data': jsonResponse};
      } else {
        return {
          'success': false,
          'error': jsonResponse['error'] ?? 'Erreur inconnue'
        };
      }
    } catch (e) {
      print('Erreur lors de la requête : $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<dynamic>> fetchReviewsByPlaceId(
      String placeId, int startId) async {
    final String url = '$baseUrl/api/getavis';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'place_id': placeId,
          'startid': startId,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['avis'];
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête de ApiService : $e');
    }
  }

  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    final String url = '$baseUrl/api/deleteavis';
    final String? token = await AuthService.getToken();

    if (token == null) {
      return {'success': false, 'error': 'Token non trouvé'};
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accesstoken': token,
          'avis_id': reviewId,
        }),
      );

      final Map<String, dynamic> responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'error': responseData['error'] ?? 'Erreur inconnue'
        };
      }
    } catch (e) {
      print('Erreur lors de la requête : $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> proposeModifications(
      {required int osmId,
      required List<Map<String, String>> modifications}) async {
    final String url = '$baseUrl/modification';
    final String? token = await AuthService.getToken();
    print('modifie avec ${modifications.toString()} et id ${osmId.toString()}');

    if (token == null) {
      throw Exception('Token non trouvé');
    }

    for (var modification in modifications) {
      try {
        print('modification: ${modification.toString()}');
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'osm_id': osmId,
            'champ_modifie': modification['champ_modifie'],
            'ancienne_valeur': modification['ancienne_valeur'],
            'nouvelle_valeur': modification['nouvelle_valeur'],
            'accesstoken': token,
          }),
        );

        if (response.statusCode == 201) {
          final responseData = json.decode(response.body);
          print(responseData['message']);
        }else{   
          print('Erreur lors de la modification: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Erreur lors de la requête : $e');
      }
    }
  }
}

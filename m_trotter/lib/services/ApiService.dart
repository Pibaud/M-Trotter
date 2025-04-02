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
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:developer';



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
  Future<Map<String, dynamic>> getProfile({String? userId}) async {
    String url;
    Map<String, dynamic> body;
    String? token;

    final headers = {
      'Content-Type': 'application/json',
    };

    if (userId == null || userId.isEmpty) {
      try {
        token = await AuthService.getToken();
        if (token == null) {
          return {'success': false, 'error': 'Token non trouvé'};
        }
      }catch (e) {
        print("Erreur de connexion: $e");
        return {"success": false, "error": "Erreur de connexion"};
      }

      url = '$baseUrl/comptes/getProfil';
      body = {'accessToken': token};
    } else {

      url = '$baseUrl/comptes/getOtherProfil';
      body = {'id_user': userId};
    }


      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(response.body);

          if (jsonResponse.containsKey('profile_pic') && jsonResponse['profile_pic'] != null) {
            var profilePic = jsonResponse['profile_pic'];

            Uint8List imageBytes;

            if (profilePic is Map && profilePic.containsKey('data') && profilePic['type'] == 'Buffer') {
              List<int> rawData = List<int>.from(profilePic['data']);

              String base64String = String.fromCharCodes(rawData);

              imageBytes = base64Decode(base64String);

              return {
                'success': true,
                'pseudo': jsonResponse['username'],
                'profile_image': imageBytes,
              };
            } else {
              return {"success": false, "error": "Image mal formatée ou absente"};
            }
          } else {
            return {
              'success': true,
              'pseudo': jsonResponse['username'],
              'profile_image': null,
            };
          }
        } catch (e) {
          print("Erreur lors du parsing JSON: $e");
          return {"success": false, "error": "Erreur de traitement des données"};
        }
      }
       else {
        print("Erreur côté serveur: ${response.statusCode} - ${response.body}");
        return {"success": false, "error": "Erreur serveur, code : ${response.statusCode}"};
      }
    }


  // Mise à jour du profil
  Future<Map<String, dynamic>> updateProfile({
    required String pseudo,
    String? age,
    File? profileImage,  // Utilise XFile ici
  }) async {
    final String url = '$baseUrl/comptes/updateProfil';
    final String? token = await AuthService.getToken();

    if (token == null) {
      return {'success': false, 'error': 'Token non trouvé'};
    }

    try {
      // Structure correcte du body
      Map<String, dynamic> body = {
        'accessToken': token, // Correction : "accessToken" avec majuscule
        'updatedFields': {
          'username': pseudo,
        }
      };

      if (age != null) {
        body['updatedFields']['age'] = age;
      }

      if (profileImage != null) {
        final file = File(profileImage.path);

        // Compression de l'image
        final compressedFile = await compressImage(file, 500);
        if (compressedFile != null) {
          // Convertir en base64
          final bytes = await compressedFile.readAsBytes();
          String image = base64Encode(bytes);
          //printImageBase64(image); // Debug

          // Ajouter l'image à updatedFields
          body['updatedFields']['profile_pic'] = image;
          print("Image compressée et ajoutée à la requête");
        } else {
          print("Échec de la compression de l'image");
        }
      }
      print("Corps de la requête envoyée au serveur :");


      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};

      } else {
        return {

          'success': false,
          'error': 'Erreur serveur : ${response.statusCode} - ${response.body}'
        };
      }
    } catch (e) {
      print("Exception pendant la mise à jour du profil: $e");
      return {
        'success': false,
        'error': 'Erreur lors de la mise à jour du profil : $e'
      };
    }
  }

// Fonction de compression d'image
  Future<File?> compressImage(File imageFile, int maxSizeKB) async {
    int quality = 80;
    int minWidth = 200;
    int minHeight = 200;
    XFile? compressedXFile;
    File? compressedFile;

    do {
      String targetPath = "${imageFile.path}_compressed.jpeg";
      compressedXFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      // Convertir XFile en File si la compression a réussi
      if (compressedXFile != null) {
        compressedFile = File(compressedXFile.path);

        // Vérification de la taille du fichier compressé
        int fileSizeKB = compressedFile.lengthSync() ~/ 1024;
        print("Compression: qualité=$quality, taille=${fileSizeKB}KB");

        if (fileSizeKB <= maxSizeKB) break;
      } else {
        return null; // La compression a échoué
      }

      // Réduction de la qualité et des dimensions pour essayer de réduire la taille
      quality -= 10;
      minWidth = (minWidth * 0.9).toInt();
      minHeight = (minHeight * 0.9).toInt();
    } while (quality > 4);

    return compressedFile;
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

  //récupération bestplace

  Future<List<dynamic>> trouveBestPlaces() async {

    final String url = '$baseUrl/api/bestplaces';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur serveur : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la requête : $e');
    }
}

//ajouter un favoris

  Future<Map<String, dynamic>> addFavoris({required int osmId}) async {
    final String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final url = Uri.parse('$baseUrl/favoris/add');
      final body = jsonEncode({
        'accessToken': token,
        'osm_id': osmId,
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

//retirer un favoris

Future<Map<String, dynamic>> deleteFavoris({required int osmId}) async {
    final String? token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Token non trouvé');
    }
    try {
      final url = Uri.parse('$baseUrl/favoris/delete');
      final body = jsonEncode({
        'accessToken': token,
        'osm_id': osmId,
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

//recuperer les favoris

Future<List<dynamic>> getFavoris() async {
  String? accessToken = await AuthService.getToken();
  final String url = '$baseUrl/favoris/get';

  if (accessToken == null) {
    throw Exception('Token non trouvé');
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json'},
      body: json.encode({
        'accessToken': accessToken}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la requête : $e');
  }
}

//test si un endroit est en favoris

Future<bool> estFavoris({required int osmId}) async {
  String? accessToken = await AuthService.getToken();
  final String url = '$baseUrl/favoris/get';

  if (accessToken == null) {
    throw Exception('Aucun access token trouvé');
  }

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'accessToken': accessToken,
      }),
    );

    if (response.statusCode == 200) {
      List<dynamic> favoris = json.decode(response.body);
      return favoris.contains(osmId);
    } else {
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Erreur lors de la requête : $e');
  }
}

}


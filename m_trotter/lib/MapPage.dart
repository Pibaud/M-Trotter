import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LocationService.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  Timer? _debounce;
  double _rotationAngle = 0.0; // Initialiser l'angle de rotation

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Fonction pour obtenir la position de l'utilisateur
  Future<void> _getUserLocation() async {
    LocationService locationService = LocationService();

    var position = await locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
    } else {
      debugPrint('Impossible d\'obtenir la position de l\'utilisateur.');
    }
  }

  void _resetMapOrientation() {
    setState(() {
      _mapController.rotate(0); // Remet la rotation à 0° (nord en haut)
      _rotationAngle = 0.0; // Mettre à jour l'angle de rotation
    });
  }

  // Fonction pour recentrer la carte sur la position actuelle
  void _centerOnCurrentLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14.5);
    } else {
      print("Position actuelle non disponible.");
    }
  }

  Future<void> getPlaces(String input) async {
    final String url = 'http://192.168.0.49:3000/api/places';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': input}),
      );

      if (response.statusCode == 200) {
        print('Réponse du serveur : ${response.body}');
      } else {
        print('Erreur du serveur : ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la requête : $e');
    }
  }

  // Gestion du debounce pour éviter les appels multiples
  void _onTextChanged(String value) {
    // Annuler le timer existant si l'utilisateur continue à taper
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }

    // Définir un nouveau timer de 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Vérifier si le champ n'est pas vide avant d'envoyer
      if (value.trim().isNotEmpty) {
        getPlaces(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(43.611, 3.876), // Montpellier
              initialZoom: 13.0,
              minZoom: 12.0, // Zoom minimal
              maxZoom: 20.0, // Zoom maximal
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(43.51483, 3.69367), // Montbazin (Sud-Ouest)
                  LatLng(43.76439, 4.05769), // Saussines (Nord-Est)
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
              ),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      child: const Icon(
                        Icons.radio_button_checked,
                        color: Colors.blue,
                        size: 30.0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
                top: 30.0, left: 8.0, right: 8.0), // Augmente la marge en haut
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                prefixIcon: Icon(Icons.search),
                filled: true, // Permet de remplir le fond avec une couleur
                fillColor: Colors.white, // Couleur de fond blanc
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(20.0), // Rayon des coins agrandi
                ),
              ),
              onChanged: _onTextChanged, // Appeler la fonction debounce
            ),
          ),
          Positioned(
            top: 120.0, // Déplacer plus bas
            right: 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // Fond blanc
                borderRadius: BorderRadius.circular(30.0), // Coins arrondis
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.explore,
                  size: 30.0,
                  color: Colors.black,
                ),
                onPressed: _resetMapOrientation,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed:
              _centerOnCurrentLocation, // Action pour recentrer sur la position
          backgroundColor: Colors.blue,
          child: const Icon(Icons.near_me)),
    );
  }
}

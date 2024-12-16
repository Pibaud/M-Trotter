import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'LocationService.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Fonction pour obtenir la position de l'utilisateur
  Future<void> _getUserLocation() async {
    // Instancier la classe LocationService
    LocationService locationService = LocationService();

    // Récupérer la position actuelle
    var position = await locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      // Centrer la carte sur la position actuelle
      _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
    } else {
      debugPrint('Impossible d\'obtenir la position de l\'utilisateur.');
    }
  }

  void _resetMapOrientation() {
    setState(() {
      _mapController.rotate(0); // Remet la rotation à 0° (nord en haut)
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
                        Icons.my_location,
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
                  Icons.rotate_right,
                  size: 30.0,
                  color: Colors.black,
                ),
                onPressed: _resetMapOrientation,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

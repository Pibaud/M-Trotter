import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

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
              maxZoom: 18.0, // Zoom maximal
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(43.51483, 3.69367), // Montbazin (Sud-Ouest)
                  LatLng(43.76439, 4.05769), // Saussines (Nord-Est)
                ),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 8.0, right: 8.0), // Augmente la marge en haut
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                prefixIcon: Icon(Icons.search),
                filled: true,  // Permet de remplir le fond avec une couleur
                fillColor: Colors.white,  // Couleur de fond blanc
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),  // Rayon des coins agrandi
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
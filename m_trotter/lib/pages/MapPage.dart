import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/LocationService.dart';
import '../services/MapInteractions.dart';
import '../services/ApiService.dart';
import 'dart:async';
import '../widgets/PlaceInfoSheet.dart';
import '../widgets/ItinerarySheet.dart';
import '../widgets/CustomSearchBar.dart';
import '../providers/BottomNavBarVisibilityProvider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final bool focusOnSearch;

  const MapPage({super.key, required this.focusOnSearch});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final GlobalKey<CustomSearchBarState> _searchBarKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(); // FocusNode pour le TextField
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  Timer? _debounce;
  TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _isLayerVisible = false; // pour contrôler l'affichage du layer blanc
  LatLng? _lieuSelectionne;
  List<LatLng> _routePoints = []; // Liste pour stocker les points du trajet
  double _bottomSheetHeight = 100.0; // Hauteur initiale de la "modal"
  late double _distance;
  late double _duration;
  late LocationService _locationService;
  late MapInteractions _mapInteractions;
  late ApiService _apiService;
  StreamSubscription<Position>? _positionSubscription;

  final Map<String, LatLng> _lieuxCoordonnees = {
    'tokyoburger': LatLng(43.611, 3.876),
    'mcdonaldsComedie': LatLng(43.63, 3.886),
    'leclocher': LatLng(43.612, 3.877),
    'laopportunite': LatLng(43.613, 3.868),
    // Ajoutez d'autres lieux ici...
  };

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(); // service de localisation
    _mapInteractions = MapInteractions(_mapController); // interactions de carte
    _apiService = ApiService(baseUrl: 'http://192.168.1.72:3000'); // requêtes
    if (widget.focusOnSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        print("le focus est sur le TextField");
        setState(() {
          _isLayerVisible = true;
        });
      });
    }
    getUserLocation();
    _positionSubscription = _locationService.listenToPositionChanges(
      onPositionUpdate: (Position position) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        print('Nouvelle position : $_currentLocation');
      },
      onError: (dynamic error) {
        debugPrint('Erreur de localisation : $error');
      },
    );
  }

  Future<void> getUserLocation() async {
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

  Future<void> getPlaces(String input) async {
    try {
      final suggestions = await _apiService.fetchPlaces(input);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      print('Erreur lors de la récupération des places : $e');
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

  void _onSuggestionTap(String lieu) {
    _bottomSheetHeight = MediaQuery.of(context).size.height * 0.45;
    _controller.text = lieu; // Mise à jour du champ texte
    print("perte de focus car appui sur suggestion");
    _focusNode.unfocus();

    LatLng? destination = _lieuxCoordonnees[lieu];
    if (destination != null) {
      // Accéder au zoom actuel via mapController.camera.zoom
      double zoom = _mapController.camera.zoom;

      // Calculer le décalage en latitude basé sur le zoom
      final double mapHeightInDegrees =
          360 / (2 << (zoom.toInt() - 1)); // Conversion zoom -> degrés
      final double offsetInDegrees = mapHeightInDegrees *
          (_bottomSheetHeight / MediaQuery.of(context).size.height);

      // Ajuster la latitude du lieu sélectionné
      LatLng adjustedDestination =
          LatLng(destination.latitude - offsetInDegrees, destination.longitude);

      setState(() {
        _lieuSelectionne = destination; // Mettre à jour le lieu sélectionné
        _suggestions.clear();
        _isLayerVisible = false;
      });

      // Déplacer la carte vers la destination ajustée
      _mapController.move(adjustedDestination, zoom);
    }

    // Masquer la barre de navigation inférieure
    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();
  }

  void _itineraire(String lieu, {String mode = 'car'}) async {
    LatLng depart = _currentLocation!;
    LatLng? destination = _lieuxCoordonnees[lieu];

    if (destination != null) {
      try {
        final routeData = await _apiService.fetchRoute(
          startLat: depart.latitude,
          startLon: depart.longitude,
          endLat: destination.latitude,
          endLon: destination.longitude,
          mode: mode,
        );

        List<LatLng> routePoints = (routeData['path'] as List)
            .map((point) => LatLng(point[1], point[0]))
            .toList();

        setState(() {
          _routePoints = routePoints;
          _distance = routeData['distance'];
          _duration = routeData['duration'];
        });
      } catch (e) {
        print('Erreur lors de la récupération de l\'itinéraire : $e');
      }
    } else {
      print('Destination introuvable.');
    }
  }

  void _toggleSearchFocus(bool focus) {
    CustomSearchBar.toggleFocus(_searchBarKey, focus);
  }

  @override
  Widget build(BuildContext context) {
    print("Build appelé pour mappage");
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(43.611, 3.876), // Montpellier
              initialZoom: 13.0,
              minZoom: 12.0,
              maxZoom: 20.0,
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
              if (_lieuSelectionne != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _lieuSelectionne!,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30.0,
                      ),
                    ),
                  ],
                ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints, // Liste des points du trajet
                      strokeWidth: 7.0,
                      color: Colors.blue, // Couleur de la polyligne
                    ),
                  ],
                ),
            ],
          ),
          if (_lieuSelectionne != null && _routePoints.isEmpty)
            PlaceInfoSheet(
              height: _bottomSheetHeight,
              onDragUpdate: (dy) {
                setState(() {
                  _bottomSheetHeight -= dy;
                });
              },
              onDragEnd: () {
                final List<double> positions = [
                  100.0, // Version réduite
                  MediaQuery.of(context).size.height * 0.45, // Milieu
                  MediaQuery.of(context).size.height, // Plein écran
                ];

                double closestPosition = positions.reduce((a, b) =>
                    (a - _bottomSheetHeight).abs() <
                            (b - _bottomSheetHeight).abs()
                        ? a
                        : b);

                setState(() {
                  _bottomSheetHeight = closestPosition;
                });
              },
              placeName: _lieuxCoordonnees.entries
                  .firstWhere((entry) => entry.value == _lieuSelectionne)
                  .key,
              placeType: "Type du lieu",
              onItineraryTap: () {
                String lieuNom = _lieuxCoordonnees.entries
                    .firstWhere((entry) => entry.value == _lieuSelectionne)
                    .key;
                _itineraire(lieuNom);
              },
              onCallTap: () {
                print("Appeler le lieu sélectionné");
              },
              onWebsiteTap: () {
                print("Ouvrir le site web du lieu sélectionné");
              },
            ),
          if (_routePoints.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ItinerarySheet(
                initialHeight: MediaQuery.of(context).size.height * 0.45,
                fullHeight: MediaQuery.of(context).size.height,
                midHeight: MediaQuery.of(context).size.height *
                    0.45, // Hauteur moyenne
                collapsedHeight: 100.0, // Hauteur réduite
                distance: _distance, // Distance calculée
                duration: _duration, // Durée calculée
                onItineraryModeSelected: (String mode) {
                  _itineraire(
                    _lieuxCoordonnees.entries
                        .firstWhere((entry) => entry.value == _lieuSelectionne)
                        .key,
                    mode: mode,
                  );
                },
                onClose: () {
                  setState(() {
                    _routePoints = [];
                  });
                },
              ),
            ),
          if (_isLayerVisible)
            Container(
              color: Colors.white,
            ),
          CustomSearchBar(
            key: _searchBarKey,
            controller: _controller,
            focusNode: _focusNode,
            initialFocus: widget.focusOnSearch,
            isLayerVisible: _isLayerVisible,
            onLayerToggle: (isVisible) {
              if (_isLayerVisible != isVisible) {
                setState(() { 
                  _isLayerVisible = isVisible;
                });
              }
            },
            onClear: () {
              setState(() {
                _isLayerVisible = false;
              });
            },
            onTextChanged: _onTextChanged,
          ),
          if (_suggestions.isNotEmpty && _isLayerVisible)
            Positioned(
              top: 85.0,
              left: 8.0,
              right: 8.0,
              bottom: 0.0,
              child: Material(
                color: Colors.transparent,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      if (_focusNode.hasFocus) {
                        // Vérifie explicitement si le TextField a encore le focus
                        _focusNode.unfocus();
                        print("scroll détecté avec focus actif");
                      }
                    }
                    return false; // Continue à propager l'événement
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        onTap: () {
                          // Appeler la fonction pour envoyer la requête avec le lieu sélectionné
                          _onSuggestionTap(_suggestions[index]);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          if (!_isLayerVisible)
            Positioned(
              top: 120.0,
              right: 10.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
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
                    onPressed: () => _mapInteractions.resetMapOrientation()),
              ),
            ),
          if (!_isLayerVisible)
            Positioned(
              bottom: 20.0,
              right: 10.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.0),
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
                    Icons.near_me,
                    size: 30.0,
                    color: Colors.blue,
                  ),
                  onPressed: () => _mapInteractions
                      .centerOnCurrentLocation(_currentLocation),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose(); // Libère le FocusNode
    _positionSubscription?.cancel();
    super.dispose();
  }
}

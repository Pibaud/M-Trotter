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
import '../models/Place.dart';
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
  List<Place> suggestedPlaces = [];
  bool _isLayerVisible = false; // pour contrôler l'affichage du layer blanc
  Place? _selectedPlace;
  double _bottomSheetHeight = 100.0; // Hauteur initiale de la "modal"
  late LocationService _locationService;
  late MapInteractions _mapInteractions;
  late ApiService _apiService;
  StreamSubscription<Position>? _positionSubscription;
  late Map<String, Map<String, dynamic>> _routes;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(); // service de localisation
    _mapInteractions = MapInteractions(_mapController); // interactions de carte
    _apiService = ApiService(); // requêtes
    _routes = {};
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
      final res = await _apiService.fetchPlaces(input);
      setState(() {
        suggestedPlaces =
            res.map<Place>((data) => Place.fromJson(data)).toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des places : $e');
    }
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isNotEmpty) {
        getPlaces(value.trim());
      }
    });
  }

  void _onSuggestionTap(Place place) {
    _bottomSheetHeight = MediaQuery.of(context).size.height * 0.45;
    _controller.text =
        place.name; // Mise à jour du champ texte avec le nom du lieu
    print("Perte de focus car appui sur suggestion");
    _focusNode.unfocus();

    // Vérification des coordonnées disponibles dans l'objet Place
    LatLng? destination;
    destination = LatLng(place.latitude, place.longitude);

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
      _selectedPlace = place; // Mettre à jour le lieu sélectionné
      suggestedPlaces.clear(); // Vide la liste des suggestions
      _isLayerVisible = false;
    });

    // Déplacer la carte vers la destination ajustée
    _mapController.move(adjustedDestination, zoom);

    // Masquer la barre de navigation inférieure
    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();
  }

  Future<void> _fetchRoutesForAllModes(Place place) async {
    if (_currentLocation == null)
      return; // S'assurer que la position est disponible

    LatLng depart = _currentLocation!;
    LatLng destination = LatLng(place.latitude, place.longitude);
    final modes = ['car', 'foot', 'bike']; //rajouter transit plus tard
    for (var mode in modes) {
      try {
        // Envoyer une seule requête pour tous les modes
        final routeData = await _apiService.fetchRoute(
            startLat: depart.latitude,
            startLon: depart.longitude,
            endLat: destination.latitude,
            endLon: destination.longitude,
            mode: mode);

        print("routeData pour le mode $mode :");
        print(routeData['path']);
        print("type de la routeData : ${routeData['path'].runtimeType}");
        print(
            "type d'un élément de la routeData : ${routeData['path'][0].runtimeType}");

        setState(() {
          _routes[mode] = routeData;
        });
      } catch (e) {
        print(
            'Erreur lors de la récupération des itinéraires pour tous les modes : $e');
      }
    }
    print("route car : ${_routes['car']}");
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
              if (_selectedPlace != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _selectedPlace!.latitude, _selectedPlace!.longitude),
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
          if (_selectedPlace != null && _routePoints.isEmpty)
            PlaceInfoSheet(
              height: _bottomSheetHeight,
              onDragUpdate: (dy) {
                setState(() {
                  _bottomSheetHeight -= dy;
                });
              },
              onDragEnd: () {
                final List<double> positions = [
                  100.0,
                  MediaQuery.of(context).size.height * 0.45,
                  MediaQuery.of(context).size.height,
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
              placeName: _selectedPlace!.name,
              placeType: _selectedPlace!.amenity,
              onItineraryTap: () {
                _fetchRoutesForAllModes(_selectedPlace!);
              },
              onCallTap: () {
                print("Appeler le lieu sélectionné");
              },
              onWebsiteTap: () {
                print("Ouvrir le site web du lieu sélectionné");
              },
              onClose: () {
                setState(() {
                  _selectedPlace = null;
                  _controller.text = "";
                });
              },
            ),
          if (_routes.isNotEmpty)
            ItinerarySheet(
              initialHeight: MediaQuery.of(context).size.height * 0.45,
              fullHeight: MediaQuery.of(context).size.height,
              midHeight: MediaQuery.of(context).size.height * 0.45,
              collapsedHeight: 100.0,
              routes: _routes, // Routes pour tous les modes
              initialDistance: _routes['car']!['distance'],
              initialDuration: _routes['car']!['duration'],
              onItineraryModeSelected: (String mode) {
                setState(() {
                  _routePoints = _routes[mode]!['path'];// ERREUR SUREMENT LA
                });
              },
              onClose: () {
                setState(() {
                  _routePoints = [];
                });
              },
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
            onTextClear: () {
              setState(() {
                _controller.clear();
              });
            },
            onTextChanged: _onTextChanged,
          ),
          if (suggestedPlaces.isNotEmpty && _isLayerVisible)
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
                        _focusNode.unfocus();
                        print("scroll détecté avec focus actif");
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: suggestedPlaces.length,
                    itemBuilder: (context, index) {
                      final place = suggestedPlaces[index];
                      return ListTile(
                        title: Text(place
                            .name), // Utilisation directe de l'attribut name
                        subtitle: Text(place.amenity ??
                            ''), // Affiche éventuellement la catégorie
                        onTap: () {
                          _onSuggestionTap(
                              place); // Appelle la fonction avec l'objet Place
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

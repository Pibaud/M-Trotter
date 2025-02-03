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
import 'package:tuple/tuple.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

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
  Map<String, dynamic> _routesInstructions = {};
  Map<String, Tuple2<double, double>> _elevationData = {};
  late String _currentLocationName;

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
      print(
          "nouvelle position : ${position.latitude}, ${position.longitude} nouvelle requete à l'api");

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      try {
        if (_currentLocation != null) {
          String value = await _apiService.getNameFromLatLng(_currentLocation!);
          print("value : $value");
          setState(() {
            _currentLocationName = value;
          });
        }
      } catch (error) {
        print('erreur de requête : $error');
      }

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
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (value.trim().isNotEmpty) {
        getPlaces(value.trim());
      }
    });
  }

  void _onSuggestionTap(Place place) {
    _bottomSheetHeight = MediaQuery.of(context).size.height * 0.45;
    _controller.text =
        place.name; // Mise à jour du champ texte avec le nom du lieu
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

    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();

    // Déplacer la carte vers la destination ajustée
    _mapController.move(adjustedDestination, zoom);
  }

  Future<void> _fetchRoutesForAllModes(Place place) async {
    if (_currentLocation == null)
      return; // S'assurer que la position est disponible

    LatLng depart = _currentLocation!;
    LatLng destination = LatLng(place.latitude, place.longitude);
    final modes = ['car', 'foot', 'bike']; // Ajouter transit

    // Définir des variables pour le mode transit (si nécessaire)
    String? startName = _currentLocationName;
    String? endName = _selectedPlace!.name;
    String? date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? time = DateFormat('HH-mm').format(DateTime.now());

    for (var mode in modes) {
      try {
        // Envoie la requête pour tous les modes
        final routeData = await _apiService.fetchRoute(
          startLat: depart.latitude,
          startLon: depart.longitude,
          endLat: destination.latitude,
          endLon: destination.longitude,
          mode: mode,
          // Paramètres spécifiques au mode transit
          startName: mode == 'transit' ? startName : null,
          endName: mode == 'transit' ? endName : null,
          date: mode == 'transit' ? date : null,
          time: mode == 'transit' ? time : null,
        );

        setState(() {
          _routes[mode] = routeData;
          _routesInstructions[mode] = routeData['instructions'];
          _elevationData[mode] =
              Tuple2(routeData['ascend'], routeData['descend']);
        });
      } catch (e) {
        print(
            'Erreur lors de la récupération des itinéraires pour tous les modes : $e');
      }
    }
    print(
        "date : $date, time : $time, startName : $startName, endName : $endName");
    try {
      final routeData = await _apiService.fetchRoute(
        startLat: depart.latitude,
        startLon: depart.longitude,
        endLat: destination.latitude,
        endLon: destination.longitude,
        mode: 'transit',
        startName: startName,
        endName: endName,
        date: date,
        time: time,
      );

      debugPrint(jsonEncode(routeData['responseData']['trips']['Trip'][0]), wrapWidth: 1024);

      setState(() {
        _routes['transit'] = routeData;
      });
    } catch (e) {
      print(
          'Erreur lors de la récupération des itinéraires pour tous les modes : $e');
    }
    setState(() {
      // initialisation du mode
      _routePoints = (_routes['car']!['path'] as List)
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();
    });
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
            ],
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Stack(
                  children: [
                    // BackdropFilter pour le flou foncé
                    Positioned.fill(
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Flou
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(
                                0x10000000), // Fond semi-transparent foncé (alpha = 0.2)
                            borderRadius: BorderRadius.circular(
                                10.0), // Facultatif pour arrondir les coins
                            boxShadow: [
                              BoxShadow(
                                color: Color(
                                    0x10000000), // Légère ombre noire avec alpha = 0.2
                                blurRadius: 5.0, // Flou de l'ombre
                                spreadRadius: 2.0, // Espace de l'ombre
                                offset: Offset(
                                    0, 2), // Position de l'ombre (décalage)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Contenu du Container avec les boutons
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // Centrer les icônes
                        children: [
                          // Bouton de reset de la carte
                          IconButton(
                            icon: Icon(
                              Icons.explore,
                              size: 30.0,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _mapInteractions.resetMapOrientation(),
                          ),
                          // Barre séparatrice horizontale blanche avec espacement à gauche et à droite
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                    10.0), // Espacement à gauche et à droite
                            child: Container(
                              height: 2.0, // Hauteur de la barre
                              width:
                                  30.0, // Largeur de la barre (moins que la largeur totale du conteneur)
                              color:
                                  Colors.white, // Couleur blanche pour la barre
                            ),
                          ),
                          // Bouton de centrage sur la localisation actuelle
                          IconButton(
                            icon: Icon(
                              Icons.near_me,
                              size: 30.0,
                              color: Colors.white,
                            ),
                            onPressed: () => _mapInteractions
                                .centerOnCurrentLocation(_currentLocation),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

                Provider.of<BottomNavBarVisibilityProvider>(context,
                        listen: false)
                    .showBottomNav();
              },
            ),
          if (_routes.isNotEmpty)
            ItinerarySheet(
              initialHeight: MediaQuery.of(context).size.height * 0.45,
              fullHeight: MediaQuery.of(context).size.height,
              midHeight: MediaQuery.of(context).size.height * 0.45,
              collapsedHeight: 100.0,
              routes: _routes, // Routes pour tous les modes
              routesInstructions: _routesInstructions,
              elevationData: _elevationData,
              initialDistance: _routes['car']!['distance'],
              initialDuration: _routes['car']!['duration'],
              initialMode: 'car',
              onItineraryModeSelected: (String mode) {
                setState(() {
                  _routePoints = (_routes[mode]!['path'] as List)
                      .map((coord) =>
                          LatLng(coord[1].toDouble(), coord[0].toDouble()))
                      .toList();
                });
              },
              onClose: () {
                setState(() {
                  _routePoints = [];
                  _routes = {};
                  _routesInstructions = {};
                });
              },
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

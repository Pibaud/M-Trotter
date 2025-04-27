import 'package:flutter/material.dart';
import 'dart:math' show sqrt, pow;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/services.dart';
import 'package:m_trotter/widgets/PlaceListSheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/LocationService.dart';
import '../services/MapInteractions.dart';
import '../services/ApiService.dart';
import '../services/AmenitiesService.dart';
import 'dart:async';
import '../widgets/PlacePresentationSheet.dart';
import '../widgets/PlaceInfoSheet.dart';
import '../widgets/ItinerarySheet.dart';
import '../widgets/CustomSearchBar.dart';
import '../providers/BottomNavBarVisibilityProvider.dart';
import '../models/Place.dart';
import '../models/TramLine.dart';
import '../models/TramStop.dart';
import '../models/Photo.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tuple/tuple.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../utils/AmenityIcons.dart';
import '../utils/GlobalData.dart'; // Added import for GlobalData
import 'package:url_launcher/url_launcher.dart'; // Add this import

class MapPage extends StatefulWidget {
  final bool focusOnSearch;
  final Place? selectedPlace;

  const MapPage({super.key, required this.focusOnSearch, this.selectedPlace});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final logger = Logger();
  final GlobalKey<CustomSearchBarState> _searchBarKey = GlobalKey();
  final FocusNode _focusNode = FocusNode(); // FocusNode pour le TextField
  final MapController _mapController = MapController();
  StreamSubscription<MapEvent>? _mapEventSubscription;
  LatLngBounds?
      _lastBounds; // Stocke la dernière zone chargée pour pas trop de requêtes
  final double zoomThreshold = 0.3; // Seuil de zoom pour éviter trop d'appels
  LatLng? _currentLocation;
  Timer? _debounce;
  TextEditingController _controller = TextEditingController();
  List<Place> suggestedPlaces = [];
  List<Place> fittingPlaces =
      []; // places correspondant à l'amenity (extensible à d'autres filtres ?)
  List<String> suggestedAmenities = [];
  bool _isLayerVisible = false;
  bool _isPlacePresentationSheetVisible = false;
  bool _isPlaceInfoSheetVisible = false;
  Place? _selectedPlace;
  String? _selectedAmenity;
  double _bottomSheetHeight = 80.0;
  List<String> _searchHistory = [];
  late LocationService _locationService;
  late MapInteractions _mapInteractions;
  late ApiService _apiService;
  late AmenitiesService _amenitiesService;
  StreamSubscription<Position>? _positionSubscription;
  late Map<String, Map<String, dynamic>> _routes;
  late List<dynamic> _transitWays = [];
  List<LatLng> _routePoints = [];
  List<Tuple2<String, List<LatLng>>> _tramPolyLinesPoints =
      []; //la ou les lignes de tram de format _tramPolyLinesPoints[0] = (codeHexa, [LatLng])
  List<List<LatLng>> _walkTramPoints =
      []; // chemins à faire à pied pour arriver au tram / en sortant du tram jusqu'à la destination
  Map<String, dynamic> _routesInstructions = {};
  Map<String, Tuple2<double, double>> _elevationData = {};
  late String _currentLocationName;
  late List<TramStop> tramStops = [];
  late List<TramLine> tramLines = [];
  late List<Place> _loadedPlaces = [];
  late List<Photo> photos = [];
  bool _showingAllAmenities = false;
  LatLng? _lastQueryLocation;
  List<dynamic> _nearbyModificationsToValidate = [];
  final double _queryDistanceThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService(); // service de localisation
    _amenitiesService = AmenitiesService();
    _loadAmenitiesData(); // Nouvelle méthode pour charger les données
    _mapInteractions = MapInteractions(_mapController); // interactions de carte
    _mapEventSubscription = _mapController.mapEventStream.listen(_onMapEvent);
    loadTramData();
    _apiService = ApiService(); // requêtes
    _routes = {};
    _showingAllAmenities = false; // Add this state variable
    _lastQueryLocation = null;
    
    // Appeler getUserLocation d'abord, puis _fetchNearbyModificationsToValidate après
    getUserLocation().then((_) {
      // Ajoute un délai pour s'assurer que _currentLocation est défini
      Future.delayed(const Duration(seconds: 1), () {
        _fetchNearbyModificationsToValidate();
      });
    });
    
    if (widget.focusOnSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        setState(() {
          _isLayerVisible = true;
        });
      });
    }

    if (widget.selectedPlace != null) {
      Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
          .hideBottomNav();
      setState(() {
        _selectedPlace = widget.selectedPlace;
        _isPlacePresentationSheetVisible = true;
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
    // Call _fetchPlacesBbox with the current visible bounds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlacesBbox(_mapController.camera.visibleBounds);
    });
    //_loadSearchHistory();
  }

  void _checkAndFetchNearbyModifications() {
    if (_currentLocation != null) {
      if (_lastQueryLocation == null) {
        _lastQueryLocation = _currentLocation;
        _fetchNearbyModificationsToValidate();
      } else {
        // Calcul de la distance entre la dernière position de requête et la position actuelle
        double distance = Geolocator.distanceBetween(
            _lastQueryLocation!.latitude,
            _lastQueryLocation!.longitude,
            _currentLocation!.latitude,
            _currentLocation!.longitude);

        // Si la distance dépasse le seuil, faire une nouvelle requête
        if (distance > _queryDistanceThreshold) {
          _lastQueryLocation = _currentLocation;
          _fetchNearbyModificationsToValidate();
        }
      }
    }
  }

  Future<void> _fetchNearbyModificationsToValidate() async {
    print('Fetching nearby modifications...');
    
    // Si _currentLocation est null, attendre qu'il soit disponible
    if (_currentLocation == null) {
      print('Waiting for location data...');
      // Attendre que la localisation soit disponible (max 5 secondes)
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_currentLocation != null) break;
      }
      
      // Si toujours null après l'attente, tenter d'obtenir la position
      if (_currentLocation == null) {
        print('Location still null, trying to get it directly...');
        await getUserLocation();
      }
      
      // Si toujours null, abandonner
      if (_currentLocation == null) {
        print('Could not get location, abandoning fetch of nearby modifications');
        return;
      }
    }
    
    print('Current location: $_currentLocation');
    try {
      final response = await _apiService.fetchModificationsToValidate(
          _currentLocation!.latitude, _currentLocation!.longitude, 400);

      setState(() {
        _nearbyModificationsToValidate = response['lieux'];

        print('Nombre de modifications reçues : ${response['lieux']}');
      });
  
    } catch (e) {
      print('Erreur lors de la récupération des modifications à valider: $e');
    }
  }

  Future<void> _loadAmenitiesData() async {
    await _amenitiesService.loadAmenities();
  }

  Future<void> loadTramData() async {
    String stopsData = await rootBundle.loadString('assets/tramStops.json');
    String linesData = await rootBundle.loadString('assets/tramLines.json');

    Map<String, dynamic> stopsJson = jsonDecode(stopsData);
    Map<String, dynamic> linesJson = jsonDecode(linesData);

    List<TramStop> loadedStops = stopsJson['features']
        .map<TramStop>((json) => TramStop.fromJson(json))
        .toList();

    List<TramLine> loadedLines = linesJson['features']
        .map<TramLine>((json) => TramLine.fromJson(json, loadedStops))
        .toList();

    setState(() {
      tramStops = loadedStops;
      tramLines = loadedLines;
    });
  }

  Future<LatLng?> getUserLocation() async {
    print('Getting user location...');
    LocationService locationService = LocationService();

    var position = await locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      print('Location updated: $_currentLocation');

      try {
        if (_currentLocation != null) {
          String value = await _apiService.getNameFromLatLng(_currentLocation!);
          print("Localisation : $value");
          setState(() {
            _currentLocationName = value;
          });
        }
      } catch (error) {
        print('erreur de requête : $error');
      }

      if (position.latitude >= 43.51483 &&
          position.latitude <= 43.76439 &&
          position.longitude >= 3.69367 &&
          position.longitude <= 4.05769) {
        _mapController.move(
            LatLng(position.latitude, position.longitude), 13.0);
      }
      
      return _currentLocation;
    } else {
      debugPrint('Impossible d\'obtenir la position de l\'utilisateur.');
      return null;
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
        List<String> foundAmenities = _amenitiesService.searchAmenities(value);
        if (foundAmenities.isNotEmpty) {
          setState(() {
            suggestedAmenities = foundAmenities;
          });
        } else {
          setState(() {
            suggestedAmenities = [];
          });
        }
      }
    });
  }

/*
  void _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString('search_history');
    if (historyJson != null){
      setState(() {
      _searchHistory = List<Place>.from(jsonDecode(historyJson));
      });
    }
    else{
      setState(() {
      _searchHistory = [];
      });
    }
  }
*/
  void _onSuggestionTap(Place place) async {
    _bottomSheetHeight = MediaQuery.of(context).size.height * 0.45;
    _controller.text =
        place.name; // Mise à jour du champ texte avec le nom du lieu
    _focusNode.unfocus();
    LatLng? destination;
    destination = LatLng(place.latitude, place.longitude);
    double zoom = _mapController.camera.zoom;
    final double mapHeightInDegrees =
        360 / (2 << (zoom.toInt() - 1)); // Conversion zoom -> degrés
    final double offsetInDegrees = mapHeightInDegrees *
        (_bottomSheetHeight / MediaQuery.of(context).size.height);
    LatLng adjustedDestination =
        LatLng(destination.latitude - offsetInDegrees, destination.longitude);

    setState(() {
      _selectedPlace = place; // Mettre à jour le lieu sélectionné
      suggestedPlaces.clear(); // Vide la liste des suggestions
      _isLayerVisible = false;
      _isPlacePresentationSheetVisible = true;
    });

    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();

    _mapController.move(adjustedDestination, zoom);

    // Fetch images for the selected place
    try {
      List<Photo> fetchedPhotos =
          await _apiService.fetchImagesByPlaceId(place.id.toString());
      setState(() {
        photos = fetchedPhotos;
      });
    } catch (e) {
      print('Erreur lors de la récupération des images : $e');
    }
    final prefs = await SharedPreferences.getInstance();
    String? historyJson = prefs.getString('search_history');
    /*historyJson.removeWhere((existingPlace) => existingPlace.id == place.id);
    historyJson.insert(0, place);
    if (historyJson.length > 5) {
      historyJson.removeLast();
    }*/
  }

  void _onMarkerTap(Place place) {
    setState(() {
      _selectedPlace = place;
      _isPlacePresentationSheetVisible = true;
    });

    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();
  }

  Future<void> _fetchRoutesForAllModes(Place place) async {
    if (_currentLocation == null) return;

    LatLng depart = _currentLocation!;
    LatLng destination = LatLng(place.latitude, place.longitude);
    final modes = ['car', 'foot', 'bike']; // Ajouter transit

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
        );

        setState(() {
          _routes[mode] = routeData;
          _routesInstructions[mode] = routeData['instructions'];
          _elevationData[mode] =
              Tuple2(routeData['ascend'], routeData['descend']);
        });
      } catch (e) {
        print(
            'Erreur lors de la récupération des itinéraires pour le mode $mode : $e');
      }
    }

    try {
      final transitRoutesData = await _apiService.fetchTransitRoute(
        startLat: depart.latitude,
        startLon: depart.longitude,
        endLat: destination.latitude,
        endLon: destination.longitude,
        startName: startName,
        endName: endName,
        date: date,
        time: time,
      );

      List<dynamic> transitWays = [];

      for (var way in transitRoutesData) {
        Map<String, dynamic> wayInfos = {};
        DateTime dateDepartureTime =
            DateFormat("dd/MM/yyyy HH:mm:ss").parse(way["heure_de_départ"]);
        DateTime dateArrivalTime =
            DateFormat("dd/MM/yyyy HH:mm:ss").parse(way["heure_d_arrivée"]);

        List<dynamic> cheminMarcheToTram =
            way["itinéraire"][0]["chemin_marche"];
        List<dynamic> cheminMarcheToEnd = way["itinéraire"][2]["chemin_marche"];

        List<LatLng> walkToTramWayPoints = cheminMarcheToTram.map((point) {
          return LatLng(point["Lat"], point["Long"]);
        }).toList();
        List<LatLng> tramToWalkWayPoints = cheminMarcheToEnd.map((point) {
          return LatLng(point["Lat"], point["Long"]);
        }).toList();

        Map<String, dynamic> arriveeToTram = way["itinéraire"][0]["arrivée"];
        Map<String, dynamic> arriveeToEnd = way["itinéraire"][0]["arrivée"];

        LatLng arrivalTramPoint = LatLng(arriveeToTram["position"]["Lat"],
            arriveeToTram["position"]["Long"]);
        walkToTramWayPoints.add(arrivalTramPoint);

        LatLng arrivalEndPoint = LatLng(
            arriveeToEnd["position"]["Lat"], arriveeToEnd["position"]["Long"]);
        tramToWalkWayPoints.add(arrivalEndPoint);

        String startStationName = arriveeToTram["nom"];

        // Transformation de la durée "PT8M42S" en "8 minutes"
        String walkToTramDurationRaw = way["itinéraire"][0]["durée"];
        String tramDurationRaw = way["itinéraire"][1]["durée"];
        String tramToWalkDurationRaw = way["itinéraire"][2]["durée"];
        RegExp regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
        Match? walkToTramMatch = regex.firstMatch(walkToTramDurationRaw);
        Match? tramMatch = regex.firstMatch(tramDurationRaw);
        Match? tramToWalkMatch = regex.firstMatch(tramToWalkDurationRaw);

        String walkToTramDurationFormatted =
            '${int.parse(walkToTramMatch?.group(2) ?? '0')} minutes';
        String tramDurationFormatted =
            '${int.parse(tramMatch?.group(2) ?? '0')} minutes';
        String tramToWalkDurationFormatted =
            '${int.parse(tramToWalkMatch?.group(2) ?? '0')} minutes';

        wayInfos['heureDepart'] = DateFormat("HH:mm").format(dateDepartureTime);
        wayInfos['heureArrivee'] = DateFormat("HH:mm").format(dateArrivalTime);
        wayInfos['distance'] = way["distance"];
        wayInfos['co2Economise'] = way["co2_économisé"];
        wayInfos['walkToTram'] = {
          'wayPoints': walkToTramWayPoints,
          'to': startStationName,
          'duration': walkToTramDurationFormatted
        };

        List<Map<String, dynamic>> tramSteps = [
          way["itinéraire"][0]["arrivée"],
          ...way["itinéraire"][1]["étapes_tram"]
        ];

        wayInfos['tram'] = {
          'line':
              'L${way["itinéraire"][1]["ligne"].replaceAll(RegExp(r'\s*-\s*'), ' > ')}',
          'steps': tramSteps,
          'duration': tramDurationFormatted
        };

        if (tramToWalkWayPoints.isNotEmpty) {
          tramToWalkWayPoints.removeLast();
        }

        wayInfos['tramToWalk'] = {
          'wayPoints': tramToWalkWayPoints,
          'to': arrivalEndPoint,
          'duration': tramToWalkDurationFormatted
        };

        transitWays.add(wayInfos);
      }

      setState(() {
        _transitWays = transitWays;
      });
    } catch (e) {
      print(
          'Erreur lors de la récupération des itinéraires pour le mode transit : $e');
    }

    setState(() {
      // initialisation du mode
      _routePoints = (_routes['car']!['path'] as List)
          .map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
          .toList();
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return sqrt(pow(point1.latitude - point2.latitude, 2) +
        pow(point1.longitude - point2.longitude, 2));
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final bounds = _mapController.camera.visibleBounds;

      if (_lastBounds == null || _hasSignificantChange(bounds, _lastBounds!)) {
        _lastBounds = bounds;
        _fetchPlacesBbox(bounds);
      }
    }
  }

  bool _hasSignificantChange(LatLngBounds newBounds, LatLngBounds oldBounds) {
    const double movementThreshold =
        0.002; // Ajuste ce seuil pour éviter trop d'appels
    return (newBounds.northEast.latitude - oldBounds.northEast.latitude).abs() >
            movementThreshold ||
        (newBounds.northEast.longitude - oldBounds.northEast.longitude).abs() >
            movementThreshold ||
        (newBounds.southWest.latitude - oldBounds.southWest.latitude).abs() >
            movementThreshold ||
        (newBounds.southWest.longitude - oldBounds.southWest.longitude).abs() >
            movementThreshold;
  }

  void _fetchPlacesBbox(LatLngBounds bounds) async {
    try {
      List<dynamic> res = await ApiService().fetchPlacesBbox(
        bounds.southWest, // min (lat, lon)
        bounds.northEast, // max (lat, lon)
      );

      List<Place> places =
          res.map<Place>((data) => Place.fromJson(data)).toList();

      setState(() {
        _loadedPlaces = places;
      });
    } catch (e) {
      print('Erreur lors de la récupération des lieux: $e');
    }
  }

  Future<void> _onAmenityTap(String amenity) async {
    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();
    _controller.text = amenity;
    _focusNode.unfocus();

    setState(() {
      _selectedAmenity = amenity; // Mettre à jour le lieu sélectionné
      suggestedPlaces = [];
      _isLayerVisible = false;
    });

    try {
      final res = await _apiService.fetchPlacesFittingAmenity(
          _amenitiesService.getRealAmenityName(amenity));
      setState(() {
        fittingPlaces.addAll(res.map<Place>((data) => Place.fromJson(data)));
      });
    } catch (e) {
      print('Erreur lors de la récupération des places pour une amenity : $e');
    }
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
              onMapReady: () {
                _fetchPlacesBbox(_mapController.camera.visibleBounds);
              },
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
              if (_loadedPlaces.isNotEmpty)
                MarkerLayer(
                  markers: _loadedPlaces.map((place) {
                    return Marker(
                      point: LatLng(place.latitude, place.longitude),
                      width: 20.0,
                      height: 20.0,
                      child: GestureDetector(
                        onTap: () => _onMarkerTap(place),
                        child: _selectedPlace == place
                            ? const SizedBox.shrink()
                            : Icon(
                                getAmenityIcon(place.amenity ?? ''),
                                color: getAmenityColor(place.amenity ?? ''),
                                size: 20.0,
                              ),
                      ),
                    );
                  }).toList(),
                ),
              if (_tramPolyLinesPoints.isNotEmpty)
                PolylineLayer(
                  polylines: _tramPolyLinesPoints.map((tuple) {
                    return Polyline(
                      points: tuple.item2, // Liste de LatLng
                      strokeWidth: 5.0,
                      color: Color(int.parse(
                          '0xff${tuple.item1.replaceFirst('#', '')}')), // Couleur hexadécimale
                    );
                  }).toList(),
                ),
              if (_walkTramPoints.isNotEmpty)
                PolylineLayer(
                  polylines: _walkTramPoints.map((walkPath) {
                    return Polyline(
                      points: walkPath,
                      strokeWidth: 3.0,
                      color: Color.fromARGB(255, 87, 168, 235), // Bleu
                    );
                  }).toList(),
                ),
              if (_selectedPlace != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _selectedPlace!.latitude, _selectedPlace!.longitude),
                      child: const Icon(
                        Icons.location_on_rounded,
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
                suggestedPlaces = [];
                suggestedAmenities = [];
              });
            },
            onTextChanged: _onTextChanged,
          ),
          if (!_isLayerVisible && !_isPlacePresentationSheetVisible)
            Positioned(
              top: 85.0,
              left: 0.0,
              right: 0.0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAmenityChip('Supermarché'),
                    _buildAmenityChip('Restaurant'),
                    _buildAmenityChip('Bar'),
                    _buildAmenityChip('Station-service'),
                    _buildAmenityChip('Hôtel'),
                    ActionChip(
                      avatar: const Icon(Icons.more_horiz, color: Colors.black),
                      label: Text('Plus'),
                      onPressed: () {
                        Provider.of<BottomNavBarVisibilityProvider>(context,
                                listen: false)
                            .hideBottomNav();
                        setState(() {
                          _isLayerVisible = true;
                          _showingAllAmenities = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isLayerVisible && _showingAllAmenities) _buildAllAmenitiesView(),
          if ((_isLayerVisible && suggestedPlaces.isNotEmpty) ||
              _isLayerVisible && suggestedAmenities.isNotEmpty)
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
                      }
                    }
                    return false;
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Affichage des amenities
                        /*if (_searchHistory.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _searchHistory.length,
                              itemBuilder: (context, index) {
                                final placeName = _searchHistory[index];
                                return ListTile(
                                  leading: const Icon(Icons.history),
                                  title: Text(place.name),
                                  subtitle: Text(place.amenity ?? ''),
                                  onTap: () {
                                    _onSuggestionTap(place)
                                  },
                                );
                              },
                            ),
                          ),*/
                        if (suggestedAmenities.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: suggestedAmenities.length,
                              itemBuilder: (context, index) {
                                final amenity = suggestedAmenities[index];
                                return ListTile(
                                  leading: const Icon(Icons.category),
                                  title: Text(amenity),
                                  onTap: () {
                                    _onAmenityTap(amenity);
                                  },
                                );
                              },
                            ),
                          ),

                        // Affichage des places
                        if (suggestedPlaces.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: suggestedPlaces.length,
                              itemBuilder: (context, index) {
                                final place = suggestedPlaces[index];
                                return ListTile(
                                  leading: const Icon(Icons.place),
                                  title: Text(place.name),
                                  subtitle: Text(place.amenity ?? ''),
                                  onTap: () {
                                    _onSuggestionTap(place);
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_isLayerVisible)
            Positioned(
              top: 140.0,
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
          if (fittingPlaces.isNotEmpty && !_isPlacePresentationSheetVisible)
            PlaceListSheet(
                initialHeight: MediaQuery.of(context).size.height * 0.45,
                fullHeight: MediaQuery.of(context).size.height * 0.95,
                midHeight: MediaQuery.of(context).size.height * 0.45,
                collapsedHeight: 100.0,
                onClose: () {
                  Provider.of<BottomNavBarVisibilityProvider>(context,
                          listen: false)
                      .showBottomNav();
                  setState(() {
                    _controller.clear();
                    fittingPlaces = [];
                  });
                },
                onFittingPlaceTap: (Place selectedPlace) {
                  _onSuggestionTap(selectedPlace);
                },
                title: _selectedAmenity ?? '',
                places: fittingPlaces),
          if (_selectedPlace != null &&
              _routes.isEmpty &&
              _tramPolyLinesPoints.isEmpty)
            if (_isPlacePresentationSheetVisible && !_isLayerVisible)
              PlacePresentationSheet(
                height: _bottomSheetHeight,
                onDragUpdate: (dy) {
                  setState(() {
                    _bottomSheetHeight -= dy;
                  });
                },
                onDragEnd: () {
                  final List<double> positions = [
                    MediaQuery.of(context).size.height * 0.95,
                    MediaQuery.of(context).size.height * 0.45,
                    MediaQuery.of(context).size.height * 0.2,
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
                place: _selectedPlace!,
                onItineraryTap: () {
                  _fetchRoutesForAllModes(_selectedPlace!);
                  setState(() {
                    _loadedPlaces = [];
                  });
                },
                onCallTap: () async {
                  final phoneNumber = _selectedPlace!.tags["phone"];
                  if (phoneNumber != null && phoneNumber.isNotEmpty) {
                    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      // Show a snackbar or dialog if the call can't be made
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Impossible de passer l\'appel')),
                        );
                      }
                    }
                  } else {
                    // Show a snackbar if no phone number is available
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Aucun numéro de téléphone disponible')),
                      );
                    }
                  }
                },
                onWebsiteTap: () async {
                  final website = _selectedPlace!.tags["website"];
                  if (website != null && website is String && website.isNotEmpty) {
                    final Uri websiteUri = Uri.parse(website);
                    if (await canLaunchUrl(websiteUri)) {
                      await launchUrl(websiteUri,
                          mode: LaunchMode.externalApplication);
                    } else {
                      // Show a snackbar or dialog if the website can't be opened
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Impossible d\'ouvrir le site web')),
                        );
                      }
                    }
                  } else {
                    // Show a snackbar if no website is available
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Aucun site web disponible')),
                      );
                    }
                  }
                },
                onInfosTap: () {
                  print(_selectedPlace!);
                  setState(() {
                    _isPlaceInfoSheetVisible = true;
                    _isPlacePresentationSheetVisible = false;
                  });
                },
                onClose: () {
                  setState(() {
                    _selectedPlace = null;
                    _isPlacePresentationSheetVisible = false;
                    _controller.text = "";
                  });

                  if (fittingPlaces.isEmpty) {
                    Provider.of<BottomNavBarVisibilityProvider>(context,
                            listen: false)
                        .showBottomNav();
                  }
                },
              ),
          if (_routes.isNotEmpty)
            ItinerarySheet(
              initialHeight: MediaQuery.of(context).size.height * 0.45,
              fullHeight: MediaQuery.of(context).size.height * 0.95,
              midHeight: MediaQuery.of(context).size.height * 0.45,
              collapsedHeight: 100.0,
              routes: _routes, // Routes pour tous les modes
              routesInstructions: _routesInstructions,
              elevationData: _elevationData,
              transitWays: _transitWays,
              indexInTransitWays: -1, //par défaut
              initialDistance: _routes['car']!['distance'],
              initialDuration: _routes['car']!['duration'],
              initialMode: 'car',
              onItineraryModeSelected: (String mode) {
                // rajouter un paramètre int qui stocke l'index dans la liste des transitWays (-1 si mode != 'transit')
                if (mode != 'tram') {
                  setState(() {
                    _tramPolyLinesPoints = [];
                    _walkTramPoints = [];
                    _routePoints = (_routes[mode]!['path'] as List)
                        .map((coord) =>
                            LatLng(coord[1].toDouble(), coord[0].toDouble()))
                        .toList();
                  });
                } else {
                  // Nous devons trouver la ligne de tram et extraire les points entre le départ et l'arrivée
                  setState(() {
                    _routePoints = [];

                    // Récupérons d'abord la ligne de tram concernée
                    String tramLineName = _transitWays[0]["tram"]["line"];
                    TramLine? targetLine = tramLines
                        .firstWhere((line) => line.name == tramLineName);

                    // Position de départ et d'arrivée
                    LatLng startPos = LatLng(
                        _transitWays[0]["tram"]["steps"][0]["position"]["Lat"],
                        _transitWays[0]["tram"]["steps"][0]["position"]
                            ["Long"]);

                    // Récupérer le dernier élément de la liste des étapes
                    var lastIndex = _transitWays[0]["tram"]["steps"].length - 1;
                    LatLng endPos = LatLng(
                        _transitWays[0]["tram"]["steps"][lastIndex]["position"]
                            ["Lat"],
                        _transitWays[0]["tram"]["steps"][lastIndex]["position"]
                            ["Long"]);

                    // Trouvons les indices des points les plus proches dans la ligne de tram
                    int startIndex = 0;
                    int endIndex = 0;
                    double minStartDist = double.infinity;
                    double minEndDist = double.infinity;

                    // Parcourons tous les points de la ligne pour trouver les plus proches
                    for (int i = 0; i < targetLine.points.length; i++) {
                      var point = targetLine.points[i];

                      // Calculons les distances avec le point de départ
                      double startDist = _calculateDistance(point, startPos);
                      if (startDist < minStartDist) {
                        minStartDist = startDist;
                        startIndex = i;
                      }

                      // Et avec le point d'arrivée
                      double endDist = _calculateDistance(point, endPos);
                      if (endDist < minEndDist) {
                        minEndDist = endDist;
                        endIndex = i;
                      }
                    }

                    // Assurons-nous que startIndex est bien avant endIndex
                    if (startIndex > endIndex) {
                      var temp = startIndex;
                      startIndex = endIndex;
                      endIndex = temp;
                    }

                    // Extrayons la sous-liste des points entre départ et arrivée
                    var extractedPoints =
                        targetLine.points.sublist(startIndex, endIndex + 1);

                    // Mettons à jour _tramPolyLinesPoints avec la nouvelle ligne
                    _tramPolyLinesPoints = [
                      Tuple2(targetLine.color, extractedPoints)
                    ];
                    // Extraction des chemins à pied
                    List<List<LatLng>> walkingPaths = [];

                    walkingPaths
                        .add(_transitWays[0]["walkToTram"]["wayPoints"]);
                    walkingPaths
                        .add(_transitWays[0]["tramToWalk"]["wayPoints"]);

                    _walkTramPoints = walkingPaths;
                    _routePoints = [];
                  });
                }
              },
              onClose: () {
                setState(() {
                  _routePoints = [];
                  _routes = {};
                  _routesInstructions = {};
                  _transitWays = [];
                  _tramPolyLinesPoints = [];
                  _walkTramPoints = [];
                });
              },
            ),
          if (_isPlaceInfoSheetVisible && !_isPlacePresentationSheetVisible)
            PlaceInfoSheet(
              height: _bottomSheetHeight,
              onDragUpdate: (dy) {
                setState(() {
                  _bottomSheetHeight -= dy;
                });
              },
              onDragEnd: () {
                final List<double> positions = [
                  MediaQuery.of(context).size.height * 0.95,
                  MediaQuery.of(context).size.height * 0.45,
                  MediaQuery.of(context).size.height * 0.2,
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
              place: _selectedPlace!,
              onClose: () {
                setState(() {
                  _isPlaceInfoSheetVisible = false;
                  _isPlacePresentationSheetVisible = true;
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
    _locationService.stopListening();
    _mapEventSubscription?.cancel();
    super.dispose();
  }

  // Add the _buildAmenityChip method
  Widget _buildAmenityChip(String amenity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(amenity),
        onPressed: () => _onAmenityTap(amenity),
      ),
    );
  }

  // Method to build the all amenities view
  Widget _buildAllAmenitiesView() {
    // Get the keys from GlobalData.amenities map and sort them alphabetically
    List<String> amenityKeys = GlobalData.amenities.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toutes les catégories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isLayerVisible = false;
                      _showingAllAmenities = false;
                    });
                    Provider.of<BottomNavBarVisibilityProvider>(context,
                            listen: false)
                        .showBottomNav();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.0,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: amenityKeys.length,
                itemBuilder: (context, index) {
                  String amenityKey = amenityKeys[index];
                  String amenityValue =
                      GlobalData.amenities[amenityKey] ?? amenityKey;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _isLayerVisible = false;
                        _showingAllAmenities = false;
                      });
                      _onAmenityTap(amenityKey);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          amenityKey,
                          style: const TextStyle(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

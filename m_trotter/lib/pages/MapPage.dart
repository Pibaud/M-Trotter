import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/LocationService.dart';
import 'dart:async';
import '../providers/BottomNavBarVisibilityProvider.dart';
import 'package:provider/provider.dart';

class MapPage extends StatefulWidget {
  final bool focusOnSearch;

  const MapPage({super.key, required this.focusOnSearch});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FocusNode _focusNode = FocusNode(); // FocusNode pour le TextField
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  Timer? _debounce;
  double _rotationAngle = 0.0; // Initialiser l'angle de rotation
  TextEditingController _controller = TextEditingController();
  List<String> _suggestions = [];
  bool _isLayerVisible =
      false; // Booléen pour contrôler l'affichage du layer blanc
  LatLng?
      _lieuSelectionne; // Variable pour stocker la localisation du lieu sélectionné
  List<LatLng> _routePoints = []; // Liste pour stocker les points du trajet
  double _bottomSheetHeight = 100.0; // Hauteur initiale de la "modal"
  late double _distance;
  late double _duration;

  final Map<String, LatLng> _lieuxCoordonnees = {
    'tokyoburger': LatLng(43.611, 3.876),
    'mcdonaldsComedie': LatLng(43.8, 3.9765),
    'leclocher': LatLng(43.612, 3.877),
    'laopportunite': LatLng(43.613, 3.878),
    // Ajoutez d'autres lieux ici...
  };

  @override
  void initState() {
    super.initState();
    if (widget.focusOnSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus(); // Donne le focus au TextField
        setState(() {
          _isLayerVisible = true; // Affiche le layer blanc au début
        });
      });
    }
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
    final String url = 'http://192.168.1.46:3000/api/places';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'data': input}),
      );

      if (response.statusCode == 200) {
        print('Réponse du serveur : ${response.body}');

        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('places')) {
          setState(() {
            _suggestions = List<String>.from(responseData['places']);
          });
        } else {
          print('Aucune liste de places trouvée.');
        }
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

  void _onSuggestionTap(String lieu) {
    _controller.text = lieu; // Mise à jour du champ texte
    _focusNode.unfocus();
    setState(() {
      _suggestions.clear();
      _isLayerVisible = false;
    });

    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .hideBottomNav();

    LatLng? destination = _lieuxCoordonnees[lieu];
    if (destination != null) {
      setState(() {
        _lieuSelectionne = destination; // Mettre à jour le lieu sélectionné
        _mapController.move(destination, 15.0); // Centrer la carte sur le lieu
      });
    }
  }

  void _itineraire(String lieu, {String mode = 'car'}) async {
    LatLng depart = LatLng(43.610769, 3.876716);
    LatLng destination = _lieuxCoordonnees[lieu]!;
    String url = 'http://192.168.1.46:3000/api/routes?'
        'startLat=${depart.latitude}&startLon=${depart.longitude}&'
        'endLat=${destination.latitude}&endLon=${destination.longitude}&'
        'mode=$mode';

    try {
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          List<dynamic> path = responseData['path'];
          List<LatLng> routePoints = [];
          for (var point in path) {
            var coords = point;
            LatLng latLng = LatLng(coords[1], coords[0]);
            routePoints.add(latLng);
          }

          setState(() {
            _routePoints = routePoints;
            _distance = responseData['distance'];
            _duration = responseData['duration'];
          });
        }
      } else {
        print('Erreur du serveur : ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi de la requête : $e');
    }
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
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _bottomSheetHeight -= details.delta.dy;
                  });
                },
                onVerticalDragEnd: (details) {
                  // Liste des hauteurs prédéfinies
                  final List<double> positions = [
                    100.0, // Version réduite
                    MediaQuery.of(context).size.height * 0.45, // Milieu
                    MediaQuery.of(context).size.height, // Plein écran
                  ];

                  // Trouver la position la plus proche
                  double closestPosition = positions.reduce((a, b) =>
                      (a - _bottomSheetHeight).abs() <
                              (b - _bottomSheetHeight).abs()
                          ? a
                          : b);

                  // Ajuster la hauteur à la position la plus proche
                  setState(() {
                    _bottomSheetHeight = closestPosition;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _bottomSheetHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Poignée pour indiquer la possibilité de glisser
                      Container(
                        width: 40.0,
                        height: 6.0,
                        margin: const EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _lieuxCoordonnees.entries
                                    .firstWhere((entry) =>
                                        entry.value == _lieuSelectionne)
                                    .key,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10.0),
                              const Text(
                                'Type du lieu',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 20.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      String lieuNom = _lieuxCoordonnees.entries
                                          .firstWhere((entry) =>
                                              entry.value == _lieuSelectionne)
                                          .key;
                                      _itineraire(lieuNom);
                                    },
                                    child: const Text('Itinéraire'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      print("Appeler le lieu sélectionné");
                                    },
                                    child: const Text('Appeler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      print(
                                          "Ouvrir le site web du lieu sélectionné");
                                    },
                                    child: const Text('Site Web'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_routePoints.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _bottomSheetHeight -= details.delta.dy;
                  });
                },
                onVerticalDragEnd: (details) {
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
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: _bottomSheetHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            blurRadius: 10.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Poignée pour glisser
                          Container(
                            width: 40.0,
                            height: 6.0,
                            margin: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Itinéraire',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Text(
                                    'Distance : ${_distance < 1000 ? '${_distance} m' : '${(_distance / 1000).toStringAsFixed(2)} km'}',
                                  ),
                                  Text(
                                      'Durée : ${(_duration / 60).toStringAsFixed(0)} minutes'),
                                  const SizedBox(height: 20.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.directions_car),
                                        onPressed: () {
                                          _itineraire(
                                              _lieuxCoordonnees.entries
                                                  .firstWhere((entry) =>
                                                      entry.value ==
                                                      _lieuSelectionne)
                                                  .key,
                                              mode: 'car');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.directions_walk),
                                        onPressed: () {
                                          _itineraire(
                                              _lieuxCoordonnees.entries
                                                  .firstWhere((entry) =>
                                                      entry.value ==
                                                      _lieuSelectionne)
                                                  .key,
                                              mode: 'foot');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.directions_bike),
                                        onPressed: () {
                                          _itineraire(
                                              _lieuxCoordonnees.entries
                                                  .firstWhere((entry) =>
                                                      entry.value ==
                                                      _lieuSelectionne)
                                                  .key,
                                              mode: 'bike');
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.directions_transit),
                                        onPressed: () {
                                          _itineraire(
                                              _lieuxCoordonnees.entries
                                                  .firstWhere((entry) =>
                                                      entry.value ==
                                                      _lieuSelectionne)
                                                  .key,
                                              mode: 'transit');
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ajout de la croix pour fermer
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _routePoints = [];
                          });
                        },
                        child: const Icon(Icons.close, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Layer blanc lorsque la recherche est active
          if (_isLayerVisible)
            Container(
              color: Colors.white, // Blanc avec opacité
            ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 8.0, right: 8.0),
            child: TextField(
              controller: _controller, // Utiliser le contrôleur
              focusNode: _focusNode, // Associe le TextField au FocusNode
              onTap: () {
                // Affiche le layer blanc lorsque l'utilisateur tape sur le TextField
                setState(() {
                  _isLayerVisible = true;
                });

                Provider.of<BottomNavBarVisibilityProvider>(context,
                        listen: false)
                    .hideBottomNav();
              },
              decoration: InputDecoration(
                hintText: 'Où voulez-vous aller ?',
                prefixIcon: GestureDetector(
                  onTap: () {
                    if (_isLayerVisible) {
                      setState(() {
                        _isLayerVisible = false; // Désactiver le layer blanc
                        _focusNode.unfocus(); // Perdre le focus
                        _controller.clear();
                        _suggestions.clear();
                        _lieuSelectionne = null;
                      });

                      // Réafficher la BottomNavigationBar
                      Provider.of<BottomNavBarVisibilityProvider>(context,
                              listen: false)
                          .showBottomNav();
                    }
                  },
                  child: Icon(
                    _isLayerVisible
                        ? Icons.arrow_back
                        : Icons.search, // Icône conditionnelle
                  ),
                ),
                suffixIcon: _lieuSelectionne != null
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            _lieuSelectionne =
                                null; // Réinitialiser le lieu sélectionné
                            _controller
                                .clear(); // Réinitialiser le texte de la barre
                            _routePoints = [];
                          });
                          // Montrer la BottomNavigationBar lorsque la sélection est réinitialisée
                          Provider.of<BottomNavBarVisibilityProvider>(context,
                                  listen: false)
                              .showBottomNav();
                        },
                        child: const Icon(Icons.clear), // Icône de croix
                      )
                    : null,
                filled: true, // Permet de remplir le fond avec une couleur
                fillColor: Colors.white, // Couleur de fond blanc
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(20.0), // Rayon des coins arrondi
                ),
              ),
              onChanged: _onTextChanged, // Appeler la fonction debounce
            ),
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
                        _focusNode
                            .unfocus(); // Retire le focus dès qu'un défilement commence
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

  @override
  void dispose() {
    _focusNode.dispose(); // Libère le FocusNode
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'LocationService.dart';
import 'dart:async';

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
  bool _isSearchFocused = false;

  final Map<String, LatLng> _lieuxCoordonnees = {
    'tokyoburger': LatLng(43.611, 3.876),
    'mcdonaldsComedie': LatLng(43.6115, 3.8765),
    'leclocher': LatLng(43.612, 3.877),
    'laopportunite': LatLng(43.613, 3.878),
    // Ajoutez d'autres lieux ici...
  };

  @override
  void initState() {
    super.initState();
    print("MapPage initState called. focusOnSearch = ${widget.focusOnSearch}");
    // Si le paramètre focusOnSearch est vrai, activer le focus
    if (widget.focusOnSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus(); // Donne le focus au TextField
      });
    }

    // Ajouter un listener pour détecter le focus sur le TextField
    _focusNode.addListener(() {
      setState(() {});
    });
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

  void _onSuggestionTap(String lieu) async {
    // Coordonnées de départ (Montpellier)
    LatLng depart = LatLng(43.610769, 3.876716);

    // Coordonnées du lieu sélectionné
    LatLng destination = _lieuxCoordonnees[lieu]!;

    // Construire l'URL avec les paramètres de la requête
    String url = 'http://192.168.0.49:3000/api/routes?'
        'startLat=${depart.latitude}&startLon=${depart.longitude}&'
        'endLat=${destination.latitude}&endLon=${destination.longitude}&'
        'mode=foot';

    // Envoi de la requête HTTP avec l'URL contenant les paramètres de la requête
    try {
      final response = await http
          .get(Uri.parse(url)); // Utiliser http.get au lieu de http.post

      if (response.statusCode == 200) {
        print('Réponse du serveur : ${response.body}');
        // Traite la réponse du serveur pour afficher l'itinéraire ou autre action
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
            ],
          ),
          // Layer blanc lorsque la recherche est active
          if (_focusNode.hasFocus)
            Container(
              color: Colors.white.withOpacity(0.8), // Blanc avec opacité
            ),
          Padding(
            padding: const EdgeInsets.only(top: 30.0, left: 8.0, right: 8.0),
            child: TextField(
              controller: _controller, // Utiliser le contrôleur
              focusNode: _focusNode, // Associe le TextField au FocusNode
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
          // Affichage des suggestions
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 100.0,
              left: 8.0,
              right: 8.0,
              bottom: 0.0,
              child: Material(
                color: Colors.transparent,
                child: Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_suggestions[index]),
                        onTap: () {
                          // Appeler la fonction pour envoyer la requête avec le lieu sélectionné
                          _onSuggestionTap(_suggestions[index]);

                          // Mettre à jour le champ de recherche
                          _controller.text = _suggestions[index];
                          _focusNode.unfocus();
                          setState(() {
                            _suggestions.clear();
                          });
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

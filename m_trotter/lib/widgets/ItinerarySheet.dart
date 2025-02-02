import 'package:flutter/material.dart';

class ItinerarySheet extends StatefulWidget {
  final double initialHeight;
  final double fullHeight;
  final double midHeight;
  final double collapsedHeight;
  final Function(String mode) onItineraryModeSelected;
  final Function onClose;
  final Map<String, dynamic> routes; // Stocke tous les itinéraires
  final double initialDistance;
  final double initialDuration;
  final String initialMode; // Ajout du mode initial (ex. "car")

  const ItinerarySheet({
    Key? key,
    required this.initialHeight,
    required this.fullHeight,
    required this.midHeight,
    required this.collapsedHeight,
    required this.onItineraryModeSelected,
    required this.onClose,
    required this.routes, // Routes pour tous les modes
    required this.initialDistance,
    required this.initialDuration,
    required this.initialMode, // Nouveau paramètre pour le mode initial
  }) : super(key: key);

  @override
  _ItinerarySheetState createState() => _ItinerarySheetState();
}

class _ItinerarySheetState extends State<ItinerarySheet> {
  late double _currentHeight;
  late double _distance;
  late double _duration;
  late Map<String, dynamic> _routes;
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _distance = widget.initialDistance;
    _duration = widget.initialDuration;
    _routes = widget.routes; // Initialiser les routes pour tous les modes
    _selectedMode = widget.initialMode; // Initialiser le mode sélectionné
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentHeight -= details.delta.dy;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final List<double> positions = [
      widget.collapsedHeight,
      widget.midHeight,
      widget.fullHeight,
    ];

    double closestPosition = positions.reduce((a, b) =>
        (a - _currentHeight).abs() < (b - _currentHeight).abs() ? a : b);

    setState(() {
      _currentHeight = closestPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _currentHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Column(
                children: [
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
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10.0),
                          // Affichage de la distance (arrondi)
                          Text(
                            'Distance : ${_distance < 1000 ? '${_distance.ceil()} m' : '${(_distance / 1000).ceil()} km'}',
                          ),
                          // Affichage de la durée (arrondi)
                          Text(
                            'Durée : ${(_duration / 60).ceil()} minutes',
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment
                                .spaceEvenly, // Espacement des icônes
                            children: [
                              _buildModeIcon('car', Icons.directions_car),
                              _buildModeIcon('foot', Icons.directions_walk),
                              _buildModeIcon('bike', Icons.directions_bike),
                              _buildModeIcon(
                                  'tram', Icons.train), // Icône du tram
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => widget.onClose(),
                child: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Construction d'un bouton pour chaque mode avec un contour bleu pour le mode sélectionné
  Widget _buildModeIcon(String mode, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _updateItinerary(mode);
        });
        widget.onItineraryModeSelected(mode);
      },
      child: Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: _selectedMode == mode
                ? Colors.blue
                : Colors
                    .grey[300], // Remplissage gris clair pour non sélectionné
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            color: _selectedMode == mode
                ? Colors.white
                : Colors.grey[700], // Icône en gris foncé pour non sélectionné
          ),
        ),
      ),
    );
  }

// Mise à jour des informations d'itinéraire pour un mode donné
  void _updateItinerary(String mode) {
    final route =
        _routes[mode]; // Récupère les itinéraires pour le mode sélectionné
    if (route != null) {
      setState(() {
        _distance = route['distance'];
        _duration = route['duration'];
      });
    }
  }
}
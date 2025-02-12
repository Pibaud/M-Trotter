import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';

class ItinerarySheet extends StatefulWidget {
  final double initialHeight;
  final double fullHeight;
  final double midHeight;
  final double collapsedHeight;
  final Function(String mode) onItineraryModeSelected;
  final Function onClose;
  final Map<String, dynamic> routes; // Stocke tous les itinéraires
  final Map<String, dynamic> routesInstructions;
  final Map<String, Tuple2<double, double>> elevationData;
  final List<dynamic> transitWays;
  final int indexInTransitWays;
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
    required this.routesInstructions,
    required this.elevationData,
    required this.transitWays,
    required this.indexInTransitWays,
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
  late Map<String, dynamic> _routesInstructions;
  late Map<String, Tuple2<double, double>> _elevationData;
  late List<dynamic> _transitWays;
  late int _indexInTransitWays;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _distance = widget.initialDistance;
    _duration = widget.initialDuration;
    _routes = widget.routes; // Initialiser les routes pour tous les modes
    _selectedMode = widget.initialMode; // Initialiser le mode sélectionné
    _routesInstructions =
        widget.routesInstructions; // Initialisation des instructions
    _elevationData =
        widget.elevationData; // Initialisation des données d'élevation
    _transitWays = widget.transitWays;
    _indexInTransitWays = widget.indexInTransitWays;
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
                          Text(
                            'Distance : ${_distance < 1000 ? '${_distance.ceil()} m' : '${(_distance / 1000).ceil()} km'}',
                          ),
                          Text(
                            'Durée : ${_duration >= 3600 ? (_duration ~/ 3600).toString() + ' h ' : ''}${(_duration % 3600) ~/ 60} minutes',
                          ),
                          if (_selectedMode == 'foot' ||
                              _selectedMode == 'bike')
                            Text(
                              '${_getDifficultyLevel(_elevationData[_selectedMode]?.item1 ?? 0, _elevationData[_selectedMode]?.item2 ?? 0)} ${_elevationData[_selectedMode]?.item1.ceil() ?? 0} m ascendant / ${_elevationData[_selectedMode]?.item2.ceil() ?? 0} m descendant',
                            ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildModeIcon('car', Icons.directions_car),
                              _buildModeIcon('foot', Icons.directions_walk),
                              _buildModeIcon('bike', Icons.directions_bike),
                              _buildModeIcon('tram', Icons.train),
                            ],
                          ),
                          const SizedBox(height: 20.0),
                          Text(
                            'Instructions :',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10.0),
                          _buildInstructionsList(),
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

  Widget _buildModeIcon(String mode, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _updateItinerary(mode);
        });
        widget.onItineraryModeSelected(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: _selectedMode == mode ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          icon,
          color: _selectedMode == mode ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  String _getDifficultyLevel(double ascend, double descend) {
    double totalElevation = ascend + descend;

    if (totalElevation < 100) {
      return 'Généralement plat';
    } else if (totalElevation < 500) {
      return 'Dénivelé modéré';
    } else {
      return 'Grand dénivelé';
    }
  }

  void _updateItinerary(String mode) {
    final route = _routes[mode];
    if (route != null) {
      setState(() {
        _distance = route['distance'];
        _duration = route['duration'];
      });
    }
  }

  Widget _buildInstructionsList() {
    List instructions = _routesInstructions[_selectedMode] ?? [];

    return Expanded(
      child: ListView.builder(
        itemCount: instructions.length,
        itemBuilder: (context, index) {
          var instruction = instructions[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (instruction['distance'] != null)
                    Text('Sur ${instruction['distance'].ceil()} mètres, '),
                  if (instruction['text'] != null)
                    Text('${instruction['text']}'),
                  if (instruction['time'] != null)
                    Text('Pendant ${((instruction['time'])/1000).ceil()} minutes'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

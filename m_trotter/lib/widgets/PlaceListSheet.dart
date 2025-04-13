import 'package:flutter/material.dart';
import 'package:m_trotter/models/Place.dart';
import 'package:tuple/tuple.dart';

class PlaceListSheet extends StatefulWidget {
  final double initialHeight;
  final double fullHeight;
  final double midHeight;
  final double collapsedHeight;
  final Function onClose;
  final Function(Place) onFittingPlaceTap;
  final String title;
  final List<Place> places;

  const PlaceListSheet({
    Key? key,
    required this.initialHeight,
    required this.fullHeight,
    required this.midHeight,
    required this.collapsedHeight,
    required this.onClose,
    required this.onFittingPlaceTap,
    required this.title,
    required this.places,
  }) : super(key: key);

  @override
  _PlaceListSheetState createState() => _PlaceListSheetState();
}

class _PlaceListSheetState extends State<PlaceListSheet> {
  late double _currentHeight;
  late String _title;
  late List<Place> _places;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
    _title = widget.title;
    _places = widget.places;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _currentHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12, // Updated  color
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête avec titre et bouton fermer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => widget.onClose(),
                    ),
                  ],
                ),
              ),

              // Séparateur
              const Divider(),

              // Liste des places
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _places.length,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${place.amenity}'),
                            Text(
                              'Coordonnées: ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onFittingPlaceTap(place);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

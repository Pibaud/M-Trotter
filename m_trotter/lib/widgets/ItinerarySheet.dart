import 'package:flutter/material.dart';

class ItinerarySheet extends StatefulWidget {
  final double initialHeight;
  final double fullHeight;
  final double midHeight;
  final double collapsedHeight;
  final Function(String mode) onItineraryModeSelected;
  final Function onClose;
  final double distance;
  final double duration;

  const ItinerarySheet({
    Key? key,
    required this.initialHeight,
    required this.fullHeight,
    required this.midHeight,
    required this.collapsedHeight,
    required this.onItineraryModeSelected,
    required this.onClose,
    required this.distance,
    required this.duration,
  }) : super(key: key);

  @override
  _ItinerarySheetState createState() => _ItinerarySheetState();
}

class _ItinerarySheetState extends State<ItinerarySheet> {
  late double _currentHeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.initialHeight;
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
                            'Distance : ${widget.distance < 1000 ? '${widget.distance} m' : '${(widget.distance / 1000).toStringAsFixed(2)} km'}',
                          ),
                          Text(
                            'Durée : ${(widget.duration / 60).toStringAsFixed(0)} minutes',
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.directions_car),
                                onPressed: () => widget.onItineraryModeSelected('car'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions_walk),
                                onPressed: () => widget.onItineraryModeSelected('foot'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions_bike),
                                onPressed: () => widget.onItineraryModeSelected('bike'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.directions_transit),
                                onPressed: () => widget.onItineraryModeSelected('transit'),
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
}

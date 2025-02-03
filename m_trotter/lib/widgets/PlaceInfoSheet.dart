import 'package:flutter/material.dart';

class PlaceInfoSheet extends StatelessWidget {
  final double height;
  final Function(double) onDragUpdate;
  final Function() onDragEnd;
  final String placeName;
  final String placeType;
  final Function() onItineraryTap;
  final Function() onCallTap;
  final Function() onWebsiteTap;
  final Function() onClose; // Nouvelle fonction pour fermer

  const PlaceInfoSheet({
    Key? key,
    required this.height,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.placeName,
    required this.placeType,
    required this.onItineraryTap,
    required this.onCallTap,
    required this.onWebsiteTap,
    required this.onClose, // Nouvelle fonction
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
        onVerticalDragEnd: (_) => onDragEnd(),
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: height,
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
                          Text(
                            placeName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            placeType,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: onItineraryTap,
                                child: const Text('Itinéraire'),
                              ),
                              TextButton(
                                onPressed: onCallTap,
                                child: const Text('Appeler'),
                              ),
                              TextButton(
                                onPressed: onWebsiteTap,
                                child: const Text('Site Web'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  //Expanded(
                  //)
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

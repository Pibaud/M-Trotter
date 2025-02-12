import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../models/TramStop.dart';

class TramLine {
  final String number;
  final String name;
  final String direction;
  final String color;
  List<TramStop> stops;
  final List<LatLng> points;

  TramLine({
    required this.number,
    required this.name,
    required this.direction,
    required this.color,
    required this.stops,
    required this.points,
  });

  factory TramLine.fromJson(
      Map<String, dynamic> json, List<TramStop> allStops) {
    var lineId = json['properties']['num_exploitation'].toString();
    String nomLigne = json['properties']['nom_ligne'];
    String direction = _extractDirection(nomLigne);

    List<TramStop> filteredStops = _filterStops(json, allStops);
    List<LatLng> linePoints = (json['geometry']['coordinates'] as List)
        .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
        .toList();

    // Déterminer le stop de départ en fonction du nom de la ligne
    String? startingStopName = _getStartingStopName(nomLigne);
    TramStop? startingStop = filteredStops.firstWhere(
      (stop) => stop.name == startingStopName,
      orElse: () => filteredStops.first,
    );

    // Trier les stops par distance en utilisant un algorithme simple (proche voisin)
    List<TramStop> orderedStops =
        _orderStopsByDistance(startingStop, filteredStops);

    return TramLine(
      number: lineId,
      name: nomLigne,
      direction: direction,
      color: json['properties']['code_couleur'],
      stops: orderedStops,
      points: linePoints,
    );
  }

  static String? _getStartingStopName(String lineName) {
    final stopMapping = {
      'L1 Mosson > Odysseum': 'Mosson',
      'L1 Odysseum > Mosson': 'Odysseum',
      'L2 Saint-Jean de Védas Centre > Jacou': 'Saint-Jean de Védas Centre',
      'L2 Jacou > Saint-Jean de Védas Centre': 'Jacou',
      'L3 Pérols Étang de l\'Or > Juvignac': 'Pérols Étang de l\'Or',
      'L3 Juvignac > Lattes Centre': 'Juvignac',
      'L3 Juvignac > Pérols Étang de l\'Or': 'Juvignac',
      'L3 Lattes Centre > Juvignac': 'Lattes Centre',
      'L4 Garcia Lorca > Garcia Lorca A': 'Garcia Lorca',
      'L4 Garcia Lorca > Garcia Lorca B': 'Garcia Lorca',
    };
    return stopMapping[lineName];
  }

  static String _extractDirection(String nomLigne) {
    RegExp regex = RegExp(r'(?:>\s*| - )\s*(.*)');
    Match? match = regex.firstMatch(nomLigne);
    return match != null ? match.group(1) ?? '' : '';
  }

  static List<TramStop> _filterStops(
      Map<String, dynamic> json, List<TramStop> allStops) {
    var lineId = json['properties']['num_exploitation'].toString();
    String lineDirection =
        json['properties']['nom_ligne'].split(' > ').last.trim();

    String normalizeDirection(String direction) {
      return direction
          .replaceAll(RegExp(r'\s*sens \s*[AB]', caseSensitive: false), '')
          .replaceAll(RegExp(r'[-/]'), '')
          .trim()
          .toLowerCase();
    }

    String normalizedLineDirection = normalizeDirection(lineDirection);

    return allStops.where((stop) {
      if (!stop.lines.contains(lineId)) return false;
      return stop.directions.any((direction) {
        String normalizedStopDirection = normalizeDirection(direction);
        return normalizedStopDirection.contains(normalizedLineDirection);
      });
    }).toList();
  }

  static List<TramStop> _orderStopsByDistance(
      TramStop? startingStop, List<TramStop> stops) {
    if (startingStop == null) return stops;

    List<TramStop> orderedStops = [];
    Set<TramStop> remainingStops = Set.from(stops);
    TramStop currentStop = startingStop;
    final Distance distance = Distance();

    while (remainingStops.isNotEmpty) {
      orderedStops.add(currentStop);
      remainingStops.remove(currentStop);

      if (remainingStops.isEmpty) break;

      // Trouver l'arrêt le plus proche
      TramStop nearestStop = remainingStops.reduce((a, b) => distance.as(
                  LengthUnit.Meter, currentStop.position, a.position) <
              distance.as(LengthUnit.Meter, currentStop.position, b.position)
          ? a
          : b);

      currentStop = nearestStop;
    }

    return orderedStops;
  }
}

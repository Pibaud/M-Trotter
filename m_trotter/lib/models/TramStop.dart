import 'package:latlong2/latlong.dart';

class TramStop {
  final String name;
  final LatLng position;
  final List<String> lines; // String pas objet TramLine !!!
  final List<String> directions;

  TramStop({
    required this.name,
    required this.position,
    required this.lines,
    required this.directions,
  });

  factory TramStop.fromJson(Map<String, dynamic> json) {
    return TramStop(
      name: json['properties']['description'],
      position: LatLng(
        json['geometry']['coordinates'][1],
        json['geometry']['coordinates'][0],
      ),
      lines: ((json['properties']['lignes_passantes'] ?? '') as String)
          .split(RegExp(r'[ ,;]+'))
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim())
          .toList(),
      directions: ((json['properties']['lignes_et_directions'] ?? '') as String)
          .split(';')
          .where((direction) => direction.trim().isNotEmpty)
          .map((direction) => direction.trim())
          .toList(),
    );
  }
}

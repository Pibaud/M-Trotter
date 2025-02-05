import 'package:latlong2/latlong.dart';

class TramStop {
  final String name;
  final LatLng position;
  final List<String> lines; // String pas objet TramLine !!!
  final String direction;

  TramStop({
    required this.name,
    required this.position,
    required this.lines,
    required this.direction,
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
      direction:
          json['properties']['lignes_et_directions'].split(';').last.trim(),
    );
  }
}

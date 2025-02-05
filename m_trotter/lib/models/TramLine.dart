import '../models/TramStop.dart';

class TramLine {
  final String number;
  final String name;
  final String direction;
  final String color;
  final List<TramStop> stops;

  TramLine({
    required this.number,
    required this.name,
    required this.direction,
    required this.color,
    required this.stops,
  });

  factory TramLine.fromJson(Map<String, dynamic> json, List<TramStop> allStops) {
    var lineId = json['properties']['num_exploitation'].toString(); // Conversion en String

    // Filtrage des arrêts de la ligne
    List<TramStop> filteredStops = allStops.where((stop) {
      // Extraire la direction de la ligne
      String lineDirection = json['properties']['nom_ligne'].split(' > ').last.trim();

      // Extraire toutes les directions de l'arrêt
      List<String> stopDirections = stop.direction
          .split(';')
          .map((e) => e.split(' ').last.trim()) // Garder la dernière partie de la direction
          .toList();

      // Vérifier si la direction de la ligne correspond à l'une des directions de l'arrêt
      return stop.lines.contains(lineId) &&
             stopDirections.contains(lineDirection);
    }).toList();

    // Extraction du nom de la ligne
    String nomLigne = json['properties']['nom_ligne'];

    // Expression régulière pour extraire la direction après le ">"
    RegExp regex = RegExp(r'>\s*(.*)');
    Match? match = regex.firstMatch(nomLigne);

    // Si la direction est trouvée, on l'extrait, sinon on garde une valeur vide
    String direction = match != null ? match.group(1) ?? '' : '';

    // Affichage des informations pour débogage
    print("Created tram line: $nomLigne dans le sens $direction");
    for (var stop in filteredStops) {
      print("Stop for this line: ${stop.name} with direction ${stop.direction}");
    }

    // Retour de l'objet TramLine
    return TramLine(
      number: json['properties']['num_exploitation'].toString(),
      name: nomLigne,
      direction: direction, // On utilise la direction extraite
      color: json['properties']['code_couleur'],
      stops: filteredStops,
    );
  }
}

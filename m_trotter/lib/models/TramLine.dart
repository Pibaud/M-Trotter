import 'dart:ffi';

import '../models/TramStop.dart';
import 'package:latlong2/latlong.dart';

class TramLine {
  final String number;
  final String name;
  final String direction;
  final String color;
  List<TramStop> stops;
  final List<LatLng> points;
  static List<dynamic> orderL1Odysseum = [
    "Mosson",
    "Stade de la Mosson",
    "Halles de la Paillade",
    "Saint-Paul",
    "Hauts de Massane",
    "Euromédecine",
    "Malbosc - Domaine d'Ô",
    "Château d'Ô",
    "Occitanie",
    "Hôpital Lapeyronie",
    "Universités Sciences et Lettres",
    "Saint-Éloi",
    "Boutonnet - Cité des Arts",
    "Stade Philippidès",
    "Place Albert 1er - Saint-Charles",
    "Louis Blanc - Agora de la Danse",
    "Corum",
    "Comédie",
    "Gare Saint-Roch",
    "Du Guesclin",
    "Antigone",
    "Léon Blum",
    "Place de l'Europe",
    "Rives du Lez",
    "Moularès (Hôtel de Ville)",
    "Port Marianne",
    "Mondial 98",
    "Millénaire",
    "Place de France",
    "Odysseum",
  ];
  static List<dynamic> orderL1Mosson =
      orderL1Odysseum.reversed.toList(); //reverse orderL1Odysseum

  static List<dynamic> orderL2Jacou = [
    "Saint-Jean de Védas Centre",
    "Saint-Jean le Sec",
    "La Condamine",
    "Victoire 2",
    "Sabines",
    "Villeneuve d'Angoulême",
    "Croix d'Argent",
    "Mas Drevon",
    "Lemasson",
    "Saint-Cléophas",
    "Nouveau Saint-Roch",
    "Rondelet",
    "Gare Saint-Roch",
    "Comédie",
    "Corum",
    "Beaux-Arts",
    "Jeu de Mail des Abbés",
    "Aiguelongue",
    "Saint-Lazare",
    "Charles de Gaulle",
    "Clairval",
    "La Galine",
    "Centurions",
    "Notre-Dame de Sablassou",
    "Aube Rouge",
    "Via Domitia",
    "Georges Pompidou",
    "Jacou",
  ];

  static List<dynamic> orderL2SaintJeanDeVedasCentre =
      orderL2Jacou.reversed.toList();

  static List<dynamic> orderL3LattesCentre = [
    "Juvignac",
    "Mosson",
    "Celleneuve",
    "Pilory",
    "Hôtel du Département",
    "Pergola",
    "Tonnelles",
    "Jules Guesde",
    "Astruc",
    "Les Arceaux",
    "Plan Cabanes",
    "Saint-Denis",
    "Observatoire",
    "Gare Saint-Roch - République",
    "Place Carnot",
    "Voltaire",
    "Rives du Lez - Consuls de Mer",
    "Moularès (Hôtel de Ville)",
    "Port Marianne",
    "Pablo Picasso",
    "Boirargues",
    "Cougourlude",
    "Lattes Centre"
  ];

  static List<dynamic> orderL3JuvignacFromLattesCentre =
      orderL3LattesCentre.reversed.toList();

  static List<dynamic> orderL3PerolsEtangDeLOr = [
    "Juvignac",
    "Mosson",
    "Celleneuve",
    "Pilory",
    "Hôtel du Département",
    "Pergola",
    "Tonnelles",
    "Jules Guesde",
    "Astruc",
    "Les Arceaux",
    "Plan Cabanes",
    "Saint-Denis",
    "Observatoire",
    "Gare Saint-Roch - République",
    "Place Carnot",
    "Voltaire",
    "Rives du Lez - Consuls de Mer",
    "Moularès (Hôtel de Ville)",
    "Port Marianne",
    "Pablo Picasso",
    "Boirargues",
    "EcoPôle",
    "Parc Expo",
    "Pérols Centre",
    "Pérols Étang de l'Or"
  ];

  static List<dynamic> orderL3JuvignacFromPerolsEtangDeLOr =
      orderL3PerolsEtangDeLOr.reversed.toList();

  static List<dynamic> orderl4A = [
    "Garcia Lorca",
    "Restanque",
    "Saint-Martin",
    "Nouveau Saint-Roch",
    "Rondelet",
    "Gare Saint-Roch - République",
    "Observatoire",
    "Saint-Guilhem - Courreau",
    "Peyrou - Arc de Triomphe",
    "Albert 1er - Cathédrale",
    "Louis Blanc - Agora de la Danse",
    "Corum",
    "Les Aubes",
    "Pompignane",
    "Place de l'Europe",
    "Rives du Lez",
    "Georges Frêche - Hôtel de Ville",
    "La Rauze",
    "Garcia Lorca"
  ];

  static List<dynamic> orderl4B = orderl4A.reversed.toList();

  TramLine({
    required this.number,
    required this.name,
    required this.direction,
    required this.color,
    required this.stops,
    required this.points,
  });

  bool _matchesOrder(List<dynamic> orderList) {
    // Comparer les noms des arrêts dans stops avec l'ordre de orderList
    List<String> stopNames = stops.map((stop) => stop.name).toList();
    return stopNames.toSet().containsAll(orderList.toSet()) &&
        stopNames.length == orderList.length;
  }

  void reorderStops() {
    List<List<dynamic>> orderedLists = [
      orderL1Odysseum,
      orderL1Mosson,
      orderL2SaintJeanDeVedasCentre,
      orderL2Jacou,
      orderL3LattesCentre,
      orderL3JuvignacFromLattesCentre,
      orderL3PerolsEtangDeLOr,
      orderL3JuvignacFromPerolsEtangDeLOr,
      orderl4A,
      orderl4B
    ];

    for (var orderList in orderedLists) {
      if (_matchesOrder(orderList)) {
        // Réorganiser les arrêts de cette ligne selon l'ordre trouvé
        stops.sort((a, b) {
          int indexA = orderList.indexOf(a.name);
          int indexB = orderList.indexOf(b.name);
          return indexA.compareTo(indexB); // Comparaison pour trier les arrêts
        });
        break;
      }
    }
  }

  factory TramLine.fromJson(
      Map<String, dynamic> json, List<TramStop> allStops) {
    var lineId = json['properties']['num_exploitation'].toString();

    // Extraire la direction principale de la ligne
    String lineDirection =
        json['properties']['nom_ligne'].split(' > ').last.trim();

    // Nettoyage et normalisation des directions
    String normalizeDirection(String direction) {
      return direction
          .replaceAll(RegExp(r'\s*sens \s*[AB]', caseSensitive: false), '')
          .replaceAll(RegExp(r'[-/]'), '')
          .trim()
          .toLowerCase();
    }

    String normalizedLineDirection = normalizeDirection(lineDirection);

    // Filtrage des arrêts
    List<TramStop> filteredStops = allStops.where((stop) {
      if (!stop.lines.contains(lineId)) return false;

      return stop.directions.any((direction) {
        String normalizedStopDirection = normalizeDirection(direction);
        return normalizedStopDirection.contains(normalizedLineDirection);
      });
    }).toList();

    // Extraction des points à partir des coordonnées de GeoJSON
    List<LatLng> linePoints = (json['geometry']['coordinates'] as List)
        .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
        .toList();

    String nomLigne = json['properties']['nom_ligne'];

    // Regex pour extraire la direction avec ">" ou " - " mais uniquement si entouré d'espaces
    RegExp regex = RegExp(r'(?:>\s*| - )\s*(.*)');
    Match? match = regex.firstMatch(nomLigne);

    String direction = match != null ? match.group(1) ?? '' : '';

    //mise en ordre des points

    TramLine tramLine = TramLine(
      number: lineId,
      name: nomLigne,
      direction: direction,
      color: json['properties']['code_couleur'],
      stops: filteredStops,
      points: linePoints,
    );

    // Réorganiser les arrêts après la création de l'objet
    tramLine.reorderStops();

    // Retourner l'objet avec les arrêts réorganisés
    return tramLine;
  }
}

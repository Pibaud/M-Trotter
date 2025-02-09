import 'dart:ffi';

import '../models/TramStop.dart';
import 'package:latlong2/latlong.dart';

class TramLine {
  final String number;
  final String name;
  final String direction;
  final String color;
  final List<TramStop> stops;
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

    // Filtrage des arrêts de la ligne
    List<TramStop> filteredStops = allStops.where((stop) {
      String lineDirection =
          json['properties']['nom_ligne'].split(' > ').last.trim();

      return stop.lines.contains(lineId) &&
       stop.directions.any((direction) => direction.contains(lineDirection));

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
    List<dynamic> orderL1Odysseum = [
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

    List<dynamic> orderL1Mosson =
        orderL1Odysseum.reversed.toList(); //reverse orderL1Odysseum

    List<dynamic> orderL2Jacou = [
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

    List<dynamic> orderL2SaintJeanDeVedasCentre =
        orderL2Jacou.reversed.toList();

    List<dynamic> orderL3LattesCentre = [
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

    List<dynamic> orderL3JuvignacFromLattesCentre =
        orderL3LattesCentre.reversed.toList();

    List<dynamic> orderL3PerolsEtangDeLOr = [
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

    List<dynamic> orderL3JuvignacFromPerolsEtangDeLOr =
        orderL3PerolsEtangDeLOr.reversed.toList();

    List<dynamic> orderl4A = [
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

    List<dynamic> orderl4B = orderl4A.reversed.toList();

    orderl4A.insert(0, "Sens A");

    orderl4B.insert(0, "Sens B");

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
/*
    for (var line in orderedLists) { // pour chaque line
      bool bij = true;
      for (var stop in stops) { // pour chaque stop
        if (stop.direction == line[0]) { // s'ils ont la même direction
          if (!bij) { // on vérifie si on n'a pas déjà vu que le point n'est pas dans la liste
            break;
          } else {
            if (!(line.contains(stop.name))) {
              bij = false;
            }
          }
        }
      }
      if (bij) {
        //réordonner this.points selon l'ordre de la line
      }
    }*/

    return TramLine(
      number: lineId,
      name: nomLigne,
      direction: direction,
      color: json['properties']['code_couleur'],
      stops: filteredStops,
      points: linePoints,
    );
  }
}

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapInteractions {
  final MapController mapController;

  MapInteractions(this.mapController);

  void resetMapOrientation() {
    mapController.rotate(0); // Remet la rotation à 0° (nord en haut)
  }

  void centerOnCurrentLocation(LatLng? currentLocation) {
    if (currentLocation != null) {
      mapController.move(currentLocation, 14.5);
    } else {
      print("Position actuelle non disponible.");
    }
  }
}
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationService {

  /// Vérifie et demande les permissions nécessaires
  Future<bool> _handleLocationPermission() async {
    LocationPermission permission;

    // Vérifie si les services de localisation sont activés
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Les services de localisation sont désactivés.');
      return false;
    }

    // Vérifie et demande la permission d'accès à la localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permission de localisation refusée.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint(
          'Permission de localisation refusée de façon permanente. Accédez aux paramètres pour l’autoriser.');
      return false;
    }

    // Permission accordée
    return true;
  }

  /// Obtient la position actuelle de l'utilisateur
  Future<Position?> getCurrentPosition() async {
    // Vérifie et gère les permissions
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    // Configure les paramètres de localisation
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Précision élevée
      distanceFilter: 10, // Mise à jour après un déplacement de 10 mètres
    );

    // Récupère la position actuelle
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      return position;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position : $e');
      return null;
    }
  }
}
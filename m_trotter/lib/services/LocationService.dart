import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;

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
    print("Appel à getCurrentPosition...");
    // Vérifie et gère les permissions
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }
    print("Permission acceptée");
    // Configure les paramètres de localisation
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium, // Précision élevée
      distanceFilter: 10, // Mise à jour après un déplacement de 10 mètres
    );

    // Récupère la position actuelle
    try {
      print("Récupération du Geolocator...");
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      print("position retournée : $position");
      return position;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position : $e');
      return null;
    }
  }

  /// Écoute les changements de position
  StreamSubscription<Position> listenToPositionChanges({
    required Function(Position) onPositionUpdate,
    required Function(dynamic) onError,
  }) {
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium, // Précision élevée
      distanceFilter: 10, // Mise à jour après un déplacement de 10 mètres
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      onPositionUpdate,
      onError: onError,
    );

    return _positionStreamSubscription!;
  }

  /// Arrête le suivi de la position
  void stopListening() {
    _positionStreamSubscription?.cancel();
  }
}
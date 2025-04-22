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

    // Récupère la position actuelle
    try {
      print("Récupération du Geolocator...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Remplace locationSettings
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
    if (_positionStreamSubscription != null) {
      debugPrint('Écoute des changements de position déjà démarrée.');
      return _positionStreamSubscription!;
    }

    debugPrint('Démarrage de l\'écoute des changements de position...');
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.low, // Précision élevée
      distanceFilter: 10, // Mise à jour après un déplacement de 10 mètres
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        debugPrint('Position mise à jour dans le stream : $position');
        onPositionUpdate(position);
      },
      onError: (dynamic error) {
        debugPrint('Erreur de position dans le stream : $error');
        onError(error);
      },
    );

    debugPrint('Écoute des changements de position démarrée.');
    return _positionStreamSubscription!;
  }

  /// Arrête le suivi de la position
  void stopListening() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      debugPrint('Écoute des changements de position arrêtée.');
    } else {
      debugPrint('Aucune écoute des changements de position à arrêter.');
    }
  }
}

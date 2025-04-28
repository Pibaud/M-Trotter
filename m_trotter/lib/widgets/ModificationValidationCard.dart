import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../utils/GlobalData.dart';

class ModificationValidationCard extends StatelessWidget {
  final Map<String, dynamic> modification;
  final Function(int, bool) onValidationResponse;
  final Function() onDismiss;
  final LatLng? userLocation;

  const ModificationValidationCard({
    Key? key,
    required this.modification,
    required this.onValidationResponse,
    required this.onDismiss,
    this.userLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extract data from modification
    final String name = modification['name'] ?? 'Lieu sans nom';
    final int idModification = modification['id_modification'] ?? 0;
    final String champModifie = modification['champ_modifie'] ?? '';
    final String ancienneValeur = modification['ancienne_valeur'] ?? '';
    final String nouvelleValeur = modification['nouvelle_valeur'] ?? '';

    print('Ancienne valeur: $ancienneValeur, Nouvelle valeur: $nouvelleValeur');

    // Format the changes for display
    String formattedChanges = '';
    // Determine the type of modification
    String modificationHeading = 'Modifications proposées';

    if (champModifie == 'tags') {
      try {
        // Compare old and new values to highlight changes
        final Map<String, dynamic> oldTags = _parseTags(ancienneValeur);
        final Map<String, dynamic> newTags = _parseTags(nouvelleValeur);

        // Count the changes
        int addCount = 0;
        int modCount = 0;
        int delCount = 0;

        // Find modified tags
        for (final key in newTags.keys) {
          String cleanKey = key.replaceAll('"', '');
          String cleanValue = newTags[key].replaceAll('"', '');

          if (!oldTags.containsKey(key)) {
            //GlobalData.getTagKey(key)
            formattedChanges += '${GlobalData.getTagKey(cleanKey)}: $cleanValue\n';
            addCount++;
          } else if (oldTags[key] != newTags[key]) {
            String cleanOldValue = oldTags[key].replaceAll('"', '');
            formattedChanges += '${GlobalData.getTagKey(cleanKey)}: $cleanOldValue → $cleanValue\n';
            modCount++;
          }
        }

        // Find removed tags
        for (final key in oldTags.keys) {
          if (!newTags.containsKey(key)) {
            String cleanKey = key.replaceAll('"', '');
            String cleanValue = oldTags[key].replaceAll('"', '');
            formattedChanges += '- $cleanKey: $cleanValue\n';
            delCount++;
          }
        }

        // Determine heading based on the type of changes
        int totalChanges = addCount + modCount + delCount;
        if (totalChanges == 0) {
          modificationHeading = 'Pas de modification';
        } else if (addCount > 0 && modCount == 0 && delCount == 0) {
          modificationHeading = 'Nouvelle information';
        } else if (totalChanges == 1) {
          modificationHeading = 'Modification proposée';
        } else {
          modificationHeading = 'Modifications proposées';
        }

        if (formattedChanges.isEmpty) {
          formattedChanges = 'Pas de changements détectés';
        }
      } catch (e) {
        formattedChanges = 'Erreur d\'analyse des modifications';
        print('Error parsing tags: $e');
      }
    } else {
      // For non-tag modifications
      if (ancienneValeur.isEmpty && nouvelleValeur.isNotEmpty) {
        modificationHeading = 'Nouvelle information';
      } else {
        modificationHeading = 'Modification proposée';
      }
      formattedChanges = '$champModifie:\n$ancienneValeur → $nouvelleValeur';
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Un utilisateur a proposé cette modification',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  modificationHeading,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formattedChanges,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          onValidationResponse(idModification, true),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          onValidationResponse(idModification, false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to parse tags string into a Map
  Map<String, dynamic> _parseTags(String tagsString) {
    Map<String, dynamic> result = {};

    // Split by commas and process each tag
    final List<String> tagPairs = tagsString.split(', ');

    for (String pair in tagPairs) {
      // Remove quotes at start and end if needed
      if (pair.startsWith('"') && pair.endsWith('"')) {
        pair = pair.substring(1, pair.length - 1);
      }

      // Split by "=>" to get key and value
      final parts = pair.split('=>');
      if (parts.length == 2) {
        String key = parts[0].trim();
        String value = parts[1].trim();

        // Remove surrounding quotes if present
        if (key.startsWith('"') && key.endsWith('"')) {
          key = key.substring(1, key.length - 1);
        }
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        result[key] = value;
      }
    }

    return result;
  }
}

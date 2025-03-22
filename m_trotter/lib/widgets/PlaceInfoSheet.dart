import 'package:flutter/material.dart';
import 'package:m_trotter/models/Place.dart';

class PlaceInfoSheet extends StatelessWidget {
  final double height;
  final Function(double)? onDragUpdate;
  final Function()? onDragEnd;
  final Place place;
  final Function onClose;

  const PlaceInfoSheet({
    Key? key,
    required this.place,
    required this.onClose,
    required this.height,
    this.onDragUpdate,
    this.onDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) => onDragUpdate?.call(details.delta.dy),
        onVerticalDragEnd: (_) => onDragEnd?.call(),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
            ],
          ),
          child: Column(
            children: [
              // Barre de drag
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // En-tête avec titre et bouton fermer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => onClose(),
                    ),
                  ],
                ),
              ),

              // Séparateur
              const Divider(),

              // Informations sur le lieu
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    ListTile(
                      title: const Text('Type'),
                      subtitle: Text(place.amenity ?? 'N/A'),
                    ),
                    ListTile(
                      title: const Text('Coordonnées'),
                      subtitle: Text(
                          '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}'),
                    ),
                    if (place.phone != null)
                      ListTile(
                        title: const Text('Téléphone'),
                        subtitle: Text(place.phone!),
                      ),
                    if (place.cuisine != null)
                      ListTile(
                        title: const Text('Cuisine'),
                        subtitle: Text(place.cuisine!),
                      ),
                    if (place.website != null)
                      ListTile(
                        title: const Text('Site web'),
                        subtitle: Text(place.website!),
                      ),
                    if (place.email != null)
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(place.email!),
                      ),
                    if (place.city != null)
                      ListTile(
                        title: const Text('Ville'),
                        subtitle: Text(place.city!),
                      ),
                    if (place.street != null)
                      ListTile(
                        title: const Text('Rue'),
                        subtitle: Text(place.street!),
                      ),
                    if (place.postcode != null)
                      ListTile(
                        title: const Text('Code postal'),
                        subtitle: Text(place.postcode!),
                      ),
                    if (place.openingHours != null)
                      ListTile(
                        title: const Text('Heures d\'ouverture'),
                        subtitle: Text(place.openingHours!),
                      ),
                    if (place.wheelchairAccessible != null)
                      ListTile(
                        title: const Text('Accès fauteuil roulant'),
                        subtitle:
                            Text(place.wheelchairAccessible! ? 'Oui' : 'Non'),
                      ),
                    if (place.outdoorSeating != null)
                      ListTile(
                        title: const Text('Sièges extérieurs'),
                        subtitle: Text(place.outdoorSeating! ? 'Oui' : 'Non'),
                      ),
                    if (place.airConditioning != null)
                      ListTile(
                        title: const Text('Climatisation'),
                        subtitle: Text(place.airConditioning! ? 'Oui' : 'Non'),
                      ),
                    if (place.facebook != null)
                      ListTile(
                        title: const Text('Facebook'),
                        subtitle: Text(place.facebook!),
                      ),
                    if (place.operator != null)
                      ListTile(
                        title: const Text('Opérateur'),
                        subtitle: Text(place.operator!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

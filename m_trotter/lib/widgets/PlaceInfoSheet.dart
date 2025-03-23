import 'package:flutter/material.dart';
import 'package:m_trotter/models/Place.dart';
import '../services/ApiService.dart';

class PlaceInfoSheet extends StatefulWidget {
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
  _PlaceInfoSheetState createState() => _PlaceInfoSheetState();
}

class _PlaceInfoSheetState extends State<PlaceInfoSheet> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: (details) =>
            widget.onDragUpdate?.call(details.delta.dy),
        onVerticalDragEnd: (_) => widget.onDragEnd?.call(),
        child: Stack(
          children: [
            Container(
              height: widget.height,
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
                          widget.place.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => widget.onClose(),
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
                          title: const Text('Type du lieu'),
                          subtitle: Text(widget.place.amenity ?? 'N/A'),
                        ),
                        ListTile(
                          title: const Text('Adresse'),
                          subtitle: Text(
                              '${widget.place.latitude.toStringAsFixed(4)}, ${widget.place.longitude.toStringAsFixed(4)}'),
                        ),
                        if (widget.place.phone != null)
                          ListTile(
                            title: const Text('Téléphone'),
                            subtitle: Text(widget.place.phone!),
                          ),
                        if (widget.place.cuisine != null)
                          ListTile(
                            title: const Text('Cuisine'),
                            subtitle: Text(widget.place.cuisine!),
                          ),
                        if (widget.place.website != null)
                          ListTile(
                            title: const Text('Site web'),
                            subtitle: Text(widget.place.website!),
                          ),
                        if (widget.place.email != null)
                          ListTile(
                            title: const Text('Email'),
                            subtitle: Text(widget.place.email!),
                          ),
                        if (widget.place.city != null)
                          ListTile(
                            title: const Text('Ville'),
                            subtitle: Text(widget.place.city!),
                          ),
                        if (widget.place.street != null)
                          ListTile(
                            title: const Text('Rue'),
                            subtitle: Text(widget.place.street!),
                          ),
                        if (widget.place.postcode != null)
                          ListTile(
                            title: const Text('Code postal'),
                            subtitle: Text(widget.place.postcode!),
                          ),
                        if (widget.place.openingHours != null)
                          ListTile(
                            title: const Text('Heures d\'ouverture'),
                            subtitle: Text(widget.place.openingHours!),
                          ),
                        if (widget.place.wheelchairAccessible != null)
                          ListTile(
                            title: const Text('Accès fauteuil roulant'),
                            subtitle: Text(widget.place.wheelchairAccessible!
                                ? 'Oui'
                                : 'Non'),
                          ),
                        if (widget.place.outdoorSeating != null)
                          ListTile(
                            title: const Text('Sièges extérieurs'),
                            subtitle: Text(
                                widget.place.outdoorSeating! ? 'Oui' : 'Non'),
                          ),
                        if (widget.place.airConditioning != null)
                          ListTile(
                            title: const Text('Climatisation'),
                            subtitle: Text(
                                widget.place.airConditioning! ? 'Oui' : 'Non'),
                          ),
                        if (widget.place.facebook != null)
                          ListTile(
                            title: const Text('Facebook'),
                            subtitle: Text(widget.place.facebook!),
                          ),
                        if (widget.place.operator != null)
                          ListTile(
                            title: const Text('Opérateur'),
                            subtitle: Text(widget.place.operator!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
                child: Icon(isEditing ? Icons.check : Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

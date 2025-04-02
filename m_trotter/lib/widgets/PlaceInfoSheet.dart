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
  bool isFavorite = false;
  List<Map<String, String>> modifications = [];
  String? selectedAmenity;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    bool favoriteStatus = await _apiService.estFavoris(osmId: widget.place.id);
    setState(() {
      isFavorite = favoriteStatus;
    });
  }

  Future<void> _toggleFavorite() async {
    if (isFavorite) {
      await _apiService.deleteFavoris(osmId:widget.place.id);
    } else {
      await _apiService.addFavoris(osmId:widget.place.id);
    }

    setState(() {
      isFavorite = !isFavorite;
    });
  }

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
                          subtitle:
                              Text(isEditing ? '' : widget.place.amenity!), // s
                        ),
                        if (isEditing)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 1.0),
                            child: DropdownButton<String>(
                              value: selectedAmenity,
                              hint: Text('Sélectionner un type de lieu'),
                              items: GlobalData.amenities.keys
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedAmenity = newValue;
                                  modifications.add({
                                    'champ_modifie': 'amenity',
                                    'ancienne_valeur': widget.place.amenity!,
                                    'nouvelle_valeur': selectedAmenity!,
                                  });
                                });
                              },
                            ),
                          ),
                        if (widget.place.tags['addr:city'] != null ||
                            widget.place.tags['addr:street'] != null ||
                            widget.place.tags['addr:postcode'] != null)
                          ListTile(
                            title: const Text('Adresse'),
                            subtitle: Text(
                                '${widget.place.houseNumber} ${widget.place.tags['addr:street']}, ${widget.place.tags['addr:postcode']}, ${widget.place.tags['addr:city']}'),
                          ),
                        if (isEditing) ...[
                          TextField(
                            controller: TextEditingController(
                                text: widget.place.houseNumber.toString()),
                            onChanged: (newValue) {
                              setState(() {
                                modifications.add({
                                  'champ_modifie': 'houseNumber',
                                  'ancienne_valeur':
                                      '"addr:housenumber"=>"${widget.place.houseNumber}"',
                                  'nouvelle_valeur':
                                      '"addr:housenumber"=>"$newValue"',
                                });
                              });
                            },
                          ),
                          TextField(
                            controller: TextEditingController(
                                text: widget.place.tags['addr:street']),
                            onChanged: (newValue) {
                              setState(() {
                                modifications.add({
                                  'champ_modifie': 'tags',
                                  'ancienne_valeur':
                                      '"addr:street"=>"${widget.place.tags['addr:street']}"',
                                  'nouvelle_valeur':
                                      '"addr:street"=>"$newValue"',
                                });
                              });
                            },
                          ),
                          TextField(
                            controller: TextEditingController(
                                text: widget.place.tags['addr:postcode']),
                            onChanged: (newValue) {
                              setState(() {
                                modifications.add({
                                  'champ_modifie': 'tags',
                                  'ancienne_valeur':
                                      '"addr:postcode"=>"${widget.place.tags['addr:postcode']}"',
                                  'nouvelle_valeur':
                                      '"addr:postcode"=>"$newValue"',
                                });
                              });
                            },
                          ),
                          TextField(
                            controller: TextEditingController(
                                text: widget.place.tags['addr:city']),
                            onChanged: (newValue) {
                              setState(() {
                                modifications.add({
                                  'champ_modifie': 'tags',
                                  'ancienne_valeur':
                                      '"addr:city"=>"${widget.place.tags['addr:city']}"',
                                  'nouvelle_valeur': '"addr:city"=>"$newValue"',
                                });
                              });
                            },
                          ),
                        ],
                        if (widget.place.tags['phone'] != null)
                          ListTile(
                            title: const Text('Téléphone'),
                            subtitle: isEditing
                                ? TextField(
                                    controller: TextEditingController(
                                        text: widget.place.tags['phone']),
                                    onChanged: (newValue) {
                                      setState(() {
                                        modifications.add({
                                          'champ_modifie': 'tags',
                                          'ancienne_valeur':
                                              '"phone"=>"${widget.place.tags['phone']}"',
                                          'nouvelle_valeur':
                                              '"phone"=>"$newValue"',
                                        });
                                      });
                                    },
                                  )
                                : Text(widget.place.tags['phone']!),
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
                onPressed: () async {
                  if (isEditing) {
                    // Call proposeModifications method
                    await ApiService().proposeModifications(
                      osmId: widget.place.id,
                      modifications: modifications,
                    );
                  }
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


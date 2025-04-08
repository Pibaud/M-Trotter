import 'package:flutter/material.dart';
import 'package:m_trotter/models/Place.dart';
import '../services/ApiService.dart';
import '../utils/GlobalData.dart';

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
  List<Map<String, String>> modifications = [];
  String? selectedAmenity;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
  }

/*
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
                                          //chercher dans tags l'occurrence de phone
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
}*/

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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20.0)),
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
                              fontSize: 20, fontWeight: FontWeight.bold),
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

                  // Partie principale : ListView qui contient tous les tags
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
                        // Afficher les tags importants en tout temps (même s'ils sont vides)
                        ...buildImportantTags(),

                        // Afficher les autres tags (qui peuvent être en mode édition ou lecture)
                        ...buildOtherTags(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bouton de modification
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () async {
                  if (isEditing) {
                    // Appeler la méthode proposeModifications si on est en mode édition
                    await ApiService().proposeModifications(
                      osmId: widget.place.id,
                      modifications: modifications,
                    );
                    setState(() {
                      modifications.clear();
                    });
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

// Fonction pour afficher les tags importants
  List<Widget> buildImportantTags() {
    return [
      // Adresse (affiché en tout temps)
      ListTile(
        title: const Text('Adresse'),
        subtitle: isEditing
            ? buildEditableAddress() // Afficher un champ pour éditer en mode édition
            : Text(
                '${widget.place.houseNumber ?? 'Non spécifié'} ${widget.place.tags['addr:street'] ?? 'Non spécifié'}, ${widget.place.tags['addr:postcode'] ?? 'Non spécifié'}, ${widget.place.tags['addr:city'] ?? 'Non spécifié'}',
              ),
      ),
      // Téléphone (affiché en tout temps)
      if (widget.place.tags['phone'] != null)
        ListTile(
          title: const Text('Téléphone'),
          subtitle: isEditing
              ? buildEditablePhone() // Afficher un champ pour éditer en mode édition
              : Text(widget.place.tags['phone'] ?? 'Non spécifié'),
        ),
    ];
  }

// Fonction pour afficher tous les autres tags
  List<Widget> buildOtherTags() {
    return widget.place.tags.entries
        .where((entry) => ![
      'addr:street',
      'addr:postcode',
      'addr:city',
      'phone'
    ].contains(entry.key)) // Exclure les tags importants
        .map((entry) {
      TextEditingController controller = TextEditingController(text: entry.value);

      return ListTile(
        title: Text(entry.key),
        subtitle: isEditing
            ? TextField(
            controller: controller,
            onSubmitted: (newValue) {
              if (newValue.isNotEmpty) {
                updateTag(entry.key, newValue);
              }
            }
        )
            : Text(entry.value ?? 'Non spécifié'), // En mode lecture
      );
    }).toList();
  }

// Fonction pour mettre à jour un tag lorsqu'on est en mode édition
  void updateTag(String key, String newValue) {
    // Vérifier si la nouvelle valeur est différente de l'ancienne
    if (widget.place.tags[key] != newValue) {
      // Récupérer l'état des tags avant de modifier
      String oldTags = widget.place.tags.entries
          .map((entry) => '"${entry.key}"=>"${entry.value}"')
          .join(', ');

      // Créer une copie des tags avec la nouvelle valeur
      Map<String, String> updatedTags = Map.from(widget.place.tags);
      updatedTags[key] = newValue;

      // Récupérer l'état des tags après la modification
      String newTags = updatedTags.entries
          .map((entry) => '"${entry.key}"=>"${entry.value}"')
          .join(', ');

      // Ajouter les modifications à la liste avec les anciennes et nouvelles valeurs
      modifications.add({
        'champ_modifie': "tags",
        'ancienne_valeur': oldTags,
        'nouvelle_valeur': newTags,
      });
    }
  }

  Widget buildEditableAddress() {
    TextEditingController houseNumberController = TextEditingController(text: widget.place.houseNumber?.toString() ?? '');
    TextEditingController streetController = TextEditingController(text: widget.place.tags['addr:street'] ?? '');
    TextEditingController postcodeController = TextEditingController(text: widget.place.tags['addr:postcode'] ?? '');
    TextEditingController cityController = TextEditingController(text: widget.place.tags['addr:city'] ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: houseNumberController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:housenumber', newValue);
            }
          },
          decoration: const InputDecoration(labelText: 'Numéro de maison'),
        ),
        TextField(
          controller: streetController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:street', newValue);
            }
          },
          decoration: const InputDecoration(labelText: 'Rue'),
        ),
        TextField(
          controller: postcodeController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:postcode', newValue);
            }
          },
          decoration: const InputDecoration(labelText: 'Code Postal'),
        ),
        TextField(
          controller: cityController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:city', newValue);
            }
          },
          decoration: const InputDecoration(labelText: 'Ville'),
        ),
      ],
    );
  }

// Fonction pour afficher le téléphone modifiable en mode édition
  Widget buildEditablePhone() {
    TextEditingController controller = TextEditingController(text: widget.place.tags['phone'] ?? '');

    return TextField(
      controller: controller,
      onSubmitted: (newValue) {
        if (newValue.isNotEmpty) {
          updateTag('phone', newValue);
        }
      },
      decoration: const InputDecoration(labelText: 'Téléphone'),
    );
  }
}

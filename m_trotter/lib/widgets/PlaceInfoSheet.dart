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
  TextEditingController newTagKeyController = TextEditingController();
  TextEditingController newTagValueController = TextEditingController();
  bool showTagInputs = false;
  Map<String, String>? _originalTags;
  Map<String, String> _updatedTags = {};

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
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
                              fontSize: 15, fontWeight: FontWeight.bold),
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
                            child: Column(
                              children: [
                                DropdownButton<String>(
                                  value: selectedAmenity,
                                  hint: Text('Choisir un type de lieu'),
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
                                        'ancienne_valeur':
                                            widget.place.amenity!,
                                        'nouvelle_valeur': selectedAmenity!,
                                      });
                                    });
                                  },
                                ),
                                const Divider(height: 1, color: Colors.black12),
                              ],
                            ),
                          ),
                        // Afficher les tags importants en tout temps (même s'ils sont vides)
                        ...buildImportantTags(),

                        // Afficher les autres tags (qui peuvent être en mode édition ou lecture)
                        ...buildOtherTags(),
                        if (isEditing)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 1, color: Colors.black12),
                                if (!showTagInputs)
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("Ajouter un nouveau tag"),
                                    onPressed: () {
                                      setState(() {
                                        showTagInputs = true;
                                      });
                                    },
                                  ),
                                if (showTagInputs) ...[
                                  const Text('Ajouter un nouveau tag',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextField(
                                    controller: newTagKeyController,
                                    decoration: InputDecoration(
                                      labelText: 'Nom du tag',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: newTagValueController,
                                    decoration: InputDecoration(
                                      labelText: 'Valeur du tag',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                    ),
                                    onSubmitted: (_) {
                                      final key =
                                          newTagKeyController.text.trim();
                                      final value =
                                          newTagValueController.text.trim();
                                      if (key.isNotEmpty && value.isNotEmpty) {
                                        updateTag(key, value);
                                        newTagKeyController.clear();
                                        newTagValueController.clear();
                                        setState(() {
                                          showTagInputs = false;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'N° : ${widget.place.houseNumber == -1 ? 'Non spécifié' : widget.place.houseNumber}'),
                  Text(
                      'Rue : ${widget.place.tags['addr:street'] ?? 'Non spécifiée'}'),
                  Text(
                      'Code Postal : ${widget.place.tags['addr:postcode'] ?? 'Non spécifié'}'),
                  Text(
                      'Ville : ${widget.place.tags['addr:city'] ?? 'Non spécifiée'}'),
                ],
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
    final List<Widget> widgets = [];

    for (var entry in widget.place.tags.entries.where((entry) => ![
          'addr:street',
          'addr:postcode',
          'addr:city',
          'phone'
        ].contains(entry.key))) {
      TextEditingController controller =
          TextEditingController(text: entry.value);

      widgets.add(ListTile(
        title: Text(entry.key),
        subtitle: isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onSubmitted: (newValue) {
                  if (newValue.isNotEmpty) {
                    updateTag(entry.key, newValue);
                  }
                })
            : Text(entry.value ?? 'Non spécifié'),
      ));

      if (isEditing) {
        widgets.add(const Divider(height: 1, color: Colors.black12));
      }
    }

    return widgets;
  }

  Map<String, String> _parseTagString(String tagString) {
    final tagMap = <String, String>{};
    final reg = RegExp(r'"(.*?)"=>"(.*?)"');
    for (final match in reg.allMatches(tagString)) {
      tagMap[match.group(1)!] = match.group(2)!;
    }
    return tagMap;
  }

// Fonction pour mettre à jour un tag lorsqu'on est en mode édition
  void updateTag(String key, String newValue) {
    final oldValue = widget.place.tags[key];
    if (oldValue == newValue) return;

    // 1. Appliquer la modification
    widget.place.tags[key] = newValue;

    // 2. Préparer la nouvelle valeur complète
    final newTagsStr = widget.place.tags.entries
        .map((e) => '"${e.key}"=>"${e.value}"')
        .join(', ');

    // 3. Chercher si ce tag a déjà été modifié précédemment
    bool existingTagModification = false;
    String? originalValue = oldValue;

    for (int i = 0; i < modifications.length; i++) {
      final modif = modifications[i];
      if (modif['champ_modifie'] == 'tags') {
        final oldModifTagsMap = _parseTagString(modif['ancienne_valeur']!);
        final newModifTagsMap = _parseTagString(modif['nouvelle_valeur']!);

        //! Vérifier si ce tag spécifique a été modifié dans cette entrée
        Set<String> changedKeys = {};
        for (String k in {...oldModifTagsMap.keys, ...newModifTagsMap.keys}) {
          if (oldModifTagsMap[k] != newModifTagsMap[k]) {
            changedKeys.add(k);
          }
        }

        // Si cette modification précédente concerne seulement notre tag actuel
        if (changedKeys.length == 1 && changedKeys.contains(key)) {
          // Récupérer la valeur originale du tag
          originalValue = oldModifTagsMap[key];

          // Supprimer cette modification
          modifications.removeAt(i);
          existingTagModification = true;
          break; // On a trouvé et traité la modification existante
        }
      }
    }

    // 4. Créer un snapshot avec la valeur originale
    final originalTagsMap = Map<String, String>.from(widget.place.tags);
    // Restaurer la valeur originale dans ce snapshot
    if (originalValue != null) {
      originalTagsMap[key] = originalValue;
    } else {
      // Si le tag n'existait pas à l'origine
      originalTagsMap.remove(key);
    }

    final originalTagsStr = originalTagsMap.entries
        .map((e) => '"${e.key}"=>"${e.value}"')
        .join(', ');

    // 5. Ajouter la nouvelle modification avec la valeur originale
    modifications.add({
      'champ_modifie': "tags",
      'ancienne_valeur': originalTagsStr,
      'nouvelle_valeur': newTagsStr,
    });

    print("✅ Modification proposée avec succès");

    setState(() {});
  }

  Widget buildEditableAddress() {
    TextEditingController houseNumberController = TextEditingController(
        text: widget.place.houseNumber == -1
            ? ''
            : widget.place.houseNumber.toString());
    TextEditingController streetController =
        TextEditingController(text: widget.place.tags['addr:street'] ?? '');
    TextEditingController postcodeController =
        TextEditingController(text: widget.place.tags['addr:postcode'] ?? '');
    TextEditingController cityController =
        TextEditingController(text: widget.place.tags['addr:city'] ?? '');

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
          decoration: InputDecoration(
            labelText: 'N°',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: streetController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:street', newValue);
            }
          },
          decoration: InputDecoration(
            labelText: 'Rue',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: postcodeController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:postcode', newValue);
            }
          },
          decoration: InputDecoration(
            labelText: 'Code Postal',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: cityController,
          onSubmitted: (newValue) {
            if (newValue.isNotEmpty) {
              updateTag('addr:city', newValue);
            }
          },
          decoration: InputDecoration(
            labelText: 'Ville',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

// Fonction pour afficher le téléphone modifiable en mode édition
  Widget buildEditablePhone() {
    TextEditingController controller =
        TextEditingController(text: widget.place.tags['phone'] ?? '');

    return TextField(
      controller: controller,
      onSubmitted: (newValue) {
        if (newValue.isNotEmpty) {
          updateTag('phone', newValue);
        }
      },
      decoration: InputDecoration(
        labelText: 'Téléphone',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

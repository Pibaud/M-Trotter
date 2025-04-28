import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
                                        'ancienne_valeur': GlobalData.amenities[widget.place.amenity!] ?? 'unknown',
                                        'nouvelle_valeur': GlobalData.amenities[selectedAmenity!] ?? 'unknown',
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
                                  Autocomplete<String>(
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return const Iterable<String>.empty();
                                      }
                                      return GlobalData.tags.keys
                                          .where((String option) {
                                        return option.toLowerCase().contains(
                                            textEditingValue.text
                                                .toLowerCase());
                                      }).take(5); // Limite à 5 suggestions
                                    },
                                    onSelected: (String selection) {
                                      // Quand une suggestion est sélectionnée, on remplit les champs
                                      newTagKeyController.text = selection;
                                      // On prérempli avec la valeur suggérée par défaut si disponible
                                      newTagValueController.text = '';
                                    },
                                    fieldViewBuilder: (context,
                                        textEditingController,
                                        focusNode,
                                        onFieldSubmitted) {
                                      // On met à jour notre controller externe pour l'accès en dehors du widget
                                      newTagKeyController =
                                          textEditingController;

                                      return TextField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Rechercher un tag',
                                          hintText:
                                              'Commencez à taper pour voir les suggestions',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 10),
                                          suffixIcon: const Icon(Icons.search),
                                        ),
                                        onSubmitted: (_) => onFieldSubmitted(),
                                      );
                                    },
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
                                      final key = GlobalData.tags[
                                          newTagKeyController.text.trim()];
                                      final value =
                                          newTagValueController.text.trim();
                                      if (key!.isNotEmpty && value.isNotEmpty) {
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
      ListTile(
        title: const Text('Horaires d\'ouverture'),
        subtitle: isEditing
            ? OpeningHoursEditor(
                initialValue: widget.place.tags['opening_hours'],
                onSaved: (newValue) {
                  updateTag('opening_hours', newValue);
                },
              )
            : (widget.place.tags['opening_hours'] != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _parseOpeningHours(widget.place.tags['opening_hours']!)
                            .map((entry) => Text(
                                  '${entry['day']} : ${entry['hours']}',
                                  style: const TextStyle(fontSize: 14),
                                ))
                            .toList(),
                  )
                : const Text('Non spécifié')),
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
          'phone',
          'opening_hours',
        ].contains(entry.key))) {
      // Fix the null check issue by providing a default value
      String title = GlobalData.getTagKey(entry.key);
      TextEditingController controller =
          TextEditingController(text: entry.value);

      widgets.add(ListTile(
        title: Text(title),
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

  List<Map<String, String>> _parseOpeningHours(String openingHours) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    final result = <Map<String, String>>[];

    // Split the opening_hours string into individual segments
    final segments = openingHours.split(';');
    final dayHoursMap = <String, String>{};

    for (final segment in segments) {
      final regex =
          RegExp(r'([A-Za-z]{2})(?:-([A-Za-z]{2}))?\s([\d:, -]+|off)');
      final match = regex.firstMatch(segment.trim());

      if (match != null) {
        final startDay = match.group(1);
        final endDay = match.group(2);
        final hours = match.group(3);

        if (hours == 'off') {
          if (endDay != null) {
            final startIndex = days.indexOf(startDay!);
            final endIndex = days.indexOf(endDay);

            for (int i = startIndex; i <= endIndex; i++) {
              dayHoursMap[days[i]] = 'fermé';
            }
          } else {
            dayHoursMap[startDay!] = 'fermé';
          }
        } else {
          if (endDay != null) {
            final startIndex = days.indexOf(startDay!);
            final endIndex = days.indexOf(endDay);

            for (int i = startIndex; i <= endIndex; i++) {
              dayHoursMap[days[i]] = hours!;
            }
          } else {
            dayHoursMap[startDay!] = hours!;
          }
        }
      } else {
        print('No match for segment: $segment');
      }
    }

    // Populate result for all days
    for (final day in days) {
      result.add({
        'day': _dayToFrench(day),
        'hours': dayHoursMap[day] ?? 'fermé',
      });
    }
    return result;
  }

// Add this helper function to translate days to French
  String _dayToFrench(String day) {
    switch (day) {
      case 'Mo':
        return 'Lundi';
      case 'Tu':
        return 'Mardi';
      case 'We':
        return 'Mercredi';
      case 'Th':
        return 'Jeudi';
      case 'Fr':
        return 'Vendredi';
      case 'Sa':
        return 'Samedi';
      case 'Su':
        return 'Dimanche';
      default:
        return day;
    }
  }
}

class OpeningHoursEditor extends StatefulWidget {
  final String? initialValue;
  final Function(String) onSaved;

  const OpeningHoursEditor({
    Key? key,
    this.initialValue,
    required this.onSaved,
  }) : super(key: key);

  @override
  _OpeningHoursEditorState createState() => _OpeningHoursEditorState();
}

class _OpeningHoursEditorState extends State<OpeningHoursEditor> {
  final List<String> days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  final Map<String, List<TimeRange>> dayRanges = {};

  final List<String> availableTimes = List.generate(48, (i) {
    final hour = (i ~/ 2).toString().padLeft(2, '0');
    final minute = (i % 2) * 30;
    return '$hour:${minute.toString().padLeft(2, '0')}';
  });

  @override
  void initState() {
    super.initState();
    for (var day in days) {
      dayRanges[day] = [];
    }
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _parseExisting(widget.initialValue!);
    }
  }

  void _parseExisting(String str) {
    final segments = str.split(';');
    final regex = RegExp(r'([A-Za-z]{2})(?:-([A-Za-z]{2}))?\s(.+)');

    for (final segment in segments) {
      if (segment.trim().isEmpty) continue;

      final match = regex.firstMatch(segment.trim());
      if (match != null) {
        final startDay = match.group(1)!;
        final endDay = match.group(2);
        final hours = match.group(3)!;

        final startIndex = days.indexOf(startDay);
        final endIndex = endDay != null ? days.indexOf(endDay) : startIndex;

        if (startIndex == -1 || endIndex == -1) continue;

        final targetDays = days.sublist(startIndex, endIndex + 1);

        for (final d in targetDays) {
          if (hours == 'off') {
            dayRanges[d] = [];
          } else {
            final ranges = hours.split(',');
            dayRanges[d] = ranges.map((r) {
              final times = r.split('-');
              if (times.length != 2) return TimeRange('09:00', '18:00');
              return TimeRange(times[0], times[1]);
            }).toList();
          }
        }
      }
    }
  }

  void _addRange(String day) {
    setState(() {
      dayRanges[day]!.add(TimeRange('09:00', '18:00'));
    });
  }

  void _removeRange(String day, int index) {
    setState(() {
      dayRanges[day]!.removeAt(index);
    });
  }

  void _updateTime(String day, int index, String from, String to) {
    setState(() {
      dayRanges[day]![index] = TimeRange(from, to);
    });
  }

  void _setDayClosed(String day) {
    setState(() {
      dayRanges[day]!.clear();
    });
  }

  String _formatOpeningHours() {
    final result = StringBuffer();

    // Groupe les jours par horaires identiques
    final Map<String, List<String>> scheduleGroups = {};

    for (final day in days) {
      final ranges = dayRanges[day]!;
      String schedule = '';

      if (ranges.isEmpty) {
        schedule = 'off';
      } else {
        schedule = ranges
            .where((r) => r.start.isNotEmpty && r.end.isNotEmpty)
            .map((r) => '${r.start}-${r.end}')
            .join(',');
      }

      if (!scheduleGroups.containsKey(schedule)) {
        scheduleGroups[schedule] = [];
      }
      scheduleGroups[schedule]!.add(day);
    }

    // Format les horaires par groupe
    final entries = scheduleGroups.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final schedule = entries[i].key;
      final dayGroup = entries[i].value;

      // Trouve les séquences de jours consécutifs
      List<List<String>> sequences = [];
      List<String>? currentSequence;

      for (final day in days) {
        if (dayGroup.contains(day)) {
          if (currentSequence == null) {
            currentSequence = [day];
          } else {
            currentSequence.add(day);
          }
        } else if (currentSequence != null) {
          sequences.add(currentSequence);
          currentSequence = null;
        }
      }

      if (currentSequence != null) {
        sequences.add(currentSequence);
      }

      // Format chaque séquence
      for (int j = 0; j < sequences.length; j++) {
        final seq = sequences[j];
        if (seq.length > 1) {
          result.write('${seq.first}-${seq.last} $schedule');
        } else {
          result.write('${seq.first} $schedule');
        }

        if (j < sequences.length - 1 || i < entries.length - 1) {
          result.write('; ');
        }
      }
    }

    return result.toString();
  }

  void _save() {
    final formattedHours = _formatOpeningHours();
    widget.onSaved(formattedHours);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ...days.map((day) {
              final ranges = dayRanges[day]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayToFrench(day),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (ranges.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              const Icon(Icons.not_interested),
                              const SizedBox(width: 8),
                              const Text(
                                'Fermé ce jour',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ...List.generate(ranges.length, (index) {
                        return Card(
                          margin: const EdgeInsets.only(top: 8, bottom: 8),
                          color: Colors.grey.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: ranges[index].start,
                                    decoration: const InputDecoration(
                                      labelText: 'Début',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      if (val != null) {
                                        _updateTime(
                                            day, index, val, ranges[index].end);
                                      }
                                    },
                                    items: availableTimes
                                        .map((time) => DropdownMenuItem<String>(
                                              value: time,
                                              child: Text(time),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: ranges[index].end,
                                    decoration: const InputDecoration(
                                      labelText: 'Fin',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      if (val != null) {
                                        _updateTime(day, index,
                                            ranges[index].start, val);
                                      }
                                    },
                                    items: availableTimes
                                        .map((time) => DropdownMenuItem<String>(
                                              value: time,
                                              child: Text(time),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeRange(day, index),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _addRange(day),
                              icon: const Icon(Icons.access_time),
                              label: const Text('Ajouter une plage horaire'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _setDayClosed(day),
                              icon: const Icon(Icons.do_not_disturb_on),
                              label: const Text('Définir comme fermé'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Sauvegarder les horaires'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayToFrench(String day) {
    const map = {
      'Mo': 'Lundi',
      'Tu': 'Mardi',
      'We': 'Mercredi',
      'Th': 'Jeudi',
      'Fr': 'Vendredi',
      'Sa': 'Samedi',
      'Su': 'Dimanche',
    };
    return map[day]!;
  }
}

class TimeRange {
  final String start;
  final String end;

  TimeRange(this.start, this.end);
}

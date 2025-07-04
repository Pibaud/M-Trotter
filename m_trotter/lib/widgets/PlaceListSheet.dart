import 'package:flutter/material.dart';
import 'package:m_trotter/models/Place.dart';
import 'package:m_trotter/utils/GlobalData.dart';
import '../services/ApiService.dart';
import 'package:logger/logger.dart';

class PlaceListSheet extends StatefulWidget {
  final double initialHeight;
  final double fullHeight;
  final double midHeight;
  final double collapsedHeight;
  final Function onClose;
  final Function(Place) onFittingPlaceTap;
  final String title;
  final List<Place> places;

  const PlaceListSheet({
    Key? key,
    required this.initialHeight,
    required this.fullHeight,
    required this.midHeight,
    required this.collapsedHeight,
    required this.onClose,
    required this.onFittingPlaceTap,
    required this.title,
    required this.places,
  }) : super(key: key);

  @override
  _PlaceListSheetState createState() => _PlaceListSheetState();
}

class _PlaceListSheetState extends State<PlaceListSheet> {
  late double _currentHeight;
  final logger = Logger();
  late String _title;
  late ApiService _apiService;
  List<Place> _places = [];
  final ScrollController _controller = ScrollController();
  Map<String, dynamic> _filters = {
    'isOpen': false,
    'minNote': 0.0,
  };

  // Add state variables for filters
  bool _isOpenFilterSelected = false;
  bool _isRatingFilterSelected = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _currentHeight = widget.initialHeight;
    _title = widget.title;
    _places = widget.places;

    _controller.addListener(() {
      if (_controller.position.atEdge) {
        bool isTop = _controller.position.pixels == 0;
        if (!isTop) {
          getNextPlaces(_places.last.id);
        }
      }
    });
  }

  Future<void> getNextPlaces(int osmStartId) async {
    print("demande de nouveaux lieux avec startID = $osmStartId...");
    try {
      final res = await _apiService.fetchPlacesFittingAmenity(
          GlobalData.amenities[_title]!,
          osmStartId: osmStartId);
      setState(() {
        _places.addAll(res.map<Place>((data) => Place.fromJson(data)));
      });
    } catch (e) {
      print('Erreur lors de la récupération des places pour une amenity : $e');
    }
  }

  Future<void> getFilteredPlaces(Map<String, dynamic> filters,
      {int? osmStartId}) async {
    print(
        "Filtering places with osmStartId: $osmStartId, isOpenFilter: ${filters['isOpen']}, minNote: ${filters['minNote']}");
    try {
      final res = await _apiService.fetchPlacesFittingAmenity(
        GlobalData.amenities[_title]!,
        osmStartId: osmStartId,
        isOpen: filters['isOpen'],
        minNote: filters['minNote'],
      );
      setState(() {
        _places = (res.map<Place>((data) => Place.fromJson(data))).toList();
      });
    } catch (e) {
      print('Erreur lors de la récupération des places pour une amenity : $e');
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final List<double> positions = [
      widget.collapsedHeight,
      widget.midHeight,
      widget.fullHeight,
    ];

    double closestPosition = positions.reduce((a, b) =>
        (a - _currentHeight).abs() < (b - _currentHeight).abs() ? a : b);

    setState(() {
      _currentHeight = closestPosition;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _currentHeight -= details.delta.dy;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _currentHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12, // Updated  color
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
                      _title,
                      style: const TextStyle(
                        fontSize: 15,
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

              // Filtres
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtre "Ouvert actuellement"
                      Container(
                        margin: const EdgeInsets.only(right: 10.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isOpenFilterSelected = !_isOpenFilterSelected;
                              _filters['isOpen'] = !_filters['isOpen'];
                            });
                            getFilteredPlaces(_filters);
                          },
                          icon: Icon(
                            Icons.access_time_rounded,
                            size: 18.0,
                            color: _isOpenFilterSelected ? Colors.white : null,
                          ),
                          label: Text(
                            "Ouvert actuellement",
                            style: TextStyle(
                              color:
                                  _isOpenFilterSelected ? Colors.white : null,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            backgroundColor: _isOpenFilterSelected
                                ? Theme.of(context).primaryColor
                                : null,
                            side: BorderSide(
                              color: _isOpenFilterSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Filtre "Note"
                      Container(
                        margin: const EdgeInsets.only(right: 10.0),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            double selectedNote = 0.0;
                            //faire apparaitre une pop up avec 5 étoiles alignées, l'appui la i-ème étoile met selectedNote = i
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Sélectionnez une note"),
                                  content: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(5, (index) {
                                      return IconButton(
                                        icon: Icon(
                                          Icons.star,
                                          color: index < selectedNote
                                              ? Colors.yellow
                                              : Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isRatingFilterSelected =
                                                !_isRatingFilterSelected;
                                            _filters['minNote'] =
                                                (index + 1).toDouble();
                                          });
                                          getFilteredPlaces(_filters);
                                          Navigator.of(context).pop();
                                        },
                                      );
                                    }),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isRatingFilterSelected = false;
                                          _filters['minNote'] = 0.0;
                                        });
                                        getFilteredPlaces(_filters);
                                        Navigator.of(context).pop();
                                      },
                                      child: Text("Annuler"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: Icon(
                            Icons.star_rounded,
                            size: 18.0,
                            color:
                                _isRatingFilterSelected ? Colors.white : null,
                          ),
                          label: Text(
                            "Note",
                            style: TextStyle(
                              color:
                                  _isRatingFilterSelected ? Colors.white : null,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                            backgroundColor: _isRatingFilterSelected
                                ? Theme.of(context).primaryColor
                                : null,
                            side: BorderSide(
                              color: _isRatingFilterSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Bouton "Plus de filtres"
                      Container(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Afficher plus de filtres
                          },
                          icon: const Icon(Icons.tune, size: 18.0),
                          label: const Text("Plus de filtres"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Séparateur
              const Divider(),

              // Liste des places
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _places.length,
                  controller: _controller,
                  itemBuilder: (context, index) {
                    final place = _places[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${place.amenity}'),
                            Text(
                              'Coordonnées: ${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onFittingPlaceTap(place);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/ApiService.dart';
import '../widgets/PlaceInfoSheet.dart';
import '../models/Place.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  HomePageState createState() => HomePageState();
}

void showPlaceSheet(BuildContext context, Place place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return PlaceInfoSheet(
        place: place,
        onClose: () => Navigator.of(context).pop(),
        height: 80,
      );
    },
  );
}

class HomePageState extends State<HomePage> {
  List<Place> bestPlaces = [];
  List<Place> favorisPlaces = [];
  late ApiService _apiService;

  @override
  void initState() {
    _apiService = ApiService();
    super.initState();
    loadBestPlaces();
    loadFavoris();
  }

  Future<void> loadBestPlaces() async {
    List<Place> places = await _apiService.trouveBestPlaces();
    setState(() {
      bestPlaces = places;
    });
  }

  Future<void> loadFavoris() async {
    List<Place> favoris = await _apiService.getFavoris();
    setState(() {
      favorisPlaces = favoris;
    });
  }

  Future<void> resetIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFirstLaunch');
    print("isFirstLaunch réinitialisé");
  }

  Future<void> resetIsLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    print("isLoggedIn réinitialisé");
  }

  void _navigateToMapWithPlace(Place place) {
    if (myAppKey.currentState != null) {
      myAppKey.currentState?.navigateToMapWithPlace(place);
    }
  }

  Widget _buildPlaceCard(Place place) {
    return GestureDetector(
      onTap: () => _navigateToMapWithPlace(place),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Colors.blue[200],
            borderRadius: BorderRadius.circular(20.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51), // Equivalent to 20% opacity
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(place.name, style: TextStyle(fontSize: 18)),
                if (place.amenity != null)
                  Text(place.amenity!,
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(place.avgStars.toStringAsFixed(1),
                        style: TextStyle(fontSize: 14, color: Colors.black)),
                    SizedBox(width: 4),
                    Row(
                      children: List.generate(5, (index) {
                        if (index < place.avgStars.floor()) {
                          return Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16);
                        } else if (index < place.avgStars) {
                          return Icon(Icons.star_half_rounded,
                              color: Colors.amber, size: 16);
                        } else {
                          return Icon(Icons.star_border_rounded,
                              color: Colors.grey, size: 16);
                        }
                      }),
                    ),
                    SizedBox(width: 4),
                    Text('(${place.numReviews})',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceSection(
      String title, List<Place> places, String emptyMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 5.0, bottom: 5.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150, // Fixed height instead of Expanded
          child: places.isEmpty
              ? Center(
                  child: emptyMessage == "loading"
                      ? CircularProgressIndicator()
                      : Text(
                          emptyMessage,
                          style: TextStyle(color: Colors.grey),
                        ),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      places.map((place) => _buildPlaceCard(place)).toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Text('M\'Trotter'),
      )),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search bar - fixed height
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Où voulez-vous aller ?',
                  hintStyle: TextStyle(
                    color: Color.fromRGBO(0, 0, 0, 0.35),
                  ),
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onTap: () {
                  // ...existing code...
                },
              ),
            ),

            // Use Flexible widgets to divide remaining space
            Flexible(
              flex: 1,
              child: _buildPlaceSection("Favoris", favorisPlaces,
                  "Vous n'avez pas encore de favoris"),
            ),
            Flexible(
              flex: 1,
              child: _buildPlaceSection(
                  "Populaires en ce moment", bestPlaces, "loading"),
            ),
          ],
        ),
      ),
    );
  }
}

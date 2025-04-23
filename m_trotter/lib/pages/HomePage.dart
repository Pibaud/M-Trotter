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
  List<Map<String, dynamic>> bestPlaces = [];
  List<Map<String, dynamic>> favorisPlaces = [];
  late ApiService _apiService;

  @override
  void initState() {
    _apiService = ApiService();
    super.initState();
    loadBestPlaces();
    loadFavoris();
  }

  Future<void> loadBestPlaces() async {
    List<Map<String, dynamic>> places = await _apiService.trouveBestPlaces();
    setState(() {
      bestPlaces = places;
    });
  }

  Future<void> loadFavoris() async {
    List<Map<String, dynamic>> favoris = await _apiService.getFavoris();
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

  Widget _buildPlaceCard(Map<String, dynamic> placeAndPhoto) {
    Place place = placeAndPhoto['place'];
    var photo = placeAndPhoto['photo'];

    return GestureDetector(
      onTap: () => _navigateToMapWithPlace(place),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 120, // Fixed height for the card
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: Row(
            children: [
              // Left side - Photo
              Container(
                width: 120, // Width for the image container
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    bottomLeft: Radius.circular(20.0),
                  ),
                  color: Colors.grey[200], // Placeholder color
                ),
                child: photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          bottomLeft: Radius.circular(20.0),
                        ),
                        child: Image.network(
                          'http://217.182.79.84:3000${photo['url']}',
                          fit: BoxFit.cover,
                          height: double.infinity,
                          width: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                                child: Icon(Icons.image_not_supported));
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.photo_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),

              // Right side - Information
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (place.amenity != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            place.amenity!,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Text(
                              place.avgStars.toStringAsFixed(1),
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            SizedBox(width: 4),
                            Row(
                              children: List.generate(5, (index) {
                                if (index < place.avgStars.floor()) {
                                  return Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 12);
                                } else if (index < place.avgStars) {
                                  return Icon(Icons.star_half_rounded,
                                      color: Colors.amber, size: 12);
                                } else {
                                  return Icon(Icons.star_border_rounded,
                                      color: Colors.grey, size: 12);
                                }
                              }),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(${place.numReviews})',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceSection(
      String title, List<Map<String, dynamic>> places, String emptyMessage) {
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

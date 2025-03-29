import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/ApiService.dart';
import '../widgets/PlaceInfoSheet.dart';

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
      );
    },
  );
}

class HomePageState extends State<HomePage> {
  List<dynamic> bestPlaces = [];
  List<dynamic> favorisPlaces = [];;

  @override
  void initState() {
    super.initState();
    loadBestPlaces();
    loadFavoris();
  }

  Future<void> loadBestPlaces() async {
    List<dynamic> places = await ApiService.trouveBestPlaces();
    setState(() {
      bestPlaces = places;
    });
  }

  Future<void> loadFavoris() async {
    List<dynamic> favoris = await ApiService.getFavoris(); // Retourne directement une liste dynamique
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

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
          title: Center(
        child: Text('M\'Trotter'),
      )),
      body: Column(
        children: [
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
                print("Appui sur la barre de recherche");
                if (myAppKey.currentState == null) {
                  print("myAppKey.currentState est null");
                } else {
                  print("myAppKey.currentState est valide");
                  myAppKey.currentState?.navigateToMapWithFocus();
                }
              },
            ),
          ),
          Text("Favoris"),
          Expanded(
            child: favorisPlaces.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: favorisPlaces.map((place) {
                      return GestureDetector(
                        onTap: () => showPlaceSheet(context, place),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 150,
                            color: Colors.blue[200],
                            child: Center(
                              child: Text(place['name'] ?? 'Lieu inconnu',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Text("Populaires en ce moment"),
          Expanded(
            child: bestPlaces.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: bestPlaces.map((place) {
                      return GestureDetector(
                        onTap: () => showPlaceSheet(context, place),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            width: 150,
                            color: Colors.blue[200],
                            child: Center(
                              child: Text(place['name'] ?? 'Lieu inconnu',
                                  style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await resetIsFirstLaunch();
                  },
                  child: Text("Réinitialiser 'isFirstLaunch'"),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    await resetIsLoggedIn();
                  },
                  child: Text("Réinitialiser 'isLoggedIn'"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

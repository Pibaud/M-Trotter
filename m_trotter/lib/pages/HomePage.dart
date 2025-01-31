import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  // Fonction pour réinitialiser isFirstLaunch
  Future<void> resetIsFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFirstLaunch');
    print("isFirstLaunch réinitialisé");
  }

  // Fonction pour réinitialiser isLoggedIn
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
<<<<<<< HEAD
                print("Appui sur la barre de recherche");
                if (myAppKey.currentState == null) {
                  print("myAppKey.currentState est null");
                } else {
                  print("myAppKey.currentState est valide");
                  myAppKey.currentState?.navigateToMapWithFocus();
                }
=======
                print("Navigation vers MapPage avec focusOnSearch = true");
                //myAppKey.currentState?.navigateToMapWithFocus();
>>>>>>> transit
              },
            ),
          ),
          Text("Favoris"),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 1; i <= 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 150,
                      color: Colors.blue[100 * (i % 9)],
                      child: Center(
                        child: Text('Favori $i',
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text("Populaires en ce moment"),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 1; i <= 10; i++)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 150,
                      color: Colors.blue[100 * (i % 9)],
                      child: Center(
                        child:
                            Text('Élément $i', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Boutons de réinitialisation des préférences
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

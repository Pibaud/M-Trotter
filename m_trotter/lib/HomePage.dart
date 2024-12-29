import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthPage.dart';
import 'AuthPopup.dart';

class HomePage extends StatefulWidget {
  final void Function(int) onTabChange;

  const HomePage({super.key, required this.onTabChange});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
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
                print("Navigating to MapPage with focusOnSearch = true");
                widget.onTabChange(1); // Simule un clic sur l'onglet Map
              },
            ),
          ),
          Text("Favoris"),
          Expanded(
            child: authState.isLoggedIn
                ? ListView(
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
                  )
                : Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AuthDialog(authState);
                          },
                        );
                      },
                      child: const Text("Se connecter pour voir vos favoris"),
                    ),
                  ),
          ),
          Text("Populaires en ce moment"),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal, // Scroll de droite à gauche.
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
        ],
      ),
    );
  }
}

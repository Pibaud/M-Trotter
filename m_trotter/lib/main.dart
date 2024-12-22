import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'HomePage.dart';
import 'MapPage.dart';
import 'ProfilePage.dart';
import 'package:provider/provider.dart';
import 'AuthPage.dart';

Future<void> main() async {
  try {
    print("récupération du .env...");
    await dotenv.load(fileName: "../../.env");  // chemin correct
    print(".env récupéré");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env : $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onTabChange: _onItemTapped), // Passez le callback ici
      const MapPage(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex, // Indique quel onglet est sélectionné
          selectedItemColor:
              Colors.blue, // Couleur de l'icône/texte sélectionné
          unselectedItemColor:
              Colors.grey, // Couleur des icônes non sélectionnées
          onTap:
              _onItemTapped, // Appelle cette fonction lorsqu'un onglet est tapé
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'MapPage.dart';
import 'SearchPage.dart';
import 'NewsPage.dart';
import 'ProfilePage.dart';

void main() {
  runApp(const MyApp());
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
      const SearchPage(),
      const MapPage(),
      const NewsPage(),
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
              icon: Icon(Icons.search),
              label: 'Rechercher',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: 'Actualités',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex, // Indique quel onglet est sélectionné
          selectedItemColor: Colors.blue, // Couleur de l'icône/texte sélectionné
          unselectedItemColor: Colors.grey, // Couleur des icônes non sélectionnées
          onTap: _onItemTapped, // Appelle cette fonction lorsqu'un onglet est tapé
        ),
      ),
    );
  }
}
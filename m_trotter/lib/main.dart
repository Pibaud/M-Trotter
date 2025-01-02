import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'MapPage.dart';
import 'ProfilePage.dart';
import 'package:provider/provider.dart';
import 'AuthPage.dart';
import 'BottomNavBarVisibilityProvider.dart';

final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BottomNavBarVisibilityProvider(),
      child: ChangeNotifierProvider(
        create: (_) => AuthState(),
        child: MyApp(key: myAppKey), // Assignez la clé ici
      ),
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
  bool _focusOnSearch = false; // Indique si le focus doit être activé

  late final List<Widget> _pages;

  void navigateToMapWithFocus() {
    setState(() {
      _focusOnSearch = true;
      _selectedIndex = 1; // Naviguer vers la page Map
      _pages[1] =
          MapPage(focusOnSearch: _focusOnSearch); // Actualiser la MapPage
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onTabChange: _onItemTapped),
      MapPage(focusOnSearch: _focusOnSearch),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) {
        // Naviguer vers MapPage sans activer le focus
        _focusOnSearch = false;
      }
      _selectedIndex = index; // Met à jour l'onglet sélectionné
      _pages[1] = MapPage(focusOnSearch: _focusOnSearch); // Recharge MapPage
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Consumer<BottomNavBarVisibilityProvider>(
          builder: (context, bottomNavBarVisibility, child) {
            return bottomNavBarVisibility.isBottomNavVisible
                ? BottomNavigationBar(
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
                    currentIndex: _selectedIndex,
                    selectedItemColor: Colors.blue,
                    unselectedItemColor: Colors.grey,
                    onTap: _onItemTapped,
                  )
                : SizedBox.shrink(); // Si BottomNav est caché, ne rien afficher
          },
        ),
      ),
    );
  }
}

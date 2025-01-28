import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/HomePage.dart';
import 'pages/MapPage.dart';
import 'pages/ProfilePage.dart';
import 'pages/IntroSlides.dart';
import 'pages/AuthPage.dart'; // Page d'authentification complète
import 'package:provider/provider.dart';
import 'providers/AuthNotifier.dart';
import 'providers/BottomNavBarVisibilityProvider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

void main() async {
  await dotenv.load(fileName: "assets/.env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavBarVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: const MyAppWrapper(),
    ),
  );
}

class MyAppWrapper extends StatelessWidget {
  const MyAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAppState(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Center(
                child:
                    CircularProgressIndicator()), // Encapsulation dans MaterialApp
          );
        }

        if (snapshot.hasError) {
          return const MaterialApp(
            home: Center(child: Text("Une erreur est survenue !")),
          );
        }

        if (snapshot.hasData) {
          final appState = snapshot.data!;
          final isFirstLaunch = appState['isFirstLaunch'] as bool;
          final isLoggedIn = appState['isLoggedIn'] as bool;

          if (isFirstLaunch) {
            // Afficher les slides d'introduction
            return MaterialApp(
              home: IntroSlides(onFinish: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isFirstLaunch', false);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          isLoggedIn ? const MyApp() : AuthPage(),
                    ),
                  );
                });
              }),
            );
          }
          if (isLoggedIn) {
            return const MaterialApp(
              home:
                  MyApp(), // Assurez-vous que MyApp est également dans un MaterialApp
            );
          } else {
            return MaterialApp(
              home: AuthPage(), // Encapsulez AuthPage dans MaterialApp
            );
          }
        }

        return const MaterialApp(
          home: Center(child: Text("Chargement...")),
        );
      },
    );
  }

  // Vérifie l'état global de l'application
  Future<Map<String, dynamic>> _getAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return {'isFirstLaunch': isFirstLaunch, 'isLoggedIn': isLoggedIn};
  }
}

// Vérifie si l'utilisateur est authentifié
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);

    // Afficher une page différente selon le statut de connexion
    return authState.isLoggedIn ? const MyApp() : AuthPage();
  }
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/HomePage.dart';
import 'pages/MapPage.dart';
import 'pages/AuthPage.dart';
import 'pages/ProfilePage.dart';
import 'providers/ThemeNotifier.dart';
import 'providers/LanguageNotifier.dart';
import 'providers/BottomNavBarVisibilityProvider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../services/ApiService.dart';
import '../utils/GlobalData.dart'; // Importez votre nouvelle classe
import '../models/Place.dart';

final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  Place? _selectedPlace;
  bool _focusOnSearch = false;
  late final List<Widget> _pages;
  late ApiService _apiService;

  void navigateToMapWithFocus() {
    print("Navigating to MapPage...");
    setState(() {
      _focusOnSearch = true;
      _selectedIndex = 1;
      _pages[1] = MapPage(focusOnSearch: _focusOnSearch);
    });
  }

  void navigateToMapWithPlace(Place place) {
    print("Navigating to MapPage with selected place...");
    setState(() {
      _selectedIndex = 1;
      _pages[1] = MapPage(focusOnSearch: false, selectedPlace: place);
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Charger les amenities globalement
    await GlobalData.loadAmenities();

    _pages = [
      HomePage(onTabChange: _onItemTapped),
      MapPage(focusOnSearch: _focusOnSearch),
      const ProfilePage(),
    ];

    _apiService = ApiService();
    final result = await _apiService.recupAccessToken();
    if (result['success'] == false &&
        result['error'] ==
            'Refresh token invalide, veuillez vous reconnecter') {
      print("Le refresh token est invalide, redirection vers la connexion...");
      AuthPage();
    } else {
      print("Token rafraîchi avec succès !");
    }

    // Ensure BottomNavBar is visible on initialization
    Provider.of<BottomNavBarVisibilityProvider>(context, listen: false)
        .showBottomNav();

    // Forcer une reconstruction après l'initialisation
    if (mounted) {
      setState(() {});
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) {
        _focusOnSearch = false;
      }
      _selectedIndex = index;
      _pages[1] =
          MapPage(focusOnSearch: _focusOnSearch, selectedPlace: _selectedPlace);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final languageNotifier = Provider.of<LanguageNotifier>(context);

    return MaterialApp(
      themeMode: themeNotifier.themeMode,
      theme: ThemeData.light().copyWith(
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Poppins', // Appliquer la police dans le textTheme
            ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Poppins', // Appliquer la police en mode sombre aussi
            ),
      ),
      locale: languageNotifier.currentLocale,
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
        Locale('es', 'ES'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Consumer<BottomNavBarVisibilityProvider>(
          builder: (context, bottomNavBarVisibility, child) {
            return bottomNavBarVisibility.isBottomNavVisible
                ? BottomNavigationBar(
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home_rounded),
                        label: 'Accueil',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.map_rounded),
                        label: 'Carte',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_rounded),
                        label: 'Profil',
                      ),
                    ],
                    currentIndex: _selectedIndex,
                    selectedItemColor: Colors.blue,
                    unselectedItemColor: Colors.grey,
                    onTap: _onItemTapped,
                  )
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

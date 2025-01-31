import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/HomePage.dart';
import 'pages/MapPage.dart';
import 'pages/ProfilePage.dart';
import 'providers/ThemeNotifier.dart';
import 'providers/LanguageNotifier.dart';
import 'providers/BottomNavBarVisibilityProvider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

<<<<<<< HEAD
final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);  // Utilise le paramètre 'key' directement

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
=======
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
>>>>>>> transit
  int _selectedIndex = 0;
  bool _focusOnSearch = false;
  late final List<Widget> _pages;

  void navigateToMapWithFocus() {
<<<<<<< HEAD
    print("Navigating to MapPage...");
=======
>>>>>>> transit
    setState(() {
      _focusOnSearch = true;
      _selectedIndex = 1;
      _pages[1] = MapPage(focusOnSearch: _focusOnSearch);
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
        _focusOnSearch = false;
      }
      _selectedIndex = index;
      _pages[1] = MapPage(focusOnSearch: _focusOnSearch);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final languageNotifier = Provider.of<LanguageNotifier>(context);

    return MaterialApp(
      themeMode: themeNotifier.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
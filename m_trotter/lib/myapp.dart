import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/HomePage.dart';
import 'pages/MapPage.dart';
import 'pages/ProfilePage.dart';
import 'providers/ThemeNotifier.dart';
import 'providers/LanguageNotifier.dart';
import 'providers/BottomNavBarVisibilityProvider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  bool _focusOnSearch = false;
  late final List<Widget> _pages;

  void navigateToMapWithFocus() {
    print("Navigating to MapPage...");
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
                        icon: Icon(Icons.home),
                        label: 'Accueil',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.map),
                        label: 'Carte',
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

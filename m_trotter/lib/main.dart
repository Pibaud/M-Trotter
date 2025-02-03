import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/NotificationsService.dart';
import 'pages/IntroSlides.dart';
import 'pages/AuthPage.dart';
import 'providers/AuthNotifier.dart';
import 'providers/BottomNavBarVisibilityProvider.dart';
import 'providers/ThemeNotifier.dart';
import 'providers/LanguageNotifier.dart';
import 'myapp.dart';

final GlobalKey<MyAppState> myAppKey = GlobalKey<MyAppState>();

void main() async {
  await dotenv.load(fileName: "assets/.env");
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavBarVisibilityProvider()),
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => LanguageNotifier()),
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
            home: Center(child: CircularProgressIndicator()),
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
            return MaterialApp(
              theme: ThemeData(
                fontFamily: 'Poppins', // Appliquer la police par défaut
              ),
              home: IntroSlides(),
            );
          }
          return MaterialApp(
            theme: ThemeData(
              fontFamily: 'Poppins', // Appliquer la police par défaut
            ),
            home: isLoggedIn ? MyApp(key: myAppKey) : AuthPage(),
          );
        }

        return const MaterialApp(
          home: Center(child: Text("Chargement...")),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return {'isFirstLaunch': isFirstLaunch, 'isLoggedIn': isLoggedIn};
  }
}

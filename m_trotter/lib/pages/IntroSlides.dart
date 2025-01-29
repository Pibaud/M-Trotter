import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AuthPage.dart'; // Remplace par l'import correct

class IntroSlides extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final slides = [
      {"title": "Explorez Montpellier autrement", "content": "Profitez des données en temps réel des transports et restaurants."},
      {"title": "Itinéraires simplifiés", "content": "Utilisez OpenStreetMap pour rejoindre votre destination."},
      {"title": "Participez à la communauté", "content": "Ajoutez des notes, photos et complétez les données locales."},
    ];

    return Scaffold(
      body: PageView.builder(
        itemCount: slides.length,
        itemBuilder: (context, index) {
          final slide = slides[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(slide['title']!, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(slide['content']!, textAlign: TextAlign.center),
              if (index == slides.length - 1)
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('isFirstLaunch', false);

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => AuthPage(),
                      ),
                    );
                  },
                  child: Text("Commencer"),
                ),
            ],
          );
        },
      ),
    );
  }
}
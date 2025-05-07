import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ThemeNotifier.dart';
import '../providers/LanguageNotifier.dart';
import 'NotificationsPage.dart';
import 'EditProfilePage.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageNotifier = Provider.of<LanguageNotifier>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Paramètres')),
      ),
      body: ListView(
        children: [
          // Paramètre pour le mode sombre
          SwitchListTile(
            title: const Text('Mode sombre'),
            subtitle: const Text('Activer ou désactiver le mode sombre'),
            value: themeNotifier.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              themeNotifier.toggleTheme(value);
            },
          ),
          /*

          // Autres paramètres factices
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text("Gérer vos notifications"),
            onTap: () {
              // Naviguer vers la page des notifications
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Confidentialité et Sécurité'),
            subtitle: const Text('Modifier les paramètres de confidentialité'),
            onTap: () {
              // Naviguer vers une autre page spécifique
            },
          ),
          const Divider(),

          // Option Langue avec icône avant le texte
          ListTile(
            leading: const Icon(Icons.language), // Icône du globe ici
            title: const Text("Langue"),
            trailing: DropdownButton<String>(
              value: languageNotifier.currentLocale.languageCode,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  languageNotifier.setLanguage(newValue);
                }
              },
              items: const [
                DropdownMenuItem(value: 'fr', child: Text("Français 🇫🇷")),
                DropdownMenuItem(value: 'en', child: Text("English 🇬🇧")),
                DropdownMenuItem(value: 'es', child: Text("Español 🇪🇸")),
              ],
            ),
            onTap: () {
              // Tu pourrais ouvrir un dialogue si tu le souhaites pour choisir la langue
            },
          ),

           */
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('À propos'),
            subtitle: const Text('En savoir plus sur cette application'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFB9C3F3), // Couleur douce inspirée de ton fond
      appBar: AppBar(
        title: const Text("À propos"),
        backgroundColor: const Color(0xFFB9C3F3), // Violet bleuté
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 20),
              Text(
                "M'Trotter",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFB9C3F3),
                ),
              ),
              SizedBox(height: 10),
              Text(
                "M'Trotter est une application mobile développée dans le cadre d’un projet universitaire, visant à faciliter l’exploration de la ville de Montpellier. Que ce soit pour se déplacer, découvrir de nouvelles activités ou tester des restaurants, l’application accompagne les utilisateurs dans leur quotidien. Elle repose également sur la participation de sa communauté, qui peut enrichir la base de données en partageant ses découvertes et en laissant des avis sur les lieux visités.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Notre équipe",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "- Thibaud\n"
                    "- Hugo\n"
                    "- Yanis\n"
                    "- Robin\n",
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 30),
              Text(
                "Ce projet a été réalisé dans le cadre de notre formation à l’Université de Montpellier.\n\nAnnée universitaire : 2024-2025",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

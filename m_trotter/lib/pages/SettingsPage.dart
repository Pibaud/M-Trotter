import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ThemeNotifier.dart';
import '../providers/LanguageNotifier.dart';
import 'NotificationsPage.dart';

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
          const Divider(),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('À propos'),
            subtitle: const Text('En savoir plus sur cette application'),
            onTap: () {
              // Naviguer vers une page "À propos"
            },
          ),
        ],
      ),
    );
  }
}

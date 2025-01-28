import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';
import 'SettingsPage.dart'; // Assurez-vous d'importer la page des paramètres

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor; // Récupère la couleur de fond du Scaffold

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text('Votre profil'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Bienvenue sur votre page de profil !",
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                authState.logOut(); // Déconnecte l'utilisateur.
              },
              child: const Text("Se déconnecter"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: scaffoldBackgroundColor, // Utilise la couleur de fond du Scaffold
        child: InkWell(
          onTap: () {
            // Redirection vers la page des paramètres lorsqu'on clique sur toute la barre
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Aligner à gauche
              children: [
                Icon(Icons.settings), // Icône noire pour contraste sur fond clair
                const SizedBox(width: 8),
                const Text(
                  "Paramètres",
                  style: TextStyle(fontSize: 16), // Texte noir
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

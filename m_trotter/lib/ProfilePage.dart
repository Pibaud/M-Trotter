import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'AuthPage.dart';
import 'AuthPopup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context, listen: true);
    return Scaffold(
        appBar: AppBar(
            title: Center(
          child: Text('Votre profil'),
        )),
        body: authState.isLoggedIn
            ? Center(
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
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Pour centrer verticalement
                  children: [
                    Text('Vous devez vous connecter pour voir votre profil'),
                    SizedBox(height: 20), // Espacement entre les widgets
                    ElevatedButton(
                      onPressed: () {
                        // Action du bouton
                      },
                      child: Text('Se connecter / S\'inscrire'),
                    ),
                  ],
                ),
              ));
  }
}

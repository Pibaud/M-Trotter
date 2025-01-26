import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';

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
        ));
  }
}

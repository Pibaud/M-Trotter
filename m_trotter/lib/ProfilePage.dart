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
        child: Text('M\'Trotter NewsPage ProfilePage'),
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
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AuthDialog(authState);
                },
              );
            },
            child: const Text("Se connecter"),
          ),
        ),
    );
  }
}

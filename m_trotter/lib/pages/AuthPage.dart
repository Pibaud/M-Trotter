import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';
import '../myapp.dart'; // Import de MyApp
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoginMode = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);

    // Listener pour détecter le changement d'état de la connexion
    if (authState.isLoggedIn) {
      // Si l'utilisateur est connecté, rediriger vers MyApp
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyApp()),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoginMode ? "Connexion" : "Inscription"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isLoginMode)
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: "Nom d'utilisateur",
                    errorText: _usernameError,
                  ),
                ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email ou Nom d'Utilisateur",
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Mot de passe",
                  errorText: _passwordError,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  final password = _passwordController.text.trim().toString();
                  final username = _usernameController.text.trim();

                  setState(() {
                    _emailError = null;
                    _passwordError = null;
                    _usernameError = null;
                  });

                  if (!_isValidEmail(email)) {
                    setState(() {
                      _emailError = "L'email n'est pas valide.";
                    });
                    return;
                  }

                  if (password.isEmpty) {
                    setState(() {
                      _passwordError = "Le mot de passe ne peut pas être vide.";
                    });
                    return;
                  }

                  if (password.runtimeType != String) {
                    setState(() {
                      _passwordError =
                          "Le mot de passe doit être une chaîne de caractères.";
                    });
                    return;
                  }

                  if (!_isLoginMode && username.isEmpty) {
                    setState(() {
                      _usernameError =
                          "Le nom d'utilisateur ne peut pas être vide.";
                    });
                    return;
                  }

                  if (_isLoginMode) {
                    authState.logIn(
                      email: email,
                      password: password,
                    );
                  } else {
                    print("Données envoyées au backend : $email, $username, $password");
                    authState.signUp(
                      email: email,
                      username: username,
                      password: password,
                    );
                  }
                },
                child: Text(_isLoginMode ? "Se connecter" : "S'inscrire"),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(
                  _isLoginMode
                      ? "Pas encore de compte ? Inscrivez-vous"
                      : "Déjà inscrit ? Connectez-vous",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}

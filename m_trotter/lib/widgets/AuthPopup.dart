import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/AuthNotifier.dart';
class AuthDialog extends StatefulWidget {
  final AuthState authState;

  const AuthDialog(this.authState, {Key? key}) : super(key: key);

  @override
  _AuthDialogState createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isLoginMode = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _usernameError;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{1,}$');
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isLoginMode ? "Connexion" : "Inscription"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            if (!_isLoginMode)
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: "Nom d'utilisateur", errorText: _usernameError),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email",errorText: _emailError),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mot de passe", errorText: _passwordError, ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final email = _emailController.text;
                final password = _passwordController.text;
                final username = _usernameController.text;

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

                if (!_isLoginMode && username.isEmpty) {
                  setState(() {
                    _usernameError = "Le nom d'utilisateur ne peut pas être vide.";
                  });
                  return;
                }


                if (_isLoginMode) {

                  widget.authState.logIn(
                    email: email,
                    password: password,
                  );
                } else {

                  widget.authState.signUp(
                    email: email,
                    username: username,
                    password: password,
                  );
                }

                // Ferme la popup après l'action.
                Navigator.of(context).pop();
              },
              child: Text(_isLoginMode ? "Se connecter" : "S'inscrire"),
            )
          ],
        ),
      ),
      actions: [
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
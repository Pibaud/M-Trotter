import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/ApiService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  set isLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      print("isLoggedIn a été mis à jour : $_isLoggedIn");
      notifyListeners();
    }
  }

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  Future<void> logIn({required String email, required String password}) async {
    print("tentative de login dans le service");
    print("url dans apiservice : ${_apiService.baseUrl}");
    try {
      final result = await _apiService.logIn(email, password);
      if (result['success']) {
        print("connexion réussie");
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        print("isLoggedIn mis à jour : $_isLoggedIn");
        notifyListeners(); // Assurez-vous que notifyListeners() est bien appelé
      } else {
        _errorMessage = result['error'];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
    }
  }

  Future<void> signUp(
      {required String email,
      required String username,
      required String password}) async {
    print("demande d'inscription");
    try {
      final result = await _apiService.signUp(email, username, password);
      if (result['success']) {
        print('Inscription réussie !');
      } else {
        _errorMessage = result['error'];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
    }
  }

  void logOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

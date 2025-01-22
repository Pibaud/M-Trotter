import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/ApiService.dart';

class AuthState with ChangeNotifier {
  final ApiService _apiService = ApiService(baseUrl: '');
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;


  String? _errorMessage;


  String? get errorMessage => _errorMessage;

  Future<void> logIn({required String email, required String password}) async {
    try {
      final result = await _apiService.logIn(email, password);
      if (result['success']) {
        _isLoggedIn = true;
        notifyListeners();
      } else {
        _errorMessage = result['error'];
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
    }
  }

  Future<void> signUp({required String email, required String username, required String password}) async {
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


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AuthState with ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void logIn({required String email, required String password}) {
    _isLoggedIn = true;
    notifyListeners();
  }

  void signUp(
      {required String email, required String username, required String password}) {
    _isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    _isLoggedIn = false;
    notifyListeners();
  }
}


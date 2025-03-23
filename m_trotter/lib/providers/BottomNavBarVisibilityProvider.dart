import 'package:flutter/material.dart';

class BottomNavBarVisibilityProvider extends ChangeNotifier {
  bool _isBottomNavVisible = true;

  BottomNavBarVisibilityProvider() {
    _isBottomNavVisible = true; // Ensure visibility is true on initialization
  }

  bool get isBottomNavVisible => _isBottomNavVisible;

  // Fonction pour cacher ou afficher la BottomNavigationBar
  void toggleBottomNavVisibility() {
    _isBottomNavVisible = !_isBottomNavVisible;
    notifyListeners();
  }

  void hideBottomNav() {
    _isBottomNavVisible = false;
    notifyListeners();
  }

  void showBottomNav() {
    _isBottomNavVisible = true;
    notifyListeners();
  }
}

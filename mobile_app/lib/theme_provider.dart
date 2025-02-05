import 'package:flutter/material.dart';
import 'database_helper.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkTheme;

  ThemeProvider({required bool isDarkTheme}) : _isDarkTheme = isDarkTheme;

  bool get isDarkTheme => _isDarkTheme;

  // Toggle theme and update the database
  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    DatabaseHelper().updateTheme(_isDarkTheme); // Update the database
    notifyListeners(); // Notify listeners to rebuild with the new theme
  }
}
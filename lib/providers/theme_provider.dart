// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Theme data getters
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade800,
        colorScheme: ColorScheme.light(
          primary: Colors.blue.shade800,
          secondary: Colors.green.shade600,
          background: Colors.grey.shade50,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.white,
          shadowColor: Colors.grey.withOpacity(0.2),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        useMaterial3: true,
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue.shade300,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue.shade300,
          secondary: Colors.green.shade300,
          background: Colors.grey.shade900,
        ),
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey.shade800,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: Colors.grey.shade800,
          shadowColor: Colors.black.withOpacity(0.4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        useMaterial3: true,
      );

  // Get current theme based on theme mode
  ThemeData get currentTheme {
    switch (_themeMode) {
      case ThemeMode.light:
        return lightTheme;
      case ThemeMode.dark:
        return darkTheme;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark
            ? darkTheme
            : lightTheme;
    }
  }

  // Theme mode names for UI
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  // Theme mode descriptions
  String get themeModeDescription {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme';
    }
  }

  // Set theme mode with save functionality
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _saveTheme();
    notifyListeners();
  }

  // Toggle between light and dark (for quick toggle)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Set theme by bool (true for dark, false for light)
  Future<void> setThemeByBool(bool isDark) async {
    await setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  // Set theme by index (0: system, 1: light, 2: dark)
  Future<void> setThemeByIndex(int index) async {
    switch (index) {
      case 0:
        await setThemeMode(ThemeMode.system);
        break;
      case 1:
        await setThemeMode(ThemeMode.light);
        break;
      case 2:
        await setThemeMode(ThemeMode.dark);
        break;
    }
  }

  // Get current theme index
  int get currentThemeIndex {
    switch (_themeMode) {
      case ThemeMode.system:
        return 0;
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
    }
  }

  // Load theme from shared preferences; default is light if no preference saved
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = ThemeMode.light;
            break;
          case 'dark':
            _themeMode = ThemeMode.dark;
            break;
          case 'system':
            _themeMode = ThemeMode.system;
            break;
          default:
            _themeMode = ThemeMode.light;
        }
      }
      // If no saved preference, _themeMode stays ThemeMode.light (set at field init)
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Save theme to shared preferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeValue;

      switch (_themeMode) {
        case ThemeMode.light:
          themeValue = 'light';
          break;
        case ThemeMode.dark:
          themeValue = 'dark';
          break;
        case ThemeMode.system:
          themeValue = 'system';
          break;
      }

      await prefs.setString(_themeKey, themeValue);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  // Reset to system default
  Future<void> resetToSystem() async {
    await setThemeMode(ThemeMode.system);
  }

  // Check if specific mode is active
  bool isLightMode() => _themeMode == ThemeMode.light;
  bool isDarkModeActive() => _themeMode == ThemeMode.dark;
  bool isSystemMode() => _themeMode == ThemeMode.system;
}

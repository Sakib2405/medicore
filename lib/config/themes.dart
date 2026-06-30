import 'package:flutter/material.dart';
// You may need to run: flutter pub add google_fonts
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // Define a primary color to be used across the app
  static const Color _primaryColor =
      Color(0xFF0068D9); // A professional medical blue

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent, // Modern transparent app bar
      foregroundColor: Colors.black87, // Icons and text color
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    fontFamily: GoogleFonts.inter().fontFamily,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

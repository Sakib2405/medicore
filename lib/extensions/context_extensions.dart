import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // --- MediaQuery ---
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // --- Theme ---
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  Color get primaryColor => theme.primaryColor;

  // --- Navigation ---
  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop(result);

  // --- SnackBar ---
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }
}

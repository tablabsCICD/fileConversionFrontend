import 'package:flutter/material.dart';

class AppTheme {
  // ---------- COLORS ----------
  static const Color primary = Color(0xFF2D9CDB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color banner = Color(0xFF2D9CDB);

  // ---------- LIGHT THEME ----------
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: Color(0xFFF9FCFF),
    canvasColor: Colors.black,
    cardColor: card,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.black)),
  );

  // ---------- DARK THEME ----------
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.white,
    cardColor: darkCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
  );
}

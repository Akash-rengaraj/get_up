import 'package:flutter/material.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF3949AB); // Deep Indigo
  static const Color _lightScaffold = Color(0xFFF8F9FA); // Off-white
  static const Color _lightCard = Colors.white;

  static const Color _darkScaffold = Color(0xFF121212); // Standard Dark
  static const Color _darkCard = Color(0xFF1E1E1E); // Darker Card
  static const Color _darkPrimary = Color(0xFF7986CB); // Lighter Indigo for Dark Mode
  static const Color _darkOnSurface = Colors.white; // Main text color
  static const Color _darkOnSurfaceVariant = Color(0xFFB0B0B0); // Subtitle text color
  static const Color _darkBorder = Color(0xFF2C2C2C); // Card border color

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      primary: _primaryColor,
      secondary: const Color(0xFF5C6BC0), // Lighter Indigo
      outline: Colors.grey[200]!,
    ),
    scaffoldBackgroundColor: _lightScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightScaffold,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFF212529),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: Color(0xFF212529)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _lightCard,
      surfaceTintColor: _lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightCard,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey[400],
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      primary: _darkPrimary,
      secondary: const Color(0xFF3949AB),
      outline: _darkBorder,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
    ),
    scaffoldBackgroundColor: _darkScaffold,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkScaffold, // Use scaffold color
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: _darkOnSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
      iconTheme: IconThemeData(color: _darkOnSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _darkCard,
      surfaceTintColor: _darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: _darkBorder, width: 1),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _darkCard, // Dark nav bar
      selectedItemColor: _darkPrimary,
      unselectedItemColor: _darkOnSurfaceVariant,
      elevation: 10,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}

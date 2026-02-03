import 'package:flutter/material.dart';

/// Configuration du thème de l'application
/// Utilise Material 3 avec la palette de couleurs Novadis
class AppTheme {
  // Couleurs de la charte graphique
  static const Color primaryBlue = Color(
    0xFF0B4F7C,
  ); // Fond principal, identité
  static const Color darkBlue = Color(0xFF083A5E); // Headers, navigation
  static const Color lightBlue = Color(
    0xFF1C84C6,
  ); // Sélection, éléments actifs
  static const Color lightGray = Color(
    0xFFE6EEF4,
  ); // Secondaire, backgrounds subtils
  static const Color alertRed = Color(0xFFC0392B); // Alertes, erreurs

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Thème clair de l'application
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: lightBlue,
        tertiary: darkBlue,
        error: alertRed,
        surface: white,
        onSurface: black,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightGray,

      // Configuration de l'AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: white,
        foregroundColor: darkBlue,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: darkBlue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: darkBlue),
      ),

      // Configuration des Cartes
      cardTheme: CardThemeData(
        elevation: 0, // Design plat/épuré
        color: white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.transparent,
          ), // Pas de bordure par défaut
        ),
        shadowColor: Colors.black.withValues(alpha: 0.05), // Ombre très légère
      ),

      // Textes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: darkBlue,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: darkBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkBlue,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: primaryBlue,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: black,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: TextStyle(
          color: Color(0xFF64748B), // Slate 500 equivalent
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: alertRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: lightGray,
        thickness: 1,
        space: 24,
      ),
    );
  }
}

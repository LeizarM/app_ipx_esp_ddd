import 'package:flutter/material.dart';

class PurpleGreenTheme {
  // Colores principales
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color darkPurple = Color(0xFF4527A0);
  static const Color lightPurple = Color(0xFF9575CD);
  
  static const Color slate = Color(0xFF757575);
  static const Color lightSlate = Color(0xFFBDBDBD);
  static const Color darkSlate = Color(0xFF424242);
  
  static const Color green = Color(0xFF66BB6A);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFA5D6A7);

  // Fondo degradado líquido
  static const Color backgroundColor1 = darkPurple;
  static const Color backgroundColor2 = Color(0xFF512DA8);

  // Colores de acentuación
  static const Color accentColor = green;
  static const Color errorColor = Color(0xFFE53935);

  // Obtener el tema completo
  static ThemeData get theme => ThemeData(
        primaryColor: primaryPurple,
        primaryColorDark: darkPurple,
        colorScheme: const ColorScheme.light(
          primary: primaryPurple,
          primaryContainer: darkPurple,
          secondary: green,
          secondaryContainer: darkGreen,
          surface: Colors.white,
          error: errorColor,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16.0,
            color: darkSlate,
          ),
          bodyMedium: TextStyle(
            fontSize: 14.0,
            color: slate,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: green, width: 2),
          ),
          labelStyle: const TextStyle(color: slate),
          floatingLabelStyle: const TextStyle(color: green),
        ),
      );
}

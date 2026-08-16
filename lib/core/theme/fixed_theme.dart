import 'package:flutter/material.dart';

class FixedTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF2E7D32),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      
      // Configuration des icônes pour forcer l'affichage
      iconTheme: const IconThemeData(
        color: Color(0xFF1F2937),
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: Color(0xFF2E7D32),
        size: 24,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFF1F2937),
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: Color(0xFF1F2937),
          size: 24,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Color(0xFF1F2937),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

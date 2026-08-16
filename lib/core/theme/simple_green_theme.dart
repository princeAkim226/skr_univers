import 'package:flutter/material.dart';

class SimpleGreenTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: false,
      primarySwatch: Colors.green,
      primaryColor: const Color(0xFF2E7D32),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      
      // Utiliser les polices système pour éviter les problèmes de chargement
      fontFamily: 'system-ui',
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Color(0xFF6B7280),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Configuration complète des polices pour éviter les erreurs de chargement
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        displayMedium: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2937),
        ),
        displaySmall: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineLarge: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        headlineSmall: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleLarge: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2937),
        ),
        titleMedium: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        titleSmall: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6B7280),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1F2937),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1F2937),
        ),
        bodySmall: TextStyle(
          fontFamily: 'system-ui',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

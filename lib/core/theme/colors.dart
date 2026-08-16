import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF2E7D32); // Vert foncé
  static const Color primaryLight = Color(0xFF4CAF50); // Vert clair
  static const Color primaryDark = Color(0xFF1B5E20); // Vert très foncé
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFF1976D2); // Bleu
  static const Color secondaryLight = Color(0xFF42A5F5); // Bleu clair
  static const Color secondaryDark = Color(0xFF0D47A1); // Bleu foncé
  
  // Couleurs d'accent
  static const Color accent = Color(0xFFFF9800); // Orange
  static const Color accentLight = Color(0xFFFFB74D); // Orange clair
  static const Color accentDark = Color(0xFFE65100); // Orange foncé
  
  // Couleurs de statut
  static const Color success = Color(0xFF4CAF50); // Vert
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color error = Color(0xFFF44336); // Rouge
  static const Color info = Color(0xFF2196F3); // Bleu
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212121); // Noir
  static const Color textSecondary = Color(0xFF757575); // Gris foncé
  static const Color textHint = Color(0xFFBDBDBD); // Gris clair
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Blanc
  
  // Couleurs de fond
  static const Color background = Color(0xFFFAFAFA); // Gris très clair
  static const Color surface = Color(0xFFFFFFFF); // Blanc
  static const Color surfaceVariant = Color(0xFFF5F5F5); // Gris très clair
  
  // Couleurs de bordure
  static const Color border = Color(0xFFE0E0E0); // Gris clair
  static const Color borderLight = Color(0xFFF0F0F0); // Gris très clair
  static const Color borderDark = Color(0xFFBDBDBD); // Gris foncé
  
  // Couleurs spéciales
  static const Color price = Color(0xFFE65100); // Orange pour les prix
  static const Color discount = Color(0xFFF44336); // Rouge pour les réductions
  static const Color newProduct = Color(0xFF4CAF50); // Vert pour les nouveaux produits
  
  // Couleurs de gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Couleurs d'ombre
  static const Color shadow = Color(0x1A000000); // Noir avec transparence
  static const Color shadowLight = Color(0x0A000000); // Noir très transparent
  static const Color shadowDark = Color(0x33000000); // Noir plus opaque
}

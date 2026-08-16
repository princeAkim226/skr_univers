import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Icône de maison verte remplie pour Accueil (actif)
class HomeNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const HomeNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HomeIconPainter(isActive: isActive),
    );
  }
}

class _HomeIconPainter extends CustomPainter {
  final bool isActive;

  _HomeIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Maison verte remplie (actif)
      paint.style = PaintingStyle.fill;
      paint.color = AppTheme.primaryColor;
      
      // Toit pointu
      final roofPath = Path()
        ..moveTo(size.width * 0.5, size.height * 0.15)
        ..lineTo(size.width * 0.2, size.height * 0.45)
        ..lineTo(size.width * 0.8, size.height * 0.45)
        ..close();
      canvas.drawPath(roofPath, paint);
      
      // Base rectangulaire
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.5, size.height * 0.5),
        paint,
      );
    } else {
      // Maison grise en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
      
      // Toit pointu
      final roofPath = Path()
        ..moveTo(size.width * 0.5, size.height * 0.15)
        ..lineTo(size.width * 0.2, size.height * 0.45)
        ..lineTo(size.width * 0.8, size.height * 0.45)
        ..close();
      canvas.drawPath(roofPath, paint);
      
      // Base rectangulaire
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.25, size.height * 0.45, size.width * 0.5, size.height * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de storefront/market stall avec awning strié pour Produits
class ProductsNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const ProductsNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProductsIconPainter(isActive: isActive),
    );
  }
}

class _ProductsIconPainter extends CustomPainter {
  final bool isActive;

  _ProductsIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Storefront bleu rempli (actif)
      paint.style = PaintingStyle.fill;
      paint.color = Colors.blue;
    } else {
      // Storefront gris en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Base rectangulaire
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.5, size.width * 0.6, size.height * 0.4),
      paint,
    );
    
    // Awning strié (auvent)
    final awningPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.5)
      ..lineTo(size.width * 0.2, size.height * 0.35)
      ..lineTo(size.width * 0.8, size.height * 0.35)
      ..lineTo(size.width * 0.85, size.height * 0.5);
    
    if (isActive) {
      canvas.drawPath(awningPath, paint);
    } else {
      canvas.drawPath(awningPath, paint);
    }
    
    // Lignes striées sur l'awning
    if (isActive) {
      paint.color = Colors.white.withOpacity(0.3);
    } else {
      paint.color = const Color(0xFF9E9E9E);
    }
    for (int i = 0; i < 4; i++) {
      final x = size.width * 0.25 + (i * size.width * 0.15);
      canvas.drawLine(
        Offset(x, size.height * 0.35),
        Offset(x, size.height * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de sac avec poignée pour Panier
class CartNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const CartNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CartIconPainter(isActive: isActive),
    );
  }
}

class _CartIconPainter extends CustomPainter {
  final bool isActive;

  _CartIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Panier orange rempli (actif)
      paint.style = PaintingStyle.fill;
      paint.color = Colors.orange;
    } else {
      // Panier gris en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Corps du sac
    final bagPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.85)
      ..lineTo(size.width * 0.7, size.height * 0.85)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..close();
    canvas.drawPath(bagPath, paint);
    
    // Poignée
    if (isActive) {
      paint.color = Colors.white.withOpacity(0.3);
    } else {
      paint.color = const Color(0xFF9E9E9E);
    }
    final handlePath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.15,
        size.width * 0.65,
        size.height * 0.3,
      );
    canvas.drawPath(handlePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de document avec lignes pour Commandes
class OrdersNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const OrdersNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OrdersIconPainter(isActive: isActive),
    );
  }
}

class _OrdersIconPainter extends CustomPainter {
  final bool isActive;

  _OrdersIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF9E9E9E);
    
    // Contour du document
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.65),
      paint,
    );
    
    // Lignes horizontales à l'intérieur
    for (int i = 0; i < 4; i++) {
      final y = size.height * 0.35 + (i * size.height * 0.12);
      canvas.drawLine(
        Offset(size.width * 0.3, y),
        Offset(size.width * 0.7, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de silhouette en contour pour Profil
class ProfileNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const ProfileNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ProfileIconPainter(isActive: isActive),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  final bool isActive;

  _ProfileIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Profil indigo rempli (actif)
      paint.style = PaintingStyle.fill;
      paint.color = Colors.indigo;
    } else {
      // Profil gris en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Tête (cercle)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.35),
      size.width * 0.15,
      paint,
    );
    
    // Corps (forme de cloche)
    final bodyPath = Path()
      ..moveTo(size.width * 0.35, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.45,
        size.width * 0.65,
        size.height * 0.5,
      )
      ..lineTo(size.width * 0.65, size.height * 0.85)
      ..lineTo(size.width * 0.35, size.height * 0.85)
      ..close();
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de bulle de chat pour Conversations
class ChatNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const ChatNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ChatIconPainter(isActive: isActive),
    );
  }
}

class _ChatIconPainter extends CustomPainter {
  final bool isActive;

  _ChatIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Chat violet rempli (actif)
      paint.style = PaintingStyle.fill;
      paint.color = Colors.purple;
    } else {
      // Chat gris en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Bulle de chat principale
    final chatPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..lineTo(size.width * 0.2, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.6, size.height * 0.85)
      ..lineTo(size.width * 0.55, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.7)
      ..lineTo(size.width * 0.8, size.height * 0.3)
      ..close();
    canvas.drawPath(chatPath, paint);
    
    // Points de conversation (3 points)
    if (isActive) {
      paint.color = Colors.white;
    } else {
      paint.color = const Color(0xFF9E9E9E);
    }
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < 3; i++) {
      final x = size.width * 0.35 + (i * size.width * 0.15);
      canvas.drawCircle(
        Offset(x, size.height * 0.5),
        size.width * 0.03,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de mégaphone pour Publicités
class AdsNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const AdsNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AdsIconPainter(isActive: isActive),
    );
  }
}

class _AdsIconPainter extends CustomPainter {
  final bool isActive;

  _AdsIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Mégaphone rouge rempli (actif)
      paint.style = PaintingStyle.fill;
      paint.color = Colors.red;
    } else {
      // Mégaphone gris en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Corps du mégaphone
    final megaphonePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.3)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..lineTo(size.width * 0.5, size.height * 0.75)
      ..lineTo(size.width * 0.7, size.height * 0.7)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..close();
    canvas.drawPath(megaphonePath, paint);
    
    // Poignée
    if (isActive) {
      paint.color = Colors.white.withOpacity(0.3);
    } else {
      paint.color = const Color(0xFF9E9E9E);
    }
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.4, size.width * 0.1, size.height * 0.2),
      paint,
    );
    
    // Ondes sonores (3 lignes courbes)
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = isActive ? 1.5 : 2;
    for (int i = 0; i < 3; i++) {
      final startX = size.width * 0.75;
      final startY = size.height * 0.4 + (i * size.height * 0.1);
      final endX = size.width * 0.85 + (i * size.width * 0.05);
      final endY = startY;
      final controlX = size.width * 0.8 + (i * size.width * 0.03);
      final controlY = startY - (i * size.height * 0.05);
      
      final wavePath = Path()
        ..moveTo(startX, startY)
        ..quadraticBezierTo(controlX, controlY, endX, endY);
      canvas.drawPath(wavePath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de personnes pour Abonnements
class SubscriptionsNavIcon extends StatelessWidget {
  final bool isActive;
  final double size;

  const SubscriptionsNavIcon({
    super.key,
    this.isActive = false,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SubscriptionsIconPainter(isActive: isActive),
    );
  }
}

class _SubscriptionsIconPainter extends CustomPainter {
  final bool isActive;

  _SubscriptionsIconPainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    if (isActive) {
      // Personnes vertes remplies (actif)
      paint.style = PaintingStyle.fill;
      paint.color = AppTheme.primaryColor;
    } else {
      // Personnes grises en contour (inactif)
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2;
      paint.color = const Color(0xFF9E9E9E);
    }
    
    // Première personne (gauche)
    // Tête
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.3),
      size.width * 0.12,
      paint,
    );
    // Corps
    final body1Path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.4,
        size.width * 0.4,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..lineTo(size.width * 0.3, size.height * 0.8)
      ..close();
    canvas.drawPath(body1Path, paint);
    
    // Deuxième personne (droite, légèrement superposée)
    // Tête
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.3),
      size.width * 0.12,
      paint,
    );
    // Corps
    final body2Path = Path()
      ..moveTo(size.width * 0.6, size.height * 0.42)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.4,
        size.width * 0.7,
        size.height * 0.42,
      )
      ..lineTo(size.width * 0.7, size.height * 0.8)
      ..lineTo(size.width * 0.6, size.height * 0.8)
      ..close();
    canvas.drawPath(body2Path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

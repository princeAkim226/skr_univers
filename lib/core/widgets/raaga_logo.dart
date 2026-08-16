import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RaagaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;
  final Color? globeColor;

  const RaagaLogo({
    super.key,
    this.size = 100,
    this.showText = true,
    this.textColor,
    this.globeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo avec la lettre R
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: globeColor ?? Colors.green,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (globeColor ?? Colors.green).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: RLogoPainter(
              size: size,
              greenColor: Colors.transparent,
              blackColor: Colors.white,
            ),
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'B-Place',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: textColor ?? AppTheme.primaryColor,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Text(
            'Business Place',
            style: TextStyle(
              fontSize: size * 0.12,
              color: (textColor ?? AppTheme.primaryColor).withOpacity(0.7),
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class RaagaLogoSmall extends StatelessWidget {
  final double size;
  final Color? color;

  const RaagaLogoSmall({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Colors.green,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.green).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: RLogoPainter(
          size: size,
          greenColor: Colors.transparent,
          blackColor: Colors.white,
        ),
      ),
    );
  }
}

// Peintre personnalisé pour dessiner la lettre R stylisée
class RLogoPainter extends CustomPainter {
  final double size;
  final Color greenColor;
  final Color blackColor;

  RLogoPainter({
    required this.size,
    required this.greenColor,
    required this.blackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = blackColor; // La lettre R sera en blanc (blackColor est maintenant blanc)

    // Calculer les dimensions proportionnelles
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final letterWidth = size.width * 0.5;
    final letterHeight = size.height * 0.7;
    final strokeWidth = size.width * 0.18;

    // Dessiner la lettre R stylisée en blanc
    final path = Path();

    // Partie verticale gauche - trait vertical
    path.moveTo(centerX - letterWidth / 2, centerY - letterHeight / 2);
    path.lineTo(centerX - letterWidth / 2 + strokeWidth, centerY - letterHeight / 2);
    path.lineTo(centerX - letterWidth / 2 + strokeWidth, centerY + letterHeight / 2);
    path.lineTo(centerX - letterWidth / 2, centerY + letterHeight / 2);
    path.close();
    canvas.drawPath(path, paint);

    // Partie horizontale du haut - barre horizontale
    path.reset();
    path.moveTo(centerX - letterWidth / 2, centerY - letterHeight / 2);
    path.lineTo(centerX + letterWidth / 2, centerY - letterHeight / 2);
    path.lineTo(centerX + letterWidth / 2, centerY - letterHeight / 2 + strokeWidth);
    path.lineTo(centerX - letterWidth / 2 + strokeWidth, centerY - letterHeight / 2 + strokeWidth);
    path.close();
    canvas.drawPath(path, paint);

    // Partie courbe du haut - arc supérieur
    path.reset();
    final arcRect = Rect.fromLTWH(
      centerX - letterWidth / 2 + strokeWidth,
      centerY - letterHeight / 2,
      letterWidth - strokeWidth,
      letterHeight * 0.45,
    );
    path.arcTo(arcRect, -3.14159, 1.5708, false);
    path.lineTo(centerX - letterWidth / 2 + strokeWidth, centerY - letterHeight / 2 + letterHeight * 0.45);
    path.close();
    canvas.drawPath(path, paint);

    // Partie diagonale - jambe diagonale
    path.reset();
    path.moveTo(centerX - letterWidth / 2 + strokeWidth, centerY);
    path.lineTo(centerX + letterWidth / 2, centerY);
    path.lineTo(centerX + letterWidth / 2 - strokeWidth * 0.4, centerY + letterHeight / 2);
    path.lineTo(centerX - letterWidth / 2 + strokeWidth, centerY + letterHeight / 2);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

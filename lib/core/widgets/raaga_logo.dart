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
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                globeColor ?? AppTheme.primaryDarkColor,
                globeColor ?? AppTheme.primaryLightColor,
              ],
            ),
            borderRadius: BorderRadius.circular(size * 0.22),
            boxShadow: [
              BoxShadow(
                color: (globeColor ?? AppTheme.primaryColor).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'B',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.58,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -1,
              ),
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
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'Business Place',
            style: TextStyle(
              fontSize: size * 0.12,
              color: (textColor ?? AppTheme.primaryColor).withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
              letterSpacing: 0.8,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color ?? AppTheme.primaryDarkColor,
            color ?? AppTheme.primaryLightColor,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'B',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

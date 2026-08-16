import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/raaga_logo.dart';

/// Coquille visuelle partagée pour les pages Auth (login / inscription).
class AuthPageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;
  final IconData? headerIcon;
  final String brandLabel;

  const AuthPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
    this.headerIcon,
    this.brandLabel = 'B-Place',
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 400 ? width - 32 : 360.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF43A047),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -70, right: -50, child: _orb(200, 0.08)),
            Positioned(bottom: 80, left: -60, child: _orb(160, 0.06)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: Colors.white,
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Text(
                            brandLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.fromLTRB(0, 12, 0, 20 + bottom),
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: headerIcon == null
                                    ? const RaagaLogo(
                                        size: 58,
                                        showText: false,
                                        globeColor: Color(0xFF1B5E20),
                                      )
                                    : Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B5E20),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          headerIcon,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Material(
                              color: Colors.white.withValues(alpha: 0.97),
                              borderRadius: BorderRadius.circular(28),
                              elevation: 10,
                              shadowColor: Colors.black26,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _orb(double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

InputDecoration authInputDecoration({
  required String label,
  required IconData icon,
  String? hint,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.85)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF3F7F3),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppTheme.errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
    ),
  );
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final Color? color;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.primaryColor;
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class AuthSectionTitle extends StatelessWidget {
  final String text;
  const AuthSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }
}

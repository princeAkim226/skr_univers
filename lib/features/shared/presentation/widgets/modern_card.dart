import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.boxShadow,
    this.backgroundColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? AppTheme.mediumShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

class AnimatedModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final Duration animationDuration;

  const AnimatedModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.boxShadow,
    this.backgroundColor,
    this.gradient,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedModernCard> createState() => _AnimatedModernCardState();
}

class _AnimatedModernCardState extends State<AnimatedModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _animationController.forward() : null,
      onTapUp: widget.onTap != null ? (_) => _animationController.reverse() : null,
      onTapCancel: widget.onTap != null ? () => _animationController.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ModernCard(
              padding: widget.padding,
              margin: widget.margin,
              borderRadius: widget.borderRadius,
              boxShadow: widget.boxShadow,
              backgroundColor: widget.backgroundColor,
              gradient: widget.gradient,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 10,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

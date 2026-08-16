import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget de chargement moderne et élégant
class ModernLoadingWidget extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;
  final bool showMessage;

  const ModernLoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de chargement
          SizedBox(
            width: size ?? 50,
            height: size ?? 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? AppTheme.primaryColor,
              ),
            ),
          ),
          
          // Message de chargement
          if (showMessage && message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de chargement avec animation de pulsation
class PulsatingLoadingWidget extends StatefulWidget {
  final String? message;
  final double? size;
  final Color? color;

  const PulsatingLoadingWidget({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  State<PulsatingLoadingWidget> createState() => _PulsatingLoadingWidgetState();
}

class _PulsatingLoadingWidgetState extends State<PulsatingLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicateur de chargement avec animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: widget.size ?? 50,
                  height: widget.size ?? 50,
                  decoration: BoxDecoration(
                    color: (widget.color ?? AppTheme.primaryColor).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: widget.color ?? AppTheme.primaryColor,
                    size: (widget.size ?? 50) * 0.6,
                  ),
                ),
              );
            },
          ),
          
          // Message de chargement
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.message!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de chargement avec points animés
class DotsLoadingWidget extends StatefulWidget {
  final String? message;
  final Color? color;

  const DotsLoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  State<DotsLoadingWidget> createState() => _DotsLoadingWidgetState();
}

class _DotsLoadingWidgetState extends State<DotsLoadingWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    
    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Démarrer les animations avec un délai
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Points animés
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (widget.color ?? AppTheme.primaryColor)
                          .withOpacity(_animations[index].value),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
          
          // Message de chargement
          if (widget.message != null) ...[
            const SizedBox(height: 20),
            Text(
              widget.message!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de chargement avec barre de progression
class ProgressLoadingWidget extends StatelessWidget {
  final String? message;
  final double? progress;
  final Color? color;

  const ProgressLoadingWidget({
    super.key,
    this.message,
    this.progress,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de progression
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primaryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: progress != null
                ? LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color ?? AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          
          // Message de chargement
          if (message != null) ...[
            const SizedBox(height: 20),
            Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

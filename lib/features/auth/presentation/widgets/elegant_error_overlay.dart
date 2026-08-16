import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Overlay d'erreur élégant qui s'affiche par-dessus le contenu
class ElegantErrorOverlay extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onDismiss;

  const ElegantErrorOverlay({
    super.key,
    this.message,
    this.onRetry,
    this.onCreateAccount,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône d'erreur
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: AppTheme.errorColor,
                  size: 40,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Titre
              const Text(
                'Compte non trouvé',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Text(
                message ?? 'Aucun compte trouvé avec ce numéro de téléphone. Vérifiez votre numéro ou créez un nouveau compte.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Boutons d'action
              Row(
                children: [
                  if (onRetry != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Réessayer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onCreateAccount != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCreateAccount,
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Créer un compte'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Bouton fermer
              if (onDismiss != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text(
                    'Fermer',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour afficher l'overlay d'erreur
class ErrorOverlayWidget extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onDismiss;

  const ErrorOverlayWidget({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.onCreateAccount,
    this.onDismiss,
  });

  @override
  State<ErrorOverlayWidget> createState() => _ErrorOverlayWidgetState();
}

class _ErrorOverlayWidgetState extends State<ErrorOverlayWidget> {
  bool _showOverlay = false;

  @override
  void didUpdateWidget(ErrorOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null && widget.errorMessage != oldWidget.errorMessage) {
      setState(() {
        _showOverlay = true;
      });
    }
  }

  void _hideOverlay() {
    setState(() {
      _showOverlay = false;
    });
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay && widget.errorMessage != null)
          ElegantErrorOverlay(
            message: widget.errorMessage,
            onRetry: widget.onRetry,
            onCreateAccount: widget.onCreateAccount,
            onDismiss: _hideOverlay,
          ),
      ],
    );
  }
}

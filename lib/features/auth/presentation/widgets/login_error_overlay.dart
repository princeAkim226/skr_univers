import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Overlay d'erreur spécifique pour la connexion
class LoginErrorOverlay extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onDismiss;

  const LoginErrorOverlay({
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
              // Icône d'erreur spécifique
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _getErrorColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getErrorIcon(),
                  color: _getErrorColor(),
                  size: 40,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Titre spécifique
              Text(
                _getErrorTitle(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message spécifique
              Text(
                _getErrorMessage(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Boutons d'action spécifiques
              _buildActionButtons(),
              
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

  Color _getErrorColor() {
    if (message?.contains('Aucun compte trouvé') == true) {
      return AppTheme.warningColor;
    } else if (message?.contains('mot de passe') == true) {
      return AppTheme.errorColor;
    } else if (message?.contains('réseau') == true) {
      return AppTheme.infoColor;
    }
    return AppTheme.errorColor;
  }

  IconData _getErrorIcon() {
    if (message?.contains('Aucun compte trouvé') == true) {
      return Icons.person_search_rounded;
    } else if (message?.contains('mot de passe') == true) {
      return Icons.lock_outline_rounded;
    } else if (message?.contains('réseau') == true) {
      return Icons.wifi_off_rounded;
    }
    return Icons.error_outline_rounded;
  }

  String _getErrorTitle() {
    if (message?.contains('Aucun compte trouvé') == true) {
      return 'Compte non trouvé';
    } else if (message?.contains('mot de passe') == true) {
      return 'Mot de passe incorrect';
    } else if (message?.contains('réseau') == true) {
      return 'Problème de connexion';
    }
    return 'Erreur de connexion';
  }

  String _getErrorMessage() {
    if (message?.contains('Aucun compte trouvé') == true) {
      return 'Aucun compte trouvé avec ce numéro de téléphone. Vérifiez votre numéro ou créez un nouveau compte.';
    } else if (message?.contains('mot de passe') == true) {
      return 'Le mot de passe saisi est incorrect. Vérifiez votre mot de passe ou réinitialisez-le.';
    } else if (message?.contains('réseau') == true) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.';
    }
    return message ?? 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  }

  Widget _buildActionButtons() {
    if (message?.contains('Aucun compte trouvé') == true) {
      return Row(
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
      );
    } else if (message?.contains('mot de passe') == true) {
      return Row(
        children: [
          if (onRetry != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
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
      );
    } else {
      return Row(
        children: [
          if (onRetry != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
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
      );
    }
  }
}

/// Widget pour afficher l'overlay d'erreur de connexion
class LoginErrorOverlayWidget extends StatefulWidget {
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onDismiss;

  const LoginErrorOverlayWidget({
    super.key,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.onCreateAccount,
    this.onDismiss,
  });

  @override
  State<LoginErrorOverlayWidget> createState() => _LoginErrorOverlayWidgetState();
}

class _LoginErrorOverlayWidgetState extends State<LoginErrorOverlayWidget> {
  bool _showOverlay = false;

  @override
  void didUpdateWidget(LoginErrorOverlayWidget oldWidget) {
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
          LoginErrorOverlay(
            message: widget.errorMessage,
            onRetry: widget.onRetry,
            onCreateAccount: widget.onCreateAccount,
            onDismiss: _hideOverlay,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Widget réutilisable pour afficher les états d'erreur
class ErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const ErrorWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryText,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.lightShadow,
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
            child: Icon(
              icon ?? Icons.error_outline,
              size: 40,
              color: AppTheme.errorColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          
          // Message
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          
          // Bouton de retry
          if (onRetry != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(retryText ?? 'Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour les erreurs de chargement
class LoadingErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const LoadingErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Erreur de chargement',
      message: message ?? 'Impossible de charger les données. Vérifiez votre connexion internet.',
      icon: Icons.cloud_off_outlined,
      onRetry: onRetry,
      retryText: 'Réessayer',
    );
  }
}

/// Widget pour les erreurs de réseau
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Problème de connexion',
      message: 'Vérifiez votre connexion internet et réessayez.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryText: 'Réessayer',
    );
  }
}

/// Widget pour les erreurs de permission
class PermissionErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const PermissionErrorWidget({
    super.key,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      title: 'Permission requise',
      message: message ?? 'Cette fonctionnalité nécessite une permission spéciale.',
      icon: Icons.lock_outline,
      onRetry: onRetry,
      retryText: 'Autoriser',
    );
  }
}

/// Widget pour les erreurs de données vides
class EmptyDataWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyDataWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.inbox_outlined,
              size: 40,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          
          // Message
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
          
          // Bouton d'action
          if (onAction != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionText ?? 'Ajouter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget pour les erreurs de validation de formulaire
class ValidationErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ValidationErrorWidget({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: AppTheme.errorColor,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

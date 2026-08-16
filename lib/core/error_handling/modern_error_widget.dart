import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget d'erreur moderne et élégant
class ModernErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showIcon;
  final bool isCompact;

  const ModernErrorWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryText,
    this.backgroundColor,
    this.padding,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactError(context);
    }
    
    return _buildFullError(context);
  }

  Widget _buildFullError(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône d'erreur avec animation
          if (showIcon) ...[
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: 50,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Titre
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          
          // Message
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
          
          // Bouton de retry
          if (onRetry != null) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  retryText ?? 'Réessayer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              icon ?? Icons.error_outline_rounded,
              color: AppTheme.errorColor,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (message != null) ...[
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                retryText ?? 'Réessayer',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget d'erreur de connexion spécifique
class ConnectionErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool isCompact;

  const ConnectionErrorWidget({
    super.key,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernErrorWidget(
      title: 'Problème de connexion',
      message: 'Vérifiez votre connexion internet et réessayez.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
      retryText: 'Réessayer',
      isCompact: isCompact,
    );
  }
}

/// Widget d'erreur d'authentification spécifique
class AuthErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool isCompact;

  const AuthErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernErrorWidget(
      title: 'Erreur de connexion',
      message: message ?? 'Vérifiez vos informations de connexion.',
      icon: Icons.lock_outline_rounded,
      onRetry: onRetry,
      retryText: 'Réessayer',
      isCompact: isCompact,
    );
  }
}

/// Widget d'erreur de données spécifique
class DataErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool isCompact;

  const DataErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernErrorWidget(
      title: 'Erreur de chargement',
      message: message ?? 'Impossible de charger les données.',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
      retryText: 'Recharger',
      isCompact: isCompact,
    );
  }
}

/// Widget d'erreur de validation spécifique
class ValidationErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final bool isCompact;

  const ValidationErrorWidget({
    super.key,
    required this.message,
    this.onDismiss,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ModernErrorWidget(
      title: 'Erreur de validation',
      message: message,
      icon: Icons.warning_amber_rounded,
      onRetry: onDismiss,
      retryText: 'Fermer',
      isCompact: isCompact,
    );
  }
}

/// Widget d'état vide moderne
class ModernEmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;
  final Color? iconColor;

  const ModernEmptyStateWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionText,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: (iconColor ?? AppTheme.textSecondaryColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.inbox_outlined,
              size: 50,
              color: iconColor ?? AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Titre
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
          
          // Message
          if (message != null) ...[
            Text(
              message!,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
          
          // Bouton d'action
          if (onAction != null) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  actionText ?? 'Ajouter',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

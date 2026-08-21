import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'error_boundary.dart';
import 'error_handler.dart';
import '../theme/app_theme.dart';

/// Gestionnaire d'erreurs global pour l'application
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  /// Initialise le gestionnaire d'erreurs global
  static void initialize() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousOnError?.call(details);

      if (isNonFatalFlutterError(details.exception)) {
        ErrorHandler.logError(
          details.exception,
          context: 'IgnoredNonFatalFlutterError',
          stackTrace: details.stack,
        );
        return;
      }

      ErrorHandler.logError(
        details.exception,
        context: 'FlutterError',
        stackTrace: details.stack,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (isNonFatalFlutterError(error)) {
        ErrorHandler.logError(
          error,
          context: 'IgnoredNonFatalPlatformError',
          stackTrace: stack,
        );
        return true;
      }
      ErrorHandler.logError(
        error,
        context: 'PlatformError',
        stackTrace: stack,
      );
      return true;
    };
  }

  /// Affiche une erreur de connexion réseau
  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.wifi_off, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Text('Problème de connexion'),
          ],
        ),
        content: const Text(
          'Vérifiez votre connexion internet et réessayez. Si le problème persiste, contactez le support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de permission
  static void showPermissionError(
    BuildContext context, {
    required String permission,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: AppTheme.warningColor, size: 24),
            const SizedBox(width: 8),
            const Text('Permission requise'),
          ],
        ),
        content: Text(
          'Cette fonctionnalité nécessite l\'accès à $permission. Veuillez l\'autoriser dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Autoriser'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de stockage
  static void showStorageError(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.storage, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Text('Espace de stockage insuffisant'),
          ],
        ),
        content: const Text(
          'L\'espace de stockage de votre appareil est insuffisant. Veuillez libérer de l\'espace et réessayer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de serveur
  static void showServerError(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Text('Erreur du serveur'),
          ],
        ),
        content: const Text(
          'Le serveur rencontre des difficultés temporaires. Veuillez réessayer dans quelques minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de validation de formulaire
  static void showValidationError(
    BuildContext context, {
    required String field,
    required String message,
  }) {
    ErrorHandler.showError(
      context,
      'Erreur de validation',
      customMessage: '$field: $message',
    );
  }

  /// Affiche une erreur de paiement
  static void showPaymentError(
    BuildContext context, {
    required String reason,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Text('Erreur de paiement'),
          ],
        ),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de géolocalisation
  static void showLocationError(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: AppTheme.warningColor, size: 24),
            const SizedBox(width: 8),
            const Text('Localisation indisponible'),
          ],
        ),
        content: const Text(
          'Impossible d\'obtenir votre position. Veuillez vérifier que la localisation est activée et réessayer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }

  /// Affiche une erreur de fichier
  static void showFileError(
    BuildContext context, {
    required String reason,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.file_upload, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            const Text('Erreur de fichier'),
          ],
        ),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';

/// Gestionnaire centralisé des erreurs de l'application
class ErrorHandler {
  static const String _defaultErrorMessage = 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
  
  /// Types d'erreurs reconnus
  static const Map<String, String> _errorMessages = {
    // Erreurs d'authentification
    'user_already_exists': 'Un compte existe déjà avec ce numéro ou cet email. Connectez-vous avec votre mot de passe.',
    'invalid_credentials': 'Email ou mot de passe incorrect.',
    'email_not_confirmed': 'Veuillez confirmer votre email avant de vous connecter.',
    'weak_password': 'Le mot de passe doit contenir au moins 6 caractères.',
    'invalid_email': 'Adresse email invalide.',
    'user_not_found': 'Aucun compte trouvé avec ces informations.',
    'too_many_requests': 'Trop de tentatives. Veuillez attendre quelques minutes.',
    
    // Erreurs de base de données
    '42703': 'Erreur de configuration de la base de données. Veuillez contacter le support.',
    '23505': 'Cette information existe déjà dans notre système.',
    '23503': 'Impossible de supprimer cet élément car il est utilisé ailleurs.',
    '42P01': 'Table non trouvée. Veuillez contacter le support.',
    '42501': 'Accès refusé. Vous n\'avez pas les permissions nécessaires.',
    
    // Erreurs de réseau
    'network_error': 'Problème de connexion. Vérifiez votre connexion internet.',
    'timeout': 'La requête a expiré. Veuillez réessayer.',
    'server_error': 'Erreur du serveur. Veuillez réessayer plus tard.',
    
    // Erreurs de validation
    'validation_error': 'Les informations fournies ne sont pas valides.',
    'required_field': 'Ce champ est obligatoire.',
    'invalid_phone': 'Format de numéro de téléphone invalide.',
    'invalid_format': 'Format de données invalide.',
    
    // Erreurs de paiement
    'payment_failed': 'Le paiement a échoué. Veuillez réessayer.',
    'insufficient_funds': 'Fonds insuffisants pour effectuer cette transaction.',
    'card_declined': 'Votre carte a été refusée. Contactez votre banque.',
    'payment_timeout': 'Le paiement a expiré. Veuillez réessayer.',
    
    // Erreurs de stock
    'out_of_stock': 'Ce produit n\'est plus en stock.',
    'insufficient_stock': 'Stock insuffisant pour cette quantité.',
    
    // Erreurs de géolocalisation
    'location_denied': 'Accès à la localisation refusé.',
    'location_unavailable': 'Impossible d\'obtenir votre position.',
    'location_timeout': 'Délai d\'attente de localisation dépassé.',
    
    // Erreurs de fichiers
    'file_too_large': 'Le fichier est trop volumineux.',
    'invalid_file_type': 'Type de fichier non supporté.',
    'upload_failed': 'Échec du téléchargement du fichier.',
  };

  /// Convertit une erreur technique en message utilisateur convivial
  static String getUserFriendlyMessage(dynamic error) {
    if (error == null) return _defaultErrorMessage;

    if (error is String) {
      return _sanitize(error);
    }
    
    String errorString = error.toString().toLowerCase();
    
    // Gestion des erreurs Supabase spécifiques
    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }
    
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }
    
    if (error is StorageException) {
      return _getStorageErrorMessage(error);
    }
    
    // Recherche par mots-clés dans le message d'erreur
    for (final entry in _errorMessages.entries) {
      if (errorString.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Si c'est une Exception avec un message, essayer de l'utiliser
    if (error is Exception) {
      final message = error.toString();
      if (message.isNotEmpty && message != 'Exception: null' && !message.startsWith('Exception: Exception')) {
        final cleanMessage = _sanitize(message);
        if (cleanMessage != _defaultErrorMessage) {
          return cleanMessage;
        }
      }
    }
    
    // Gestion des erreurs de réseau
    if (errorString.contains('socketexception') || 
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused')) {
      return _errorMessages['network_error']!;
    }
    
    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return _errorMessages['timeout']!;
    }
    
    // Gestion des erreurs de validation
    if (errorString.contains('validation') || 
        errorString.contains('invalid') ||
        errorString.contains('required')) {
      return _errorMessages['validation_error']!;
    }
    
    // Gestion des erreurs de permissions
    if (errorString.contains('permission') || 
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied')) {
      return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
    }
    
    // Gestion des erreurs de null
    if (errorString.contains('null') && errorString.contains('null check')) {
      return 'Une information manquante a causé une erreur. Veuillez réessayer.';
    }
    
    return _defaultErrorMessage;
  }

  static bool _looksTechnical(String message) {
    final value = message.toLowerCase();
    const markers = [
      'postgrest',
      'socketexception',
      'jwt',
      'stack',
      'package:',
      '#0 ',
      'typeerror',
      'null check',
      'sqlstate',
      'violates',
      'pgrst',
      'supabase',
      'postgres',
      'schema cache',
      'relation',
      'column',
      'dart:',
      'flutter error',
      'lateinitialization',
      'nosuchmethod',
      'rangeerror',
      'formatexception',
      'xmlhttprequest',
      'row-level security',
      'rls policy',
      'authretryable',
      'invalid jwt',
      'hint:',
      'details:',
      'statuscode',
      'status code',
      'syntax error',
      'undefined table',
      'does not exist',
      'permission denied for',
      'failed host lookup',
      'os error',
      'errno',
    ];
    return markers.any(value.contains);
  }

  static String _sanitize(String message) {
    var clean = message.trim();
    if (clean.startsWith('Exception: ')) {
      clean = clean.substring(11).trim();
    }
    if (clean.isEmpty || _looksTechnical(clean) || clean.length > 160) {
      return _defaultErrorMessage;
    }
    return clean;
  }

  static String _displayMessage(dynamic error, String? customMessage) {
    if (customMessage != null &&
        customMessage.trim().isNotEmpty &&
        !_looksTechnical(customMessage)) {
      final clean = _sanitize(customMessage);
      if (clean != _defaultErrorMessage) return clean;
    }
    return getUserFriendlyMessage(error);
  }
  
  /// Gestion spécifique des erreurs Postgrest
  static String _getPostgrestErrorMessage(PostgrestException error) {
    final code = error.code;
    final message = error.message;
    
    // Messages d'erreur plus détaillés
    switch (code) {
      case '42703':
        return 'Une erreur technique s’est produite. Réessayez dans un instant.';
      case '23505':
        return 'Cette information existe déjà dans notre système.';
      case '23503':
        return 'Impossible de supprimer cet élément car il est utilisé ailleurs.';
      case '42P01':
        return 'Service temporairement indisponible. Réessayez plus tard.';
      case '42501':
        return 'Accès refusé. Vous n\'avez pas les permissions nécessaires pour cette action.';
      case 'PGRST301':
        return 'Aucun résultat trouvé.';
      case 'PGRST116':
        return 'Impossible de terminer cette action. Vérifiez vos informations.';
      case 'PGRST204':
        return 'Aucune donnée trouvée.';
      case 'PGRST205':
        return 'Service temporairement indisponible. Réessayez dans quelques instants.';
      case 'PGRST202':
        return 'Certaines informations sont incorrectes.';
      default:
        // Essayer d'extraire un message utile
        if (message.isNotEmpty && message != 'null') {
          // Nettoyer le message pour qu'il soit plus lisible
          String cleanMessage = message;
          if (cleanMessage.contains('violates')) {
            if (cleanMessage.contains('unique constraint')) {
              return 'Cette information existe déjà.';
            }
            if (cleanMessage.contains('foreign key constraint')) {
              return 'Impossible d\'effectuer cette action car l\'élément est utilisé ailleurs.';
            }
            if (cleanMessage.contains('not-null constraint')) {
              return 'Certaines informations obligatoires sont manquantes.';
            }
          }
          if (!_looksTechnical(cleanMessage) && cleanMessage.length < 160) {
            return _sanitize(cleanMessage);
          }
        }
        return 'Impossible de terminer cette action. Réessayez.';
    }
  }
  
  /// Gestion spécifique des erreurs d'authentification
  static String _getAuthErrorMessage(AuthException error) {
    final code = error.statusCode;
    final message = error.message.toLowerCase();
    // Rate limit email
    if (code == '429' || message.contains('rate limit') || message.contains('over_email_send_rate_limit')) {
      return 'Trop de tentatives. Attendez quelques minutes.';
    }
    // Inscriptions email désactivées dans Supabase (il faut les réactiver)
    if (message.contains('email signups are disabled') || message.contains('email_provider_disabled')) {
      return 'Inscription temporairement indisponible. Réessayez plus tard.';
    }
    switch (error.statusCode) {
      case '400':
        if (error.message.contains('Invalid login credentials')) {
          return 'Email ou mot de passe incorrect.';
        }
        if (error.message.contains('Email not confirmed')) {
          return 'Veuillez confirmer votre email avant de vous connecter.';
        }
        if (message.contains('invalid') && message.contains('email')) {
          return 'Adresse email invalide. Réessayez ou contactez le support.';
        }
        return 'Informations de connexion invalides.';
      case '422':
        if (error.message.contains('User already registered') || message.contains('already registered')) {
          return 'Un compte existe déjà avec ce numéro ou cet email. Connectez-vous avec votre mot de passe.';
        }
        return 'Données de compte invalides.';
      case '429':
        return 'Trop de tentatives. Veuillez attendre quelques minutes.';
      case '500':
        return 'Erreur du serveur. Veuillez réessayer plus tard.';
      default:
        return _defaultErrorMessage;
    }
  }
  
  /// Gestion spécifique des erreurs de stockage
  static String _getStorageErrorMessage(StorageException error) {
    switch (error.statusCode) {
      case '413':
        return 'Le fichier est trop volumineux.';
      case '415':
        return 'Type de fichier non supporté.';
      case '403':
        return 'Accès refusé au fichier.';
      case '404':
        return 'Fichier non trouvé.';
      default:
        return 'Erreur lors du téléchargement du fichier.';
    }
  }
  
  /// Affiche une erreur dans l'interface utilisateur
  static void showError(BuildContext context, dynamic error, {
    String? customMessage,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
    bool showAsDialog = false,
  }) {
    final message = _displayMessage(error, customMessage);
    
    if (showAsDialog) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.errorColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry();
                        },
                        child: const Text('Réessayer'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onRetry();
                  },
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
  
  /// Affiche un message de succès
  static void showSuccess(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Affiche un message d'information
  static void showInfo(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.infoColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Affiche un message d'avertissement
  static void showWarning(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.warningColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Affiche une boîte de dialogue d'erreur
  static void showErrorDialog(BuildContext context, dynamic error, {
    String? title,
    String? customMessage,
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    final message = _displayMessage(error, customMessage);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor, size: 24),
            const SizedBox(width: 8),
            Text(title ?? 'Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel();
              },
              child: const Text('Annuler'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Réessayer'),
            )
          else
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }
  
  /// Log l'erreur pour le débogage (à implémenter avec un service de logging)
  static void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    // Log détaillé pour faciliter le diagnostic
    print('═══════════════════════════════════════════════════════════');
    print('❌ ERREUR DÉTECTÉE');
    print('═══════════════════════════════════════════════════════════');
    print('Contexte: ${context ?? "Non spécifié"}');
    print('Type: ${error.runtimeType}');
    print('Message: $error');
    
    // Détails spécifiques selon le type d'erreur
    if (error is PostgrestException) {
      print('Code Supabase: ${error.code}');
      print('Message Supabase: ${error.message}');
      print('Détails: ${error.details}');
      print('Hint: ${error.hint}');
    } else if (error is AuthException) {
      print('Status Code: ${error.statusCode}');
      print('Message Auth: ${error.message}');
    } else if (error is StorageException) {
      print('Status Code: ${error.statusCode}');
      print('Message Storage: ${error.message}');
    }
    
    if (stackTrace != null) {
      print('═══════════════════════════════════════════════════════════');
      print('STACK TRACE:');
      print(stackTrace);
    }
    print('═══════════════════════════════════════════════════════════');

    AppLogger.error(
      error,
      stackTrace: stackTrace,
      context: context,
    );
  }
}

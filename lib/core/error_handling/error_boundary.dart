import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_handler.dart';
import 'modern_error_widget.dart';
import 'modern_loading_widget.dart';

/// Ancienne « barrière » d’erreur.
///
/// Important : on ne détourne plus [FlutterError.onError] ici.
/// Avant, toute erreur (image cassée, overflow web, etc.) remplacait
/// **toute l’application** par l’écran « Oups », ce qui bloquait la navigation.
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? fallbackTitle;
  final String? fallbackMessage;
  final VoidCallback? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackTitle,
    this.fallbackMessage,
    this.onError,
  });

  @override
  Widget build(BuildContext context) => child;
}

/// Mixin pour faciliter la gestion d'erreurs dans les StatefulWidget
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Exécute une fonction asynchrone avec gestion d'erreurs
  Future<void> executeWithErrorHandling(
    Future<void> Function() action, {
    String? loadingMessage,
    bool showLoadingSnackBar = false,
    bool showErrorSnackBar = true,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (showLoadingSnackBar && loadingMessage != null) {
      ErrorHandler.showInfo(context, loadingMessage);
    }

    try {
      await action();
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      onSuccess?.call();
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandler.getUserFriendlyMessage(error);
      });

      ErrorHandler.logError(error, context: 'ErrorHandlingMixin');

      if (showErrorSnackBar && mounted) {
        ErrorHandler.showError(context, error);
      }

      onError?.call();
    }
  }

  /// Exécute une fonction avec retry automatique
  Future<void> executeWithRetry(
    Future<void> Function() action, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    String? retryMessage,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        await action();
        return;
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries) {
          setState(() {
            _isLoading = false;
            _errorMessage = ErrorHandler.getUserFriendlyMessage(error);
          });
          if (mounted) {
            ErrorHandler.showError(
              context,
              error,
              onRetry: () => executeWithRetry(
                action,
                maxRetries: maxRetries,
                delay: delay,
              ),
            );
          }
          return;
        }

        if (retryMessage != null && mounted) {
          ErrorHandler.showInfo(
            context,
            '$retryMessage (Tentative $attempts/$maxRetries)',
          );
        }

        await Future.delayed(delay);
      }
    }
  }

  void showCustomError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ErrorHandler.showError(context, message);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccess(context, message);
  }

  void showInfo(String message) {
    ErrorHandler.showInfo(context, message);
  }

  void showWarning(String message) {
    ErrorHandler.showWarning(context, message);
  }

  void clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  Widget buildErrorWidget({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool isCompact = false,
  }) {
    if (_errorMessage == null) return const SizedBox.shrink();

    return ModernErrorWidget(
      title: title,
      message: message ?? _errorMessage,
      onRetry: onRetry ?? () => clearError(),
      isCompact: isCompact,
    );
  }

  Widget buildLoadingWidget({
    String? message,
    double? size,
    bool usePulsating = false,
    bool useDots = false,
  }) {
    if (!_isLoading) return const SizedBox.shrink();

    if (usePulsating) {
      return PulsatingLoadingWidget(
        message: message,
        size: size,
      );
    }

    if (useDots) {
      return DotsLoadingWidget(
        message: message,
      );
    }

    return ModernLoadingWidget(
      message: message,
      size: size,
    );
  }
}

/// Extension pour faciliter l'utilisation du mixin
extension ErrorHandlingExtension on State {
  Future<void> safeExecute(
    Future<void> Function() action, {
    String? successMessage,
    bool showSuccess = true,
  }) async {
    try {
      await action();
      if (showSuccess && successMessage != null) {
        ErrorHandler.showSuccess(context, successMessage);
      }
    } catch (error) {
      ErrorHandler.showError(context, error);
    }
  }
}

/// Indique si une erreur Flutter est non fatale (ne doit pas bloquer l’UI).
bool isNonFatalFlutterError(Object error) {
  final lower = error.toString().toLowerCase();
  const markers = [
    '_debugduringdeviceupdate',
    'a renderflex overflowed by',
    'http request failed',
    'networkimage',
    'failed to load network image',
    'invalid image data',
    'imagecodec',
    'statuscode: 400',
    'statuscode: 403',
    'statuscode: 404',
    'statuscode: 500',
    'not supported on this platform',
    'binding has not yet been initialized',
  ];
  return markers.any(lower.contains);
}

/// Petit widget d’erreur local (remplace seulement le widget cassé).
Widget buildFriendlyErrorWidget(FlutterErrorDetails details) {
  if (isNonFatalFlutterError(details.exception)) {
    return const SizedBox.shrink();
  }

  return Material(
    color: Colors.transparent,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          ErrorHandler.getUserFriendlyMessage(details.exception),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      ),
    ),
  );
}

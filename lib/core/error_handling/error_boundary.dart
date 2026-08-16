import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_handler.dart';
import 'modern_error_widget.dart';
import 'modern_loading_widget.dart';

/// Widget qui capture les erreurs non gérées et les affiche de manière conviviale
class ErrorBoundary extends StatefulWidget {
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
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  dynamic _error;
  StackTrace? _stackTrace;
  FlutterExceptionHandler? _previousOnError;

  @override
  void initState() {
    super.initState();
    
    // Capturer les erreurs Flutter
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      // Toujours laisser le handler précédent faire son travail (logs, etc.)
      _previousOnError?.call(details);
      _handleError(details.exception, details.stack);
    };
  }

  void _handleError(dynamic error, StackTrace? stackTrace) {
    // Ne pas afficher l'écran rouge pour les erreurs attendues de chargement d'image réseau
    // (ex: URL Supabase Storage invalide / fichier manquant -> HTTP 400/404).
    final message = error.toString();
    final lower = message.toLowerCase();
    final bool isNetworkImageFailure =
        lower.contains('http request failed') ||
        lower.contains('networkimage') ||
        lower.contains('image') && (lower.contains('statuscode: 400') || lower.contains('statuscode: 404'));

    if (isNetworkImageFailure) {
      // On log, mais on n'affiche pas l'ErrorBoundary
      ErrorHandler.logError(error, context: 'IgnoredImageLoadError', stackTrace: stackTrace);
      return;
    }

    // Assertion Flutter liée au mouse tracker (debug) : ne pas bloquer l'app
    // Exemple: mouse_tracker.dart:203:12 !_debugDuringDeviceUpdate is not true
    // Sur Flutter Web, le message varie selon l'environnement (chemin absolu, etc.).
    // On filtre dès qu'on voit _debugDuringDeviceUpdate (même si le fichier n'est pas présent).
    final bool isMouseTrackerAssertion = lower.contains('_debugduringdeviceupdate');
    if (isMouseTrackerAssertion) {
      ErrorHandler.logError(error, context: 'IgnoredMouseTrackerAssertion', stackTrace: stackTrace);
      return;
    }

    // RenderFlex overflow (debug) : très fréquent sur Web/mobile en debug.
    // On log uniquement pour éviter une boucle où l'ErrorBoundary affiche... un overflow.
    final bool isRenderFlexOverflow = lower.contains('a renderflex overflowed by');
    if (isRenderFlexOverflow) {
      ErrorHandler.logError(error, context: 'IgnoredRenderFlexOverflow', stackTrace: stackTrace);
      return;
    }

    // Logger l'erreur avec plus de détails
    print('❌ ErrorBoundary - Erreur capturée:');
    print('Type: ${error.runtimeType}');
    print('Message: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    
    // Utiliser SchedulerBinding pour éviter les appels setState pendant le build
    final effectiveStack = stackTrace ?? StackTrace.current;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _error = error;
          _stackTrace = effectiveStack;
        });
      }
    });

    // Logger l'erreur
    ErrorHandler.logError(error, context: 'ErrorBoundary', stackTrace: effectiveStack);

    // Callback personnalisé
    widget.onError?.call();
  }

  void _resetError() {
    setState(() {
      _hasError = false;
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      // Version ultra-simple qui ne peut pas échouer
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _SimpleErrorWidget(
                  title: widget.fallbackTitle ?? 'Oups ! Une erreur s\'est produite',
                  message: widget.fallbackMessage ?? 
                    ErrorHandler.getUserFriendlyMessage(_error),
                  error: _error,
                  stackTrace: _stackTrace,
                  onRetry: _resetError,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
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
      
      if (showErrorSnackBar) {
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
        return; // Succès
      } catch (error) {
        attempts++;
        
        if (attempts >= maxRetries) {
          // Dernière tentative échouée
          setState(() {
            _isLoading = false;
            _errorMessage = ErrorHandler.getUserFriendlyMessage(error);
          });
          ErrorHandler.showError(
            context, 
            error,
            onRetry: () => executeWithRetry(action, maxRetries: maxRetries, delay: delay),
          );
          return;
        }
        
        // Attendre avant de réessayer
        if (retryMessage != null) {
          ErrorHandler.showInfo(context, '$retryMessage (Tentative $attempts/$maxRetries)');
        }
        
        await Future.delayed(delay);
      }
    }
  }

  /// Affiche un message d'erreur personnalisé
  void showCustomError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ErrorHandler.showError(context, message);
  }

  /// Affiche un message de succès
  void showSuccess(String message) {
    ErrorHandler.showSuccess(context, message);
  }

  /// Affiche un message d'information
  void showInfo(String message) {
    ErrorHandler.showInfo(context, message);
  }

  /// Affiche un message d'avertissement
  void showWarning(String message) {
    ErrorHandler.showWarning(context, message);
  }

  /// Efface le message d'erreur
  void clearError() {
    setState(() {
      _errorMessage = null;
    });
  }

  /// Widget d'erreur conditionnel
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

  /// Widget de chargement conditionnel
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
  /// Exécute une action avec gestion d'erreurs simplifiée
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

/// Widget d'erreur ULTRA-SIMPLE - juste du texte et un bouton
/// Version qui fonctionne à coup sûr sur mobile
class _SimpleErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const _SimpleErrorWidget({
    required this.title,
    required this.message,
    this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              width: constraints.maxWidth > 600 ? 600 : constraints.maxWidth - 32,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icône
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Détails techniques
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    _SimpleErrorDetails(error: error, stackTrace: stackTrace),
                  ],
                  // Bouton
                  if (onRetry != null) ...[
                    const SizedBox(height: 16),
                    _SimpleButton(
                      text: 'Recharger',
                      onPressed: onRetry!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bouton simple
class _SimpleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SimpleButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Détails d'erreur ultra-simple
class _SimpleErrorDetails extends StatefulWidget {
  final dynamic error;
  final StackTrace? stackTrace;

  const _SimpleErrorDetails({required this.error, this.stackTrace});

  @override
  State<_SimpleErrorDetails> createState() => _SimpleErrorDetailsState();
}

class _SimpleErrorDetailsState extends State<_SimpleErrorDetails> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final errorText = widget.error.toString();
    final st = widget.stackTrace?.toString();
    final fullText = (st == null || st.trim().isEmpty) ? errorText : '$errorText\n\n$st';

    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: _isExpanded ? _buildExpanded(fullText) : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          '▶ Détails techniques',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(String displayText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '▼ Détails techniques',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            child: Text(
              displayText,
              style: const TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

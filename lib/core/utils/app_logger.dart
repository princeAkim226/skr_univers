import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/app_logging_config.dart';

/// Logging centralisé (console + Sentry optionnel).
class AppLogger {
  static bool _sentryReady = false;

  static Future<void> init() async {
    final dsn = AppLoggingConfig.sentryDsn.trim();
    if (dsn.isEmpty) {
      _sentryReady = false;
      if (kDebugMode) {
        debugPrint('AppLogger: Sentry désactivé (DSN vide)');
      }
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.2;
        options.environment = kReleaseMode ? 'production' : 'debug';
      },
    );
    _sentryReady = true;
  }

  static void info(String message, {String? context}) {
    final prefix = context == null ? '' : '[$context] ';
    debugPrint('INFO $prefix$message');
  }

  static Future<void> error(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    final prefix = context == null ? '' : '[$context] ';
    debugPrint('ERROR $prefix$error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }

    if (_sentryReady) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (context != null) {
            scope.setTag('context', context);
          }
        },
      );
    }
  }
}

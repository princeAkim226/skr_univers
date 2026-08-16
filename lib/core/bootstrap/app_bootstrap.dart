import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/url_strategy.dart'
    if (dart.library.html) '../config/url_strategy_web.dart';
import '../error_handling/global_error_handler.dart';
import '../utils/app_logger.dart';
import '../../data/services/notification_service.dart';

Future<void> bootstrapApp({
  required Widget app,
  bool initNotifications = false,
}) async {
  debugInvertOversizedImages = false;

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              style: ThemeData().textTheme.titleLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Veuillez relancer l’application',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  };

  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  try {
    await AppLogger.init();
    GlobalErrorHandler.initialize();
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    if (initNotifications) {
      try {
        await NotificationService.initialize();
      } catch (e) {
        debugPrint('Notifications non initialisées: $e');
      }
    }

    runApp(app);
  } catch (error, stackTrace) {
    await AppLogger.error(error, stackTrace: stackTrace, context: 'bootstrap');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 50),
                  const SizedBox(height: 20),
                  Text(
                    'Erreur de démarrage',
                    style: ThemeData().textTheme.titleLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Impossible de démarrer. Réessayez plus tard.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

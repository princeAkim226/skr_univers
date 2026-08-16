import 'package:flutter/material.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/constants/app_constants.dart';
import 'core/error_handling/error_boundary.dart';
import 'core/routes/app_router.dart';
import 'core/theme/simple_green_theme.dart';
import 'core/widgets/app_scroll_behavior.dart';

/// Plateforme 1 (mobile) et plateforme 2 (copie web de l’app).
/// La plateforme d’administration est un autre programme : [admin_main.dart].
void main() async {
  await bootstrapApp(
    app: const BPlaceApp(),
    initNotifications: true,
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BPlaceApp extends StatelessWidget {
  const BPlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp.router(
        key: navigatorKey,
        title: AppConstants.appName,
        theme: SimpleGreenTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              boldText: false,
              disableAnimations: true,
              textScaler: const TextScaler.linear(1.0),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/constants/app_constants.dart';
import 'core/error_handling/error_boundary.dart';
import 'core/routes/admin_router.dart';
import 'core/theme/simple_green_theme.dart';
import 'core/widgets/app_scroll_behavior.dart';

/// Plateforme 3 : administration B-Place.
/// Programme distinct de l’app mobile et de sa copie web.
void main() async {
  await bootstrapApp(
    app: const BPlaceAdminApp(),
    initNotifications: false,
  );
}

class BPlaceAdminApp extends StatelessWidget {
  const BPlaceAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp.router(
        title: AppConstants.adminAppName,
        theme: SimpleGreenTheme.lightTheme,
        routerConfig: AdminRouter.router,
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

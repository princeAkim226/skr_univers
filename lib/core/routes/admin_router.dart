import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_login_page.dart';
import '../../features/admin/presentation/pages/admin_merchant_ads_page.dart';
import '../../features/admin/presentation/pages/admin_merchants_page.dart';
import '../../features/admin/presentation/pages/admin_platform_ads_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_promo_codes_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/admin/presentation/widgets/admin_platform_shell.dart';
import '../../data/services/auth_service.dart';
import '../theme/app_theme.dart';

/// Routeur exclusif de la plateforme d’administration.
class AdminRouter {
  static final _authService = AuthService();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminPlatformShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'admin-dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminDashboardPage(),
            ),
          ),
          GoRoute(
            path: '/users',
            name: 'admin-users',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminUsersPage(),
            ),
          ),
          GoRoute(
            path: '/merchants',
            name: 'admin-merchants',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminMerchantsPage(),
            ),
          ),
          GoRoute(
            path: '/products',
            name: 'admin-products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminProductsPage(),
            ),
          ),
          GoRoute(
            path: '/ads',
            name: 'admin-platform-ads',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminPlatformAdsPage(),
            ),
          ),
          GoRoute(
            path: '/merchant-ads',
            name: 'admin-merchant-ads',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminMerchantAdsPage(),
            ),
          ),
          GoRoute(
            path: '/promo-codes',
            name: 'admin-promo-codes',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AdminPromoCodesPage(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final loggedIn = _authService.isAuthenticated;
      final goingToLogin = state.uri.path == '/login';

      if (!loggedIn) {
        return goingToLogin ? null : '/login';
      }

      final isAdmin = await _authService.isCurrentUserAdmin();
      if (!isAdmin) {
        await _authService.signOut();
        return '/login';
      }

      if (goingToLogin) return '/';
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text('Page introuvable', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Tableau de bord'),
            ),
          ],
        ),
      ),
    ),
  );
}

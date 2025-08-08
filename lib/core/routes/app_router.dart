import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/customer/presentation/pages/customer_home_page.dart';
import '../../features/merchant/presentation/pages/merchant_home_page.dart';
import '../../features/shared/presentation/pages/splash_page.dart';
import '../constants/app_constants.dart';
import '../../data/services/auth_service.dart';

class AppRouter {
  static final _authService = AuthService(); // Instancier le service d'authentification

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Page de démarrage
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Sélection du type d'utilisateur
      GoRoute(
        path: '/user-type-selection',
        name: 'user-type-selection',
        builder: (context, state) => const UserTypeSelectionPage(),
      ),
      
      // Authentification
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => RegisterPage(
          userType: state.uri.queryParameters['userType'] ?? AppConstants.userTypeCustomer,
        ),
      ),
      
      // Routes pour les clients
      GoRoute(
        path: '/customer',
        name: 'customer-home',
        builder: (context, state) => const CustomerHomePage(),
        routes: [
          GoRoute(
            path: 'products',
            name: 'customer-products',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Liste des produits')),
            ),
          ),
          GoRoute(
            path: 'product/:id',
            name: 'customer-product-detail',
            builder: (context, state) => Scaffold(
              body: Center(child: Text('Détail produit: ${state.pathParameters['id']}')),
            ),
          ),
          GoRoute(
            path: 'cart',
            name: 'customer-cart',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Panier')),
            ),
          ),
          GoRoute(
            path: 'orders',
            name: 'customer-orders',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Mes commandes')),
            ),
          ),
          GoRoute(
            path: 'profile',
            name: 'customer-profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profil client')),
            ),
          ),
        ],
      ),
      
      // Routes pour les e-commerçants
      GoRoute(
        path: '/merchant',
        name: 'merchant-home',
        builder: (context, state) => const MerchantHomePage(),
        routes: [
          GoRoute(
            path: 'products',
            name: 'merchant-products',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Mes produits')),
            ),
          ),
          GoRoute(
            path: 'add-product',
            name: 'merchant-add-product',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Ajouter un produit')),
            ),
          ),
          GoRoute(
            path: 'edit-product/:id',
            name: 'merchant-edit-product',
            builder: (context, state) => Scaffold(
              body: Center(child: Text('Modifier produit: ${state.pathParameters['id']}')),
            ),
          ),
          GoRoute(
            path: 'orders',
            name: 'merchant-orders',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Commandes reçues')),
            ),
          ),
          GoRoute(
            path: 'analytics',
            name: 'merchant-analytics',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Analytics')),
            ),
          ),
          GoRoute(
            path: 'profile',
            name: 'merchant-profile',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Profil e-commerçant')),
            ),
          ),
        ],
      ),
    ],
    
    // Redirection basée sur l'état d'authentification
    redirect: (context, state) {
      final bool loggedIn = _authService.isAuthenticated;
      final String? userType = _authService.userType;
      
      final bool goingToLogin = state.uri.path == '/login';
      final bool goingToRegister = state.uri.path.startsWith('/register');
      final bool goingToUserTypeSelection = state.uri.path == '/user-type-selection';
      final bool goingToSplash = state.uri.path == '/';

      // Si l'utilisateur n'est pas connecté
      if (!loggedIn) {
        // Autoriser l'accès aux pages d'authentification et de démarrage
        return (goingToLogin || goingToRegister || goingToUserTypeSelection || goingToSplash)
            ? null // Laisser l'utilisateur sur la page demandée
            : '/user-type-selection'; // Rediriger vers la sélection du type d'utilisateur
      }

      // Si l'utilisateur est connecté
      // Rediriger les utilisateurs connectés loin des pages d'authentification
      if (goingToLogin || goingToRegister || goingToUserTypeSelection || goingToSplash) {
        if (userType == AppConstants.userTypeMerchant) {
          return '/merchant'; // Connecté en tant qu'e-commerçant
        } else if (userType == AppConstants.userTypeCustomer) {
          return '/customer'; // Connecté en tant que client
        }
        return '/customer'; // Par défaut si le type n'est pas clair
      }

      // Aucune redirection nécessaire si l'utilisateur est déjà sur une page autorisée et non-auth
      return null;
    },
    
    // Gestion des erreurs
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'La page ${state.uri} n\'existe pas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    ),
  );
} 
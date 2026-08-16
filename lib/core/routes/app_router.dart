import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/simple_login_page.dart';
import '../../features/auth/presentation/pages/simple_register_page.dart';
import '../../features/auth/presentation/pages/user_type_selection_page.dart';
import '../../features/merchant/presentation/pages/merchant_signup_page.dart';
import '../../features/customer/presentation/pages/customer_home_page.dart';
import '../../features/customer/presentation/pages/product_detail_page.dart';
import '../../features/customer/presentation/pages/products_page.dart';
import '../../features/customer/presentation/pages/habitation_category_page.dart';
import '../../features/customer/presentation/pages/vetements_category_page.dart';
import '../../features/customer/presentation/pages/livres_category_page.dart';
import '../../features/customer/presentation/pages/motor_category_page.dart';
import '../../features/customer/presentation/pages/beaute_category_page.dart';
import '../../features/customer/presentation/pages/electronics_category_page.dart';
import '../../features/customer/presentation/pages/equipements_category_page.dart';
import '../../features/customer/presentation/pages/divertissement_category_page.dart';
import '../../features/customer/presentation/pages/jobs_category_page.dart';
import '../../features/customer/presentation/pages/art_category_page.dart';
import '../../features/customer/presentation/pages/fournitures_category_page.dart';
import '../../features/customer/presentation/pages/animaux_category_page.dart';
import '../../features/customer/presentation/pages/merchant_products_page.dart';
import '../../features/customer/presentation/pages/cart_page.dart';
import '../../features/customer/presentation/pages/checkout_page.dart';
import '../../features/customer/presentation/pages/payment_page.dart';
import '../../features/customer/presentation/pages/orders_page.dart';
import '../../features/customer/presentation/pages/favorites_page.dart';
import '../../features/customer/presentation/pages/search_page.dart';
import '../../features/merchant/presentation/pages/merchant_home_page.dart';
import '../../features/merchant/presentation/pages/add_product_page.dart';
import '../../features/merchant/presentation/pages/add_story_page.dart';
import '../../features/merchant/presentation/pages/stories_page.dart';
import '../../features/merchant/presentation/pages/products_page.dart' as merchant_pages;
import '../../features/shared/presentation/pages/splash_page.dart';
import '../../features/shared/presentation/pages/notifications_page.dart';
import '../../features/customer/presentation/pages/customer_messaging_page.dart';
import '../../features/customer/presentation/pages/chat_page.dart';
import '../../features/merchant/presentation/pages/messaging_page.dart';
import '../../features/merchant/presentation/pages/merchant_chat_page.dart';
import '../../features/merchant/presentation/pages/add_ad_page.dart';
import '../../features/merchant/presentation/pages/plans_selection_page.dart';
import '../../features/merchant/presentation/pages/story_stats_page.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../data/services/auth_service.dart';

class AppRouter {
  static final _authService = AuthService(); // Instancier le service d'authentification
  
  static Widget _missingParamPage(BuildContext context, String paramName, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(
                'Paramètre manquant',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Le paramètre "$paramName" est requis pour ouvrir cette page.\nRoute: ${state.uri}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/customer'),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Page de démarrage
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
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
        builder: (context, state) => const SimpleLoginPage(),
      ),
      
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => SimpleRegisterPage(
          userType: state.uri.queryParameters['userType'] ?? AppConstants.userTypeCustomer,
        ),
      ),
      
      GoRoute(
        path: '/merchant-signup',
        name: 'merchant-signup',
        builder: (context, state) => const MerchantSignupPage(),
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
            builder: (context, state) {
              final category = state.extra as Map<String, dynamic>?;
              return ProductsPage(
                initialCategory: category?['category'],
              );
            },
          ),
          GoRoute(
            path: 'search',
            name: 'customer-search',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: 'habitations',
            name: 'customer-habitations',
            builder: (context, state) => const HabitationCategoryPage(),
            // Pour tester la version simplifiée, décommenter la ligne suivante :
            // builder: (context, state) => const HabitationCategoryPageSimple(),
          ),
          GoRoute(
            path: 'vetements',
            name: 'customer-vetements',
            builder: (context, state) => const VetementsCategoryPage(),
          ),
          GoRoute(
            path: 'livres',
            name: 'customer-livres',
            builder: (context, state) => const LivresCategoryPage(),
          ),
          GoRoute(
            path: 'motor',
            name: 'customer-motor',
            builder: (context, state) => const MotorCategoryPage(),
          ),
          GoRoute(
            path: 'beaute',
            name: 'customer-beaute',
            builder: (context, state) => const BeauteCategoryPage(),
          ),
          GoRoute(
            path: 'electroniques',
            name: 'customer-electroniques',
            builder: (context, state) => const ElectronicsCategoryPage(),
          ),
          GoRoute(
            path: 'equipements',
            name: 'customer-equipements',
            builder: (context, state) => const EquipementsCategoryPage(),
          ),
          GoRoute(
            path: 'divertissement',
            name: 'customer-divertissement',
            builder: (context, state) => const DivertissementCategoryPage(),
          ),
          GoRoute(
            path: 'art',
            name: 'customer-art',
            builder: (context, state) => const ArtCategoryPage(),
          ),
          GoRoute(
            path: 'fournitures',
            name: 'customer-fournitures',
            builder: (context, state) => const FournituresCategoryPage(),
          ),
          GoRoute(
            path: 'animaux',
            name: 'customer-animaux',
            builder: (context, state) => const AnimauxCategoryPage(),
          ),
          GoRoute(
            path: 'jobs',
            name: 'customer-jobs',
            builder: (context, state) => const JobsCategoryPage(),
          ),
          GoRoute(
            path: 'product/:id',
            name: 'customer-product-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              if (id == null || id.trim().isEmpty) {
                return _missingParamPage(context, 'id', state);
              }
              return ProductDetailPage(productId: id);
            },
          ),
          GoRoute(
            path: 'merchant/:merchantId',
            name: 'customer-merchant-products',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId'];
              if (merchantId == null || merchantId.trim().isEmpty) {
                return _missingParamPage(context, 'merchantId', state);
              }
              return MerchantProductsPage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'cart',
            name: 'customer-cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: 'checkout',
            name: 'customer-checkout',
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
            path: 'payment/:orderId',
            name: 'customer-payment',
            builder: (context, state) {
              final orderId = state.pathParameters['orderId'];
              if (orderId == null || orderId.trim().isEmpty) {
                return _missingParamPage(context, 'orderId', state);
              }
              return PaymentPage(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'orders',
            name: 'customer-orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: 'favorites',
            name: 'customer-favorites',
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: 'messaging',
            name: 'customer-messaging',
            builder: (context, state) => const CustomerMessagingPage(),
          ),
          GoRoute(
            path: 'chat/:conversationId',
            name: 'customer-chat',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId'];
              if (conversationId == null || conversationId.trim().isEmpty) {
                return _missingParamPage(context, 'conversationId', state);
              }
              final conversation = state.extra as Map<String, dynamic>? ?? {};
              return ChatPage(
                conversationId: conversationId,
                conversation: conversation,
              );
            },
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
            path: 'add-product',
            name: 'merchant-add-product',
            builder: (context, state) => const AddProductPage(),
          ),
          GoRoute(
            path: 'add-story',
            name: 'merchant-add-story',
            builder: (context, state) => const AddStoryPage(),
          ),
          GoRoute(
            path: 'add-ad',
            name: 'merchant-add-ad',
            builder: (context, state) => const AddAdPage(),
          ),
          GoRoute(
            path: 'stories',
            name: 'merchant-stories',
            builder: (context, state) => const MerchantStoriesPage(),
          ),
          GoRoute(
            path: 'products',
            name: 'merchant-products',
            builder: (context, state) => const merchant_pages.MerchantProductsPage(),
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
            path: 'messaging',
            name: 'merchant-messaging',
            builder: (context, state) => const MerchantMessagingPage(),
          ),
          GoRoute(
            path: 'chat/:conversationId',
            name: 'merchant-chat',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId'];
              if (conversationId == null || conversationId.trim().isEmpty) {
                return _missingParamPage(context, 'conversationId', state);
              }
              final conversation = state.extra as Map<String, dynamic>? ?? {};
              return MerchantChatPage(
                conversationId: conversationId,
                conversation: conversation,
              );
            },
          ),
          GoRoute(
            path: 'plans',
            name: 'merchant-plans',
            builder: (context, state) => const PlansSelectionPage(),
          ),
          GoRoute(
            path: 'story-stats',
            name: 'merchant-story-stats',
            builder: (context, state) => const StoryStatsPage(),
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
    redirect: (context, state) async {
      final bool loggedIn = _authService.isAuthenticated;
      final String? userType = _authService.userType;
      
      final bool goingToLogin = state.uri.path == '/login';
      final bool goingToRegister = state.uri.path.startsWith('/register');
      final bool goingToUserTypeSelection = state.uri.path == '/user-type-selection';
      final bool goingToMerchantSignup = state.uri.path == '/merchant-signup';
      final bool goingToSplash = state.uri.path == '/';

      // Si l'utilisateur n'est pas connecté
      if (!loggedIn) {
        return (goingToLogin || goingToRegister || goingToUserTypeSelection || goingToMerchantSignup || goingToSplash)
            ? null
            : '/user-type-selection';
      }

      // Si l'utilisateur est connecté, le sortir des pages d'authentification
      if (goingToLogin || goingToRegister || goingToUserTypeSelection || goingToMerchantSignup || goingToSplash) {
        if (userType == AppConstants.userTypeMerchant) {
          return '/merchant';
        }
        return '/customer';
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
              Icons.search_off_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Page introuvable',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Ce lien n’existe pas ou n’est plus disponible.',
                textAlign: TextAlign.center,
              ),
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
# Système de Gestion d'Erreurs - SKR Univers

## Vue d'ensemble

Ce système centralisé de gestion d'erreurs améliore considérablement l'expérience utilisateur en fournissant des messages d'erreur clairs, conviviaux et en français, tout en offrant des mécanismes de récupération robustes.

## Composants principaux

### 1. ErrorHandler
Le gestionnaire central des erreurs qui convertit les erreurs techniques en messages utilisateur compréhensibles.

```dart
// Utilisation basique
ErrorHandler.showError(context, error);

// Avec message personnalisé
ErrorHandler.showError(context, error, customMessage: 'Message personnalisé');

// Avec option de retry
ErrorHandler.showError(
  context, 
  error, 
  onRetry: () => _retryOperation(),
);
```

### 2. ErrorWidget
Widgets réutilisables pour afficher les états d'erreur dans l'interface.

```dart
// Widget d'erreur générique
ErrorWidget(
  title: 'Erreur de chargement',
  message: 'Impossible de charger les données',
  onRetry: () => _loadData(),
)

// Widget d'erreur de réseau
NetworkErrorWidget(onRetry: () => _retryConnection())

// Widget pour données vides
EmptyDataWidget(
  title: 'Aucun produit trouvé',
  message: 'Commencez par ajouter vos premiers produits',
  onAction: () => _addProduct(),
)
```

### 3. ErrorHandlingMixin
Mixin qui simplifie la gestion d'erreurs dans les StatefulWidget.

```dart
class MyPage extends StatefulWidget {
  // ...
}

class _MyPageState extends State<MyPage> with ErrorHandlingMixin {
  Future<void> _loadData() async {
    await executeWithErrorHandling(
      () async {
        // Votre logique métier ici
        final data = await apiService.getData();
        setState(() => _data = data);
      },
      onSuccess: () => showSuccess('Données chargées avec succès'),
    );
  }
}
```

### 4. ErrorBoundary
Widget qui capture les erreurs non gérées et les affiche de manière conviviale.

```dart
ErrorBoundary(
  child: MyApp(),
  fallbackTitle: 'Erreur de l\'application',
  fallbackMessage: 'Une erreur inattendue s\'est produite',
)
```

## Types d'erreurs gérées

### Erreurs d'authentification
- `user_already_exists` : "Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email."
- `invalid_credentials` : "Email ou mot de passe incorrect."
- `email_not_confirmed` : "Veuillez confirmer votre email avant de vous connecter."

### Erreurs de base de données
- `42703` : "Erreur de configuration de la base de données. Veuillez contacter le support."
- `23505` : "Cette information existe déjà dans notre système."
- `42501` : "Accès refusé. Vous n'avez pas les permissions nécessaires."

### Erreurs de réseau
- `network_error` : "Problème de connexion. Vérifiez votre connexion internet."
- `timeout` : "La requête a expiré. Veuillez réessayer."

### Erreurs de validation
- `validation_error` : "Les informations fournies ne sont pas valides."
- `required_field` : "Ce champ est obligatoire."

## Utilisation dans les pages

### Exemple complet

```dart
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> with ErrorHandlingMixin {
  List<Product> _products = [];
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    await executeWithErrorHandling(
      () async {
        final products = await ProductService.getProducts();
        setState(() => _products = products);
      },
      onSuccess: () => showInfo('${_products.length} produits chargés'),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: buildLoadingWidget(message: 'Chargement des produits...'),
      );
    }
    
    if (_products.isEmpty) {
      return Scaffold(
        body: Center(
          child: EmptyDataWidget(
            title: 'Aucun produit trouvé',
            message: 'Commencez par ajouter vos premiers produits',
            onAction: () => _addProduct(),
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Column(
        children: [
          // Affichage des erreurs
          buildErrorWidget(),
          
          // Liste des produits
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) => ProductCard(_products[index]),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Messages d'erreur personnalisés

### Ajouter un nouveau type d'erreur

```dart
// Dans ErrorHandler._errorMessages
'custom_error_code': 'Message personnalisé en français',
```

### Gestion spécifique d'erreurs

```dart
// Dans votre service
try {
  await apiCall();
} catch (e) {
  if (e.toString().contains('custom_error')) {
    throw Exception('custom_error_code');
  }
  rethrow;
}
```

## Bonnes pratiques

1. **Toujours utiliser le mixin** : Utilisez `ErrorHandlingMixin` dans vos StatefulWidget pour une gestion d'erreurs cohérente.

2. **Messages en français** : Tous les messages d'erreur doivent être en français et compréhensibles par l'utilisateur final.

3. **Options de retry** : Proposez toujours une option de retry quand c'est possible.

4. **Logging** : Les erreurs sont automatiquement loggées pour le débogage.

5. **États de chargement** : Utilisez `buildLoadingWidget()` pour les états de chargement.

6. **Données vides** : Utilisez `EmptyDataWidget` pour les cas où aucune donnée n'est disponible.

## Intégration avec Supabase

Le système gère automatiquement les erreurs Supabase :

- `PostgrestException` : Erreurs de base de données
- `AuthException` : Erreurs d'authentification
- `StorageException` : Erreurs de stockage de fichiers

## Configuration globale

Le système est initialisé automatiquement dans `main.dart` :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le gestionnaire d'erreurs global
  GlobalErrorHandler.initialize();
  
  // ... reste de l'initialisation
}
```

## Widgets d'erreur disponibles

- `ErrorWidget` : Widget d'erreur générique
- `LoadingErrorWidget` : Erreur de chargement
- `NetworkErrorWidget` : Erreur de réseau
- `PermissionErrorWidget` : Erreur de permission
- `EmptyDataWidget` : Données vides
- `ValidationErrorWidget` : Erreur de validation

## Exemples d'utilisation

Voir les pages mises à jour :
- `lib/features/auth/presentation/pages/login_page.dart`
- `lib/features/auth/presentation/pages/register_page.dart`
- `lib/features/customer/presentation/pages/payment_page.dart`
- `lib/features/customer/presentation/pages/profile_page.dart`

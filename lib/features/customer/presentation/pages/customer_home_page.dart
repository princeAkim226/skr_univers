import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/category_service.dart';
import '../widgets/products_list.dart';
import '../widgets/product_card.dart';
import '../widgets/stories_widget.dart';
import '../widgets/ad_section_widget.dart';
import '../widgets/category_selector.dart';
import 'cart_page.dart';
import 'customer_messaging_page.dart';
import 'profile_page.dart';
import 'merchants_discovery_page.dart';
import '../../../../core/constants/categories.dart';
import '../../../../core/widgets/raaga_bottom_nav.dart';
import '../../../../core/widgets/app_nav_shell.dart';
import '../../../../core/widgets/raaga_logo.dart';
import '../../../../core/theme/vintage_icons.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const _ProductsTab(),
    const _CartTab(),
    const _MessagesTab(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return AppNavShell(
      backgroundColor: const Color(0xFFF4F7F4),
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: RaagaBottomNav.customerItems,
      appBar: (_currentIndex == 0 || _currentIndex == 4)
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'B-Place',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppTheme.primaryDarkColor,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  color: AppTheme.textPrimaryColor,
                  onPressed: () => context.push('/customer/search'),
                ),
              ],
            ),
      body: _pages[_currentIndex],
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CategoryService _categoryService = CategoryService();
  List<Map<String, dynamic>> _featuredProducts = [];
  List<String> _categories = [];
  Map<String, int> _categoryStats = {};
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedProducts();
  }

  // Méthode pour rafraîchir les statistiques des catégories
  Future<void> _refreshCategoryStats() async {
    try {
      print('🔄 Rafraîchissement des statistiques des catégories...');
      
      // Vérifier la cohérence avant de mettre à jour
      await _categoryService.verifyCategoryConsistency();
      
      // Utiliser les statistiques nettoyées
      final updatedStats = await _categoryService.getCleanCategoryStats();
      setState(() {
        _categoryStats = updatedStats;
      });
      
      print('✅ Statistiques mises à jour (nettoyées): $_categoryStats');
    } catch (e) {
      ErrorHandler.logError(e, context: '_refreshCategoryStats');
      if (mounted) {
        ErrorHandler.showError(context, e, showAsDialog: false);
      }
    }
  }

  Future<void> _loadFeaturedProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Récupérer les centres d'intérêt de l'utilisateur
      final user = _authService.currentUser;
      final interests = user?.interests ?? [];
      
      List<Map<String, dynamic>> products;
      if (interests.isNotEmpty) {
        products = await _productService.getProductsByInterests(interests);
      } else {
        products = await _productService.getProducts();
      }
      
      // Charger les catégories et leurs statistiques nettoyées
      final categories = await _categoryService.getAllCategories();
      final categoryStats = await _categoryService.getCleanCategoryStats();
      
      setState(() {
        _featuredProducts = products.take(4).toList();
        _categories = categories;
        _categoryStats = categoryStats;
        _isLoading = false;
      });
    } catch (e) {
      ErrorHandler.logError(e, context: '_loadFeaturedProducts');
      setState(() {
        _isLoading = false;
        // En cas d'erreur, garder les listes vides plutôt que de planter
        _featuredProducts = [];
        _categories = [];
        _categoryStats = {};
      });
      // Ne pas afficher de SnackBar ici pour éviter de spammer l'utilisateur
      // L'interface affichera simplement "Aucun produit recommandé"
    }
  }

  Future<void> _filterByCategory(String? category) async {
    if (category == null) {
      // Recharger tous les produits
      await _loadFeaturedProducts();
    } else {
      // Filtrer par catégorie
      try {
        setState(() {
          _isLoading = true;
        });
        
        // Appeler la méthode de débogage approfondie
        await _categoryService.debugCategoryThoroughly(category);
        
        final products = await _categoryService.getProductsByCategory(category);
        
        // Mettre à jour les statistiques des catégories pour refléter l'état réel
        final updatedStats = await _categoryService.getCleanCategoryStats();
        
        setState(() {
          _featuredProducts = products; // Afficher tous les produits de la catégorie, pas seulement 4
          _selectedCategory = category;
          _categoryStats = updatedStats; // Mettre à jour les statistiques
          _isLoading = false;
        });
      } catch (e) {
        ErrorHandler.logError(e, context: '_filterByCategory');
        setState(() {
          _isLoading = false;
          // En cas d'erreur, réinitialiser la sélection
          _selectedCategory = null;
          _featuredProducts = [];
        });
        if (mounted) {
          ErrorHandler.showError(context, e, showAsDialog: false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          await _loadFeaturedProducts();
          await _refreshCategoryStats();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Hero immersif RAAGA
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF43A047),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const RaagaLogoSmall(size: 40, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'B-Place',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        _HeroIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Votre marché\nlocal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Produits, boutiques et offres près de chez vous',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.push('/customer/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.grey.shade600),
                            const SizedBox(width: 10),
                            Text(
                              'Rechercher un produit, une boutique...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroActionChip(
                            icon: Icons.storefront_outlined,
                            label: 'Boutiques',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MerchantsDiscoveryPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroActionChip(
                            icon: Icons.grid_view_rounded,
                            label: 'Produits',
                            onTap: () => context.push('/customer/products'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stories (cachées si vides)
                    Builder(
                      builder: (context) {
                        try {
                          return const StoriesWidget();
                        } catch (e) {
                          ErrorHandler.logError(e, context: '_HomeTab.build - StoriesWidget');
                          return const SizedBox.shrink();
                        }
                      },
                    ),

                    const Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explorez selon vos envies',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 118,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _buildCategoryCard(
                            category.name,
                            category.imageAsset,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Publicités
                    Builder(
                      builder: (context) {
                        try {
                          return const AdSectionWidget();
                        } catch (e) {
                          ErrorHandler.logError(e, context: '_HomeTab.build - AdSectionWidget');
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 8),

                    if (_categories.isNotEmpty) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filtrer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _refreshCategoryStats,
                            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
                            tooltip: 'Rafraîchir',
                          ),
                        ],
                      ),
                      CategorySelector(
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        onCategorySelected: _filterByCategory,
                        categoryStats: _categoryStats,
                      ),
                      const SizedBox(height: 18),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedCategory != null
                                ? _selectedCategory!
                                : 'À découvrir',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimaryColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _selectedCategory == null
                              ? () => context.push('/customer/products')
                              : () => _filterByCategory(null),
                          child: Text(
                            _selectedCategory == null ? 'Voir tout' : 'Réinitialiser',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildFeaturedProducts(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String title, String imageAsset) {
    return GestureDetector(
      onTap: () => _openCategory(title),
      child: Container(
        width: 96,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F1E6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC9B896), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imageAsset,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  child: Icon(
                    _getCategoryIcon(title),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF3D2E1E),
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _openCategory(String title) {
    switch (title) {
      case 'Habitations':
      case 'Maison':
        context.push('/customer/habitations');
        break;
      case 'Vêtements':
      case 'Mode':
        context.push('/customer/vetements');
        break;
      case 'Livres':
        context.push('/customer/livres');
        break;
      case 'Moteurs':
        context.push('/customer/motor');
        break;
      case 'Électroniques':
      case 'Électronique':
        context.push('/customer/electroniques');
        break;
      case 'Équipement sport':
      case 'Sport':
        context.push('/customer/equipements');
        break;
      case 'Divertissement':
        context.push('/customer/divertissement');
        break;
      case 'Beauté':
        context.push('/customer/beaute');
        break;
      case 'Art':
        context.push('/customer/art');
        break;
      case 'Fournitures':
        context.push('/customer/fournitures');
        break;
      case 'Animaux':
        context.push('/customer/animaux');
        break;
      case 'Jobs':
        context.push('/customer/jobs');
        break;
      default:
        context.push('/customer/products', extra: {'category': title});
    }
  }

  Widget _buildFeaturedProducts() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_featuredProducts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4EBE4)),
        ),
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _selectedCategory != null
                  ? 'Aucun produit dans "$_selectedCategory"'
                  : 'Les produits apparaîtront ici bientôt',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Si une catégorie est sélectionnée, afficher en grille
    if (_selectedCategory != null) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _featuredProducts.length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return ProductCard(product: product);
        },
      );
    }

    // Sinon, afficher en liste horizontale (produits recommandés)
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _featuredProducts.take(4).length,
        itemBuilder: (context, index) {
          final product = _featuredProducts[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: ProductCard(product: product),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    return VintageIcons.category(categoryName);
  }

}

class _HeroIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return const ProductsList();
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    return const CartPage();
  }
}

class _MessagesTab extends StatelessWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context) {
    return const CustomerMessagingPage();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const CustomerProfilePage();
  }
}

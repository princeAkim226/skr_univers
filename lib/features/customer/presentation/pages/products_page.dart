import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';

class ProductsPage extends StatefulWidget {
  final String? initialCategory;
  const ProductsPage({super.key, this.initialCategory});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
      _loadProductsByCategory(widget.initialCategory!);
    } else {
      _loadProducts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _loadProductsByCategory(String category) async {
    try {
      setState(() => _isLoading = true);
      final products = category == 'Tous'
          ? await _productService.getProducts()
          : await _productService.getProductsByCategory(category);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadProducts();
      return;
    }

    try {
      setState(() => _isLoading = true);
      final results = await _productService.searchProducts(query: query.trim());
      setState(() {
        _products = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go('/customer/search'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showCategoryFilter();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadProducts();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              onChanged: (value) {
                _performSearch(value);
              },
            ),
          ),
          
          // Filtres de catégories
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Tous', _selectedCategory == 'Tous'),
                const SizedBox(width: 8),
                _buildCategoryChip('Électronique', _selectedCategory == 'Électronique'),
                const SizedBox(width: 8),
                _buildCategoryChip('Mode', _selectedCategory == 'Mode'),
                const SizedBox(width: 8),
                _buildCategoryChip('Maison', _selectedCategory == 'Maison'),
                const SizedBox(width: 8),
                _buildCategoryChip('Sport', _selectedCategory == 'Sport'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _products.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Aucun produit disponible',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: _products[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
        _loadProductsByCategory(category);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filtrer par catégorie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Tous',
                'Électronique',
                'Mode',
                'Maison',
                'Sport',
                'Livres',
                'Beauté',
                'Art',
              ].map((category) => _buildCategoryChip(category, _selectedCategory == category)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

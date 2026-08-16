import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/product_service.dart';

class MerchantProductsPage extends StatefulWidget {
  const MerchantProductsPage({super.key});

  @override
  State<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends State<MerchantProductsPage> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      final products = await _productService.getMyProducts();
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des produits: $e')),
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité de suppression à implémenter'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: StyledAppBar(
        title: 'Mes produits',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Ajouter un produit',
            icon: Icon(VintageIcons.merchantAction('Ajouter un produit')),
            onPressed: () async {
              final result = await context.push('/merchant/add-product');
              if (result == true) {
                _loadProducts();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
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
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Aucun produit créé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Commencez par ajouter votre premier produit',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Adapter la disposition selon la largeur de l'écran
                      if (constraints.maxWidth > 600) {
                        // Écrans larges : grille de 2 colonnes
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        );
                      } else {
                        // Écrans étroits : liste verticale
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return _buildProductCard(product);
                          },
                        );
                      }
                    },
                  ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final String title = product['title'] ?? 'Produit';
    final double price = (product['price'] ?? 0).toDouble();
    final String imageUrl = product['images'] != null && 
        (product['images'] as List).isNotEmpty 
        ? (product['images'] as List).first 
        : '';
    final bool isActive = product['is_active'] ?? true;
    final String category = product['category'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.shopping_bag,
                            color: Colors.grey[400],
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag,
                      color: Colors.grey[400],
                      size: 30,
                    ),
            ),
            const SizedBox(width: 16),
            
            // Informations du produit
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${price.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.priceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/merchant/edit-product/${product['id']}');
                    break;
                  case 'delete':
                    _showDeleteDialog(product);
                    break;
                  case 'toggle':
                    // TODO: Implémenter l'activation/désactivation
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, size: 16),
                      SizedBox(width: 8),
                      Text('Activer/Désactiver'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${product['title']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteProduct(product['id']);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

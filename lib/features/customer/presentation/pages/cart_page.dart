import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/cart_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await _cartService.getCartItems();
      setState(() {
        _cartItems = items;
        _total = _cartService.calculateTotal(items);
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

  Future<void> _updateQuantity(String cartItemId, int quantity) async {
    try {
      await _cartService.updateQuantity(cartItemId, quantity);
      await _loadCartItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _removeItem(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
      await _loadCartItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Article supprimé du panier'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _proceedToCheckout() async {
    if (_cartItems.isEmpty) return;

    // Vérifier la disponibilité des produits
    final unavailableProducts = await _cartService.checkAvailability(_cartItems);
    if (unavailableProducts.isNotEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Produits non disponibles'),
            content: Text(
              'Les produits suivants ne sont plus disponibles en quantité suffisante:\n\n'
              '${unavailableProducts.join('\n')}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Naviguer vers la page de commande
    if (mounted) {
      context.push('/customer/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon panier'),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () async {
                await _cartService.clearCart();
                await _loadCartItems();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Panier vidé'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: const Text('Vider'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits pour commencer vos achats',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/customer/products'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Voir les produits'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item);
            },
          ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['product'];
    if (product == null) return const SizedBox.shrink();

    final String title = product['title'] ?? 'Produit';
    final double price = NumberUtils.toDouble(product['price']);
    final int quantity = (item['quantity'] ?? 0).toInt();
    final String imageUrl = (product['images'] is List && (product['images'] as List).isNotEmpty)
        ? (product['images'] as List).first.toString()
        : '';
    final String merchantName = product['merchant']?['business_name'] ?? 'Vendeur';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image du produit
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
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
                            color: Colors.grey.shade400,
                            size: 30,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.shopping_bag,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
            ),
            const SizedBox(width: 12),
            
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
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    merchantName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${price.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.priceColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contrôles de quantité
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: quantity > 1
                          ? () => _updateQuantity(item['id'], quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(item['id'], quantity + 1),
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                IconButton(
                  onPressed: () => _removeItem(item['id']),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.priceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cartItems.isNotEmpty ? _proceedToCheckout : null,
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Passer la commande'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

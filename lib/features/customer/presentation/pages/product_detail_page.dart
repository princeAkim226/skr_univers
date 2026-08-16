import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../data/services/favorites_service.dart';
import '../widgets/contact_seller_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final FavoritesService _favoritesService = FavoritesService();
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  int _quantity = 1;
  bool _showSellerInfo = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadFavorite();
  }

  Future<void> _loadFavorite() async {
    final fav = await _favoritesService.isFavorite(widget.productId);
    if (!mounted) return;
    setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final nowFav = await _favoritesService.toggleFavorite(widget.productId);
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(nowFav ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        backgroundColor: nowFav ? Colors.green : Colors.grey.shade700,
      ),
    );
  }

  Future<void> _shareProduct() async {
    final product = _product;
    if (product == null) return;
    final title = product['title'] ?? 'Produit B-Place';
    final price = (product['price'] ?? 0).toDouble().toStringAsFixed(0);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Découvre "$title" à $price FCFA sur Business Place.',
        subject: title.toString(),
      ),
    );
  }

  Future<void> _loadProduct() async {
    try {
      final product = await _productService.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du produit')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produit non trouvé')),
        body: const Center(
          child: Text('Ce produit n\'existe pas'),
        ),
      );
    }

    final product = _product!;
    final String title = product['title'] ?? 'Produit';
    final String description = product['description'] ?? '';
    final double price = (product['price'] ?? 0).toDouble();
    final double? originalPrice = product['original_price']?.toDouble();
    final List<String> images = List<String>.from(product['images'] ?? []);
    final String merchantName = product['merchant']?['business_name'] ?? 'Vendeur';
    final String? merchantPhone = product['merchant']?['business_phone'];
    final String? merchantAddress = product['merchant']?['business_address'];
    final bool hasDiscount = originalPrice != null && originalPrice > price;
    final double discountPercentage = hasDiscount 
        ? ((originalPrice - price) / originalPrice * 100).roundToDouble()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du produit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareProduct,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images du produit
            if (images.isNotEmpty)
              SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.shopping_bag,
                            color: Colors.grey[400],
                            size: 60,
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            else
              Container(
                height: 300,
                color: Colors.grey[200],
                child: Icon(
                  Icons.shopping_bag,
                  color: Colors.grey[400],
                  size: 60,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-${discountPercentage.toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Prix
                  Row(
                    children: [
                      Text(
                        '${price.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.priceColor,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${originalPrice.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Informations du vendeur
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Vendu par $merchantName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (merchantPhone != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                merchantPhone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (merchantAddress != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  merchantAddress,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantité
                  Row(
                    children: [
                      const Text(
                        'Quantité:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Container(
                              width: 50,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _quantity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => _quantity++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            
            // Widget de contact vendeur (affiché conditionnellement)
            if (_showSellerInfo && _product != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: ContactSellerWidget(
                  merchant: _product!['merchant'] ?? {},
                  product: _product!,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Bouton d'ajout au panier
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _cartService.addToCart(widget.productId, _quantity);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Produit ajouté au panier'),
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
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: const Text('Ajouter au panier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton de contact vendeur
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showSellerInfo = !_showSellerInfo;
                      });
                    },
                    icon: Icon(_showSellerInfo ? Icons.visibility_off : Icons.contact_phone),
                    label: Text(_showSellerInfo ? 'Masquer' : 'Contacter le vendeur'),
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
          ),
        ),
      ),
    );
  }
}

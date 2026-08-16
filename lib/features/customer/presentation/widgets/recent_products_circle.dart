import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/services/product_service.dart';
import '../../../../core/theme/app_theme.dart';

class RecentProductsCircle extends StatefulWidget {
  const RecentProductsCircle({super.key});

  @override
  State<RecentProductsCircle> createState() => _RecentProductsCircleState();
}

class _RecentProductsCircleState extends State<RecentProductsCircle> {
  final ProductService _productService = ProductService();
  Map<String, List<Map<String, dynamic>>> _groupedProducts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentProducts();
  }

  Future<void> _loadRecentProducts() async {
    try {
      final products = await _productService.getRecentProducts(limit: 20);
      
      // Grouper les produits par e-commerçant
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final product in products) {
        final merchantId = product['merchant_id'] as String? ?? 'unknown';
        final merchantName = product['merchant']?['business_name'] as String? ?? 'E-commerçant';
        
        grouped.putIfAbsent(merchantId, () => <Map<String, dynamic>>[]).add({
          ...product,
          'merchant_name': merchantName,
        });
      }
      
      setState(() {
        _groupedProducts = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des produits récents: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_groupedProducts.isEmpty) {
      return const Center(child: Text('Aucun produit récent disponible'));
    }
    return SizedBox(
      height: 130, // Réduit de 140 à 130
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _groupedProducts.length,
        itemBuilder: (context, index) {
          final merchantId = _groupedProducts.keys.elementAt(index);
          final products = _groupedProducts[merchantId] ?? const <Map<String, dynamic>>[];
          return _buildMerchantCircle(merchantId, products);
        },
      ),
    );
  }

  Widget _buildMerchantCircle(String merchantId, List<Map<String, dynamic>> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    final String merchantName = products.first['merchant_name'] ?? 'E-commerçant';
    final String imageUrl = (products.first['images'] is List) &&
            (products.first['images'] as List).isNotEmpty
        ? (products.first['images'] as List).first.toString()
        : '';
    final int productCount = products.length;

    return GestureDetector(
      onTap: () {
        // Naviguer vers la page des produits de ce e-commerçant
        context.push('/customer/merchant/$merchantId');
      },
      child: Container(
        width: 85, // Réduit de 90 à 85
        margin: const EdgeInsets.only(right: 12), // Réduit de 16 à 12
        child: Column(
          children: [
            // Cercle avec gradient et ombre moderne
            Container(
              width: 65, // Réduit de 70 à 65
              height: 65, // Réduit de 70 à 65
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.mediumShadow,
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.store_outlined,
                              color: AppTheme.primaryColor,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.store_outlined,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Réduit de 12 à 8
            // Nom du e-commerçant avec style moderne
            Text(
              merchantName,
              textAlign: TextAlign.center,
              maxLines: 1, // Réduit de 2 à 1 pour éviter le débordement
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12, // Réduit de 13 à 12
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 2), // Réduit de 4 à 2
            // Nombre de produits avec style attrayant
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), // Réduit le padding
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
              ),
              child: Text(
                '$productCount produit${productCount > 1 ? 's' : ''}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9, // Réduit de 10 à 9
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/image_service.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final String productId = (product['id']?.toString() ?? '').trim();
      final String title = (product['title']?.toString() ?? 'Produit').trim();

      double price = 0.0;
      final priceValue = product['price'];
      if (priceValue is num) {
        price = priceValue.toDouble();
      } else if (priceValue is String) {
        price = double.tryParse(priceValue) ?? 0.0;
      }

      double? originalPrice;
      final originalPriceValue = product['original_price'];
      if (originalPriceValue is num) {
        originalPrice = originalPriceValue.toDouble();
      } else if (originalPriceValue is String) {
        originalPrice = double.tryParse(originalPriceValue);
      }

      final dynamic imagesData = product['images'];
      String imageUrl = '';
      if (imagesData is List && imagesData.isNotEmpty) {
        imageUrl = imagesData.first.toString().trim();
      }

      String merchantName = 'Vendeur';
      if (product['merchant'] is Map) {
        merchantName =
            ((product['merchant'] as Map)['business_name']?.toString() ??
                    'Vendeur')
                .trim();
      }

      final bool hasDiscount =
          originalPrice != null && originalPrice > price;
      final double discountPercentage = hasDiscount
          ? ((originalPrice - price) / originalPrice * 100).roundToDouble()
          : 0.0;

      return LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxHeight.isFinite &&
              constraints.maxHeight < double.infinity;

          final card = _ProductCardBody(
            title: title,
            merchantName: merchantName,
            price: price,
            originalPrice: originalPrice,
            hasDiscount: hasDiscount,
            discountPercentage: discountPercentage,
            imageUrl: imageUrl,
            isNew: product['created_at'] != null,
            compact: true,
          );

          return GestureDetector(
            onTap: onTap ??
                () {
                  if (productId.isEmpty) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    context.push('/customer/product/$productId');
                  });
                },
            child: Container(
              height: bounded ? null : 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.mediumShadow,
              ),
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: card,
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Erreur produit'),
      );
    }
  }
}

class _ProductCardBody extends StatelessWidget {
  final String title;
  final String merchantName;
  final double price;
  final double? originalPrice;
  final bool hasDiscount;
  final double discountPercentage;
  final String imageUrl;
  final bool isNew;
  final bool compact;

  const _ProductCardBody({
    required this.title,
    required this.merchantName,
    required this.price,
    required this.originalPrice,
    required this.hasDiscount,
    required this.discountPercentage,
    required this.imageUrl,
    required this.isNew,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.grey.shade100,
                child: imageUrl.isNotEmpty
                    ? ImageService.buildOptimizedImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: ImageService.buildLoadingPlaceholder(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        errorWidget: ImageService.buildErrorPlaceholder(
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '-${discountPercentage.toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.successGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Nouveau',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 42,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.15,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.store, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        merchantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${price.toStringAsFixed(0)} FCFA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.priceColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

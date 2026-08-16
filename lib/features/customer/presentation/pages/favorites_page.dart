import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/favorites_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/image_service.dart';
import '../../../../core/error_handling/error_handler.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _favoritesService = FavoritesService();
  final ProductService _productService = ProductService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() => _isLoading = true);
      final ids = await _favoritesService.getFavoriteIds();
      if (ids.isEmpty) {
        if (!mounted) return;
        setState(() {
          _products = [];
          _isLoading = false;
        });
        return;
      }

      final all = await _productService.getProducts();
      final favs = all.where((p) => ids.contains(p['id']?.toString())).toList();
      if (!mounted) return;
      setState(() {
        _products = favs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _remove(String productId) async {
    await _favoritesService.toggleFavorite(productId);
    await _loadFavorites();
  }

  String _imageOf(Map<String, dynamic> product) {
    final imagesData = product['images'];
    if (imagesData is List && imagesData.isNotEmpty) {
      return imagesData.first.toString();
    }
    return product['image_url']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: const StyledAppBar(title: 'Mes favoris'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun favori pour l’instant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Touche le cœur sur un produit pour l’enregistrer ici.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final id = product['id']?.toString() ?? '';
                      final title = product['title']?.toString() ?? 'Produit';
                      final price =
                          (product['price'] as num?)?.toDouble() ?? 0;
                      final image = _imageOf(product);

                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => context.push('/customer/product/$id'),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: image.isEmpty
                                        ? Container(
                                            color: const Color(0xFFE8F2E8),
                                            child: Icon(
                                              Icons.image_outlined,
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.5),
                                            ),
                                          )
                                        : ImageService.buildOptimizedImage(
                                            imageUrl: image,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${price.toStringAsFixed(0)} FCFA',
                                        style: const TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _remove(id),
                                  icon: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Retirer des favoris',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';

class MerchantProductsPage extends StatefulWidget {
  final String merchantId;

  const MerchantProductsPage({
    super.key,
    required this.merchantId,
  });

  @override
  State<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends State<MerchantProductsPage> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _merchant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMerchantProducts();
  }

  Future<void> _loadMerchantProducts() async {
    try {
      setState(() => _isLoading = true);
      final products =
          await _productService.getProductsByMerchant(widget.merchantId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _merchant = products.isNotEmpty ? products.first['merchant'] : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des produits: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _merchant?['business_name']?.toString() ?? 'Boutique';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: StyledAppBar(
        title: name,
        subtitle: _isLoading
            ? null
            : '${_products.length} produit${_products.length > 1 ? 's' : ''}',
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/customer/search'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VintageIconBadge(icon: Icons.store, size: 34),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun produit disponible',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: _loadMerchantProducts,
                  child: CustomScrollView(
                    slivers: [
                      if (_merchant != null)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1B5E20),
                                  Color(0xFF43A047),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                VintageIconBadge(
                                  icon: Icons.store,
                                  size: 22,
                                  color: AppTheme.primaryDarkColor,
                                  backgroundColor: Colors.white,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_products.length} produit${_products.length > 1 ? 's' : ''} en vitrine',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.88),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                ProductCard(product: _products[index]),
                            childCount: _products.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';
import '../../../../core/error_handling/error_handler.dart';

/// Version simplifiée de la page Habitations pour tester
class HabitationCategoryPageSimple extends StatefulWidget {
  const HabitationCategoryPageSimple({Key? key}) : super(key: key);

  @override
  State<HabitationCategoryPageSimple> createState() => _HabitationCategoryPageSimpleState();
}

class _HabitationCategoryPageSimpleState extends State<HabitationCategoryPageSimple> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final list = await _productService.getProductsByCategory('Habitations');
      if (mounted) {
        setState(() {
          _products = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Immobilier - Habitations'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _products.isEmpty
              ? const Center(
                  child: Text('Aucun produit trouvé'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ProductCard(product: product),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';

class LivresCategoryPage extends StatefulWidget {
  const LivresCategoryPage({super.key});

  @override
  State<LivresCategoryPage> createState() => _LivresCategoryPageState();
}

class _LivresCategoryPageState extends State<LivresCategoryPage> {
  final ProductService _productService = ProductService();

  bool _loading = true;
  List<Map<String, dynamic>> _allProducts = [];
  String _search = '';
  String _type = 'Tous';
  RangeValues _priceRange = const RangeValues(0, 10000000);

  final List<String> _types = const [
    'Tous',
    'Finance / investissement',
    'Entreprenariat',
    'Roman',
    'Romantique',
    'Légende',
    'Enfant',
    'Document scolaire',
  ];

  @override
  void initState() {
    super.initState();
    _loadLivres();
  }

  Future<void> _loadLivres() async {
    setState(() => _loading = true);
    try {
      final list = await _productService.getProductsByCategory('Livres');
      setState(() {
        _allProducts = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de charger les livres: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _applyFilters() {
    return _allProducts.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      final search = _search.toLowerCase();

      if (search.isNotEmpty && !title.contains(search) && !desc.contains(search)) {
        return false;
      }

      final price = NumberUtils.toDouble(p['price']);
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }

      if (_type != 'Tous') {
        final tags = (p['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        final joined = (title + ' ' + desc + ' ' + tags.join(' ')).toLowerCase();
        if (!joined.contains(_type.toLowerCase().split(' ').first)) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilters();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Livres'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Carte filtres (style Habitations)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.lightShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, size: 18, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      'Recherche & filtres',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadLivres,
                      icon: const Icon(Icons.refresh, size: 20),
                      color: AppTheme.textSecondaryColor,
                      tooltip: 'Rafraîchir',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher un livre...',
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type de livre',
                  ),
                  items: _types
                      .map((t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'Tous'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Prix',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 10000000,
                  divisions: 20,
                  labels: RangeLabels(
                    _priceRange.start.toInt().toString(),
                    _priceRange.end.toInt().toString(),
                  ),
                  onChanged: (values) => setState(() => _priceRange = values),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.menu_book_rounded,
                        title: 'Aucun livre pour le moment',
                        subtitle: 'Les livres apparaîtront ici. Essayez d’élargir vos filtres.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ProductCard(product: product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


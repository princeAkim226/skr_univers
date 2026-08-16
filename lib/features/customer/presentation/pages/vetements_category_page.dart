import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';
import '../../../../core/error_handling/error_handler.dart';

class VetementsCategoryPage extends StatefulWidget {
  const VetementsCategoryPage({super.key});

  @override
  State<VetementsCategoryPage> createState() => _VetementsCategoryPageState();
}

class _VetementsCategoryPageState extends State<VetementsCategoryPage> {
  final ProductService _productService = ProductService();

  bool _loading = true;
  List<Map<String, dynamic>> _allProducts = [];
  String _search = '';
  String _segment = 'Tous'; // Homme / Femme / Enfant / Tous
  RangeValues _priceRange = const RangeValues(0, 10000000);

  @override
  void initState() {
    super.initState();
    _loadVetements();
  }

  Future<void> _loadVetements() async {
    setState(() => _loading = true);
    try {
      final list = await _productService.getProductsByCategory('Vêtements');
      setState(() {
        _allProducts = list;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ErrorHandler.showError(context, e);
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

      if (_segment != 'Tous') {
        // On stocke le segment (Homme/Femme/Enfant) dans tags ou description
        final tags = (p['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
        final joined = (title + ' ' + desc + ' ' + tags.join(' ')).toLowerCase();
        if (!joined.contains(_segment.toLowerCase())) return false;
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
        title: const Text('Mode - Vêtements'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Segments (Homme/Femme/Enfant)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.lightShadow,
            ),
            child: Row(
              children: [
                Expanded(child: _buildSegment('Tous', _segment == 'Tous', Icons.grid_view)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Homme', _segment == 'Homme', Icons.man)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Femme', _segment == 'Femme', Icons.woman)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Enfant', _segment == 'Enfant', Icons.child_friendly)),
              ],
            ),
          ),

          // Carte filtres
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
                      onPressed: _loadVetements,
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
                    hintText: 'Rechercher un vêtement...',
                  ),
                  onChanged: (v) => setState(() => _search = v),
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
                        icon: Icons.checkroom_rounded,
                        title: 'Aucun vêtement pour le moment',
                        subtitle: 'Les annonces apparaîtront ici. Essayez d’élargir vos filtres.',
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

  Widget _buildSegment(String label, bool selected, IconData icon) {
    return Material(
      color: selected ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _segment = label),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.textSecondaryColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
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


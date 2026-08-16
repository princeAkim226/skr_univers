import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';
import '../../../../core/error_handling/error_handler.dart';

class MotorCategoryPage extends StatefulWidget {
  const MotorCategoryPage({super.key});

  @override
  State<MotorCategoryPage> createState() => _MotorCategoryPageState();
}

class _MotorCategoryPageState extends State<MotorCategoryPage> {
  final ProductService _productService = ProductService();

  bool _loading = true;
  List<Map<String, dynamic>> _allProducts = [];
  String _type = 'Tous';
  String _condition = 'Toutes';
  RangeValues _priceRange = const RangeValues(0, 100000000);

  final List<String> _types = const [
    'Tous',
    'Voiture',
    'Motocyclette',
    'Engins lourds',
    'Accessoires',
  ];

  @override
  void initState() {
    super.initState();
    _loadMotor();
  }

  Future<void> _loadMotor() async {
    setState(() => _loading = true);
    try {
      final list = await _productService.getProductsByCategory('Moteurs');
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
      final price = NumberUtils.toDouble(p['price']);
      if (price < _priceRange.start || price > _priceRange.end) {
        return false;
      }

      final title = (p['title'] ?? '').toString().toLowerCase();
      final desc = (p['description'] ?? '').toString().toLowerCase();
      final tags = (p['tags'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final joined = (title + ' ' + desc + ' ' + tags.join(' ')).toLowerCase();

      if (_type != 'Tous' && !joined.contains(_type.toLowerCase().split(' ').first)) {
        return false;
      }

      if (_condition != 'Toutes' && !joined.contains(_condition.toLowerCase())) {
        return false;
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
        title: const Text('Motor - Véhicules'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Segments (état)
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
                Expanded(child: _buildSegment('Toutes', _condition == 'Toutes', Icons.all_inclusive)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Neuf', _condition == 'Neuf', Icons.fiber_new)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Occasion', _condition == 'Occasion', Icons.history)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Location', _condition == 'Location', Icons.key)),
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
                      'Filtres',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadMotor,
                      icon: const Icon(Icons.refresh, size: 20),
                      color: AppTheme.textSecondaryColor,
                      tooltip: 'Rafraîchir',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                        ),
                        items: _types
                            .map((t) => DropdownMenuItem<String>(
                                  value: t,
                                  child: Text(t),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v ?? 'Tous'),
                      ),
                    ),
                  ],
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
                  max: 100000000,
                  divisions: 20,
                  labels: RangeLabels(
                    _priceRange.start.toInt().toString(),
                    _priceRange.end.toInt().toString(),
                  ),
                  onChanged: (values) {
                    setState(() => _priceRange = values);
                  },
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
                        icon: Icons.directions_car,
                        title: 'Aucun véhicule pour le moment',
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
        onTap: () => setState(() => _condition = label),
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


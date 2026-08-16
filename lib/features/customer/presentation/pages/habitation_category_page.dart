import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/product_service.dart';
import '../widgets/product_card.dart';

class HabitationCategoryPage extends StatefulWidget {
  const HabitationCategoryPage({Key? key}) : super(key: key);

  @override
  State<HabitationCategoryPage> createState() => _HabitationCategoryPageState();
}

class _HabitationCategoryPageState extends State<HabitationCategoryPage> {
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _allProducts = [];
  bool _loading = true;

  String objectif = 'Vente';
  String selectedType = 'Tout';
  String selectedVille = 'Tout';
  String selectedZone = 'Tout';
  String selectedQuartier = 'Tout';
  RangeValues priceRange = const RangeValues(0, 10000000); // Commencer à 0 pour inclure tous les prix
  int? selectedChambres;
  bool onlyCertifies = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHabitations();
    });
  }

  Future<void> _loadHabitations() async {
    if (!mounted) return;
    // Mettre à jour l'état d'abord après la frame pour éviter les conflits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _loading = true);
    });
    
    try {
      print('🏠 ========== CHARGEMENT DES HABITATIONS ==========');
      print('🏠 Catégorie recherchée: Habitations');
      
      final list = await _productService.getProductsByCategory('Habitations');
      
  if (!mounted) return;
      
  print('📊 ========== RÉSULTATS ==========');
  print('📊 Nombre de produits récupérés depuis Supabase: ${list.length}');
      
      if (list.isEmpty) {
        print('ℹ️ Aucun produit trouvé pour la catégorie Habitations');
      } else {
        print('✅ ${list.length} produits récupérés avec succès!');
        for (var i = 0; i < list.length && i < 3; i++) {
          final p = list[i];
          print('📦 Produit ${i + 1}:');
          print('   - Titre: ${p['title']}');
          print('   - Property goal: ${p['property_goal']}');
          print('   - Property type: ${p['property_type']}');
          print('   - Marchand: ${p['merchant']?['business_name'] ?? 'Inconnu'}');
        }
      }
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _allProducts = list;
          _loading = false;
        });
      });
      
      print('📊 Nombre de produits chargés: ${_allProducts.length}');
    } catch (error, stackTrace) {
      print('❌ ========== ERREUR ==========');
      print('❌ Erreur lors du chargement des habitations: $error');
      print('❌ Type d\'erreur: ${error.runtimeType}');
      print('📚 Stack trace: $stackTrace');
      
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _loading = false);

        // Afficher un message d'erreur plus convivial
        final errorMessage = error.toString().contains('permission')
            ? 'Erreur d\'autorisation. Vérifiez vos droits d\'accès.'
            : 'Impossible de charger les habitations. Vérifiez votre connexion.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadHabitations,
            ),
          ),
        );
      });
    }
  }

  List<Map<String, dynamic>> _applyFilters() {
    if (_allProducts.isEmpty) {
      return [];
    }
    
    print('🔍 Application des filtres: objectif=$objectif, type=$selectedType, ville=$selectedVille, zone=$selectedZone, quartier=$selectedQuartier');
    
    final filtered = _allProducts.where((p) {
      // Filtrer par objectif (Vente/Location)
      final goal = (p['property_goal'] as String?)?.trim().toLowerCase();
      final targetGoal = objectif.toLowerCase();
      
      // Si le produit a un goal défini et qu'il ne correspond pas, on le filtre
      if (goal != null && goal.isNotEmpty && goal != targetGoal) {
        return false;
      }

      if (onlyCertifies) {
        final verified = p['merchant']?['is_verified'] as bool?;
        if (verified != true) return false;
      }

      final price = NumberUtils.toDouble(p['price']);
      if (price < priceRange.start || price > priceRange.end) {
        return false;
      }

      if (selectedType != 'Tout') {
        final type = (p['property_type'] as String?) ?? '';
        if (type != selectedType) return false;
      }
      if (selectedVille != 'Tout') {
        final v = (p['property_city'] as String?) ?? '';
        if (v != selectedVille) return false;
      }
      if (selectedZone != 'Tout') {
        final z = (p['property_zone'] as String?) ?? '';
        if (z != selectedZone) return false;
      }
      if (selectedQuartier != 'Tout') {
        final q = (p['property_quarter'] as String?) ?? '';
        if (q != selectedQuartier) return false;
      }
      if (selectedChambres != null) {
        final r = p['property_rooms'] as int?;
        if (selectedChambres! >= 5) {
          if (r == null || r < 5) return false;
        } else if (r != selectedChambres) return false;
      }
      return true;
    }).toList();
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Calculer les produits filtrés une seule fois
    final filtered = _applyFilters();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Immobilier - Habitations'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Segment Location / Vente
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
                Expanded(child: _buildSegment('Location', objectif == 'Location', Icons.key)),
                const SizedBox(width: 4),
                Expanded(child: _buildSegment('Vente', objectif == 'Vente', Icons.sell)),
              ],
            ),
          ),
          // Filtres en carte avec labels
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
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Type', selectedType, ['Tout','Maison','Résidence','Magasin','Terrain'], (v) => setState(() => selectedType = v!)),
                        _buildFilterChip('Ville', selectedVille, ['Tout','Ville A','Ville B'], (v) => setState(() => selectedVille = v!)),
                        _buildFilterChip('Zone', selectedZone, ['Tout','Zone 1','Zone 2'], (v) => setState(() => selectedZone = v!)),
                        _buildFilterChip('Quartier', selectedQuartier, ['Tout','Q1','Q2'], (v) => setState(() => selectedQuartier = v!)),
                        _buildFilterChip('Chambres', selectedChambres?.toString() ?? 'Tout', ['Tout','1','2','3','4','5+'], (v) => setState(() => selectedChambres = v == 'Tout' ? null : int.parse(v!))),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: onlyCertifies ? AppTheme.primaryColor.withOpacity(0.15) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () {
                                if (mounted) {
                                  setState(() => onlyCertifies = !onlyCertifies);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(onlyCertifies ? Icons.verified : Icons.verified_outlined, size: 18, color: onlyCertifies ? AppTheme.primaryColor : Colors.grey),
                                    const SizedBox(width: 6),
                                    Text('Certifié', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onlyCertifies ? AppTheme.primaryColor : AppTheme.textSecondaryColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: HabitationFilteredList(
              products: filtered,
              loading: _loading,
              goal: objectif,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.filter_list, color: Colors.white),
        onPressed: () {
          // Modal filtres avancés
        },
      ),
    );
  }

  Widget _buildSegment(String label, bool selected, IconData icon) {
    return Material(
      color: selected ? AppTheme.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (mounted) {
            setState(() => objectif = label);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor, size: 20),
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (value) {
                  if (mounted) {
                    onChanged(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche la liste des biens Habitations (chargés et filtrés par la page).
class HabitationFilteredList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool loading;
  final String goal;

  const HabitationFilteredList({
    required this.products,
    required this.loading,
    required this.goal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }
    
    if (products.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [_EmptyStateCard(goal: goal)],
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        if (product['id'] == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ProductCard(product: product),
        );
      },
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String goal;

  const _EmptyStateCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home_work_rounded,
              size: 56,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun bien pour le moment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goal == 'Location'
                ? 'Les annonces de location apparaîtront ici. Essayez d’élargir vos filtres.'
                : 'Les annonces de vente apparaîtront ici. Essayez d’élargir vos filtres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

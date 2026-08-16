import 'package:flutter/material.dart';
import '../../../../data/services/product_service.dart';
import 'product_card.dart';

class HabitationsList extends StatefulWidget {
  final String mode;
  final String type;
  final String zone;
  final bool certifiedFirst;
  final RangeValues priceRange;
  final int? bedrooms;

  const HabitationsList({
    Key? key,
    required this.mode,
    required this.type,
    required this.zone,
    required this.certifiedFirst,
    required this.priceRange,
    this.bedrooms,
  }) : super(key: key);

  @override
  State<HabitationsList> createState() => _HabitationsListState();
}

class _HabitationsListState extends State<HabitationsList> {
  final ProductService _productService = ProductService();
  late Future<List<Map<String, dynamic>>> _futureProducts;

  @override
  void initState() {
    super.initState();
    // Initialiser la recherche après la frame courante pour éviter les mises à jour
    // d'état pendant l'update des devices (problème rencontré en debug web).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _futureProducts = _fetchProducts();
      });
    });
  }

  @override
  void didUpdateWidget(covariant HabitationsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        widget.type != oldWidget.type ||
        widget.zone != oldWidget.zone ||
        widget.certifiedFirst != oldWidget.certifiedFirst ||
        widget.priceRange != oldWidget.priceRange ||
        widget.bedrooms != oldWidget.bedrooms) {
      // Retarder la mise à jour de l'état pour éviter l'assertion liée au
      // mouse tracker lors d'une mise à jour de devices en debug.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _futureProducts = _fetchProducts();
        });
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    // Pour "Habitations": mode = Vente/Location & type propriété = maison, etc.
    // catégorie : "Habitations"
    try {
      final results = await _productService.searchProducts(
        query: '',
        category: 'Habitations', // convention : tout bien immobilier
        minPrice: widget.priceRange.start,
        maxPrice: widget.priceRange.end,
        sortBy: 'is_featured',
        ascending: !widget.certifiedFirst,
      );
      // Affiner côté client : type, zone, chambres
      return results.where((p) {
        if (widget.mode.isNotEmpty &&
            (p['tags'] == null || !(p['tags'] as List).contains(widget.mode))) {
          return false;
        }
        if (widget.type != 'Tous' && (p['tags'] == null || !(p['tags'] as List).contains(widget.type))) {
          return false;
        }
        if (widget.bedrooms != null &&
            (p['bedrooms'] == null || p['bedrooms'] != widget.bedrooms)) {
          return false;
        }
        if (widget.zone != 'Ma zone' && (p['address'] == null || !(p['address'] as String).contains(widget.zone))) {
          return false;
        }
        return true;
      }).toList();
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Center(child: Text('Aucune propriété trouvée avec vos critères.'));
        }
        return ListView.separated(
          itemCount: products.length,
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) => ProductCard(product: products[index]),
        );
      },
    );
  }
}

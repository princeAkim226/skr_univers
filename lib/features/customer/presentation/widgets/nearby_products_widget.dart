import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/location_service.dart';
import '../../../../core/error_handling/error_handler.dart';

class NearbyProductsWidget extends StatefulWidget {
  const NearbyProductsWidget({super.key});

  @override
  State<NearbyProductsWidget> createState() => _NearbyProductsWidgetState();
}

class _NearbyProductsWidgetState extends State<NearbyProductsWidget> {
  final ProductService _productService = ProductService();
  final LocationService _locationService = LocationService();
  
  List<Map<String, dynamic>> _nearbyProducts = [];
  bool _isLoading = true;
  String? _currentAddress;
  double _maxDistance = 50.0; // km

  @override
  void initState() {
    super.initState();
    _loadNearbyProducts();
  }

  Future<void> _loadNearbyProducts() async {
    try {
      setState(() => _isLoading = true);
      
      // Obtenir la position actuelle
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Obtenir l'adresse
      _currentAddress = _locationService.currentAddress ?? 'Position actuelle';

      // Récupérer tous les produits avec géolocalisation
      final allProducts = await _productService.getNearbyProducts(
        maxDistanceKm: _maxDistance,
      );

      // Filtrer par distance
      final nearbyProducts = await _locationService.getNearbyProducts(
        allProducts,
        maxDistanceKm: _maxDistance,
      );

      setState(() {
        _nearbyProducts = nearbyProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec position et distance
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Produits près de chez vous',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (_currentAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _currentAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Dans un rayon de ${_maxDistance.toInt()} km',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton de rafraîchissement
              IconButton(
                onPressed: _loadNearbyProducts,
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Actualiser la position',
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Liste des produits
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_nearbyProducts.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun produit trouvé près de chez vous',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Essayez d\'élargir le rayon de recherche ou vérifiez votre géolocalisation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadNearbyProducts,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _nearbyProducts.length,
            itemBuilder: (context, index) {
              final product = _nearbyProducts[index];
              final distance = product['distance'] as double?;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Image du produit
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: (product['images'] is List) &&
                                (product['images'] as List).isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  (product['images'] as List).first.toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey.shade400,
                                      size: 30,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.shopping_bag,
                                color: Colors.grey.shade400,
                                size: 30,
                              ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Informations du produit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['title'] ?? 'Produit sans nom',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${NumberUtils.toDouble(product['price']).toStringAsFixed(0)} FCFA',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    product['merchant']?['business_name'] ?? 'Commerce',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (distance != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _locationService.formatDistance(distance),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.successColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
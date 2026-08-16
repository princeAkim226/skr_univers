import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/ad_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdsManagementPage extends StatefulWidget {
  const AdsManagementPage({super.key});

  @override
  State<AdsManagementPage> createState() => _AdsManagementPageState();
}

class _AdsManagementPageState extends State<AdsManagementPage> {
  final AdService _adService = AdService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;
  String? _merchantId;

  @override
  void initState() {
    super.initState();
    _loadMerchantId();
  }

  Future<void> _loadMerchantId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final merchantResponse = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id)
          .single();

      setState(() {
        _merchantId = merchantResponse['id'] as String;
      });

      await _loadAds();
    } catch (e) {
      print('Erreur lors du chargement de l\'ID du marchand: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAds() async {
    if (_merchantId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final ads = await _adService.getMerchantAds(_merchantId!);

      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des publicités: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAd(String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la publicité'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette publicité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _adService.deleteAd(adId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publicité supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAds();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleAdStatus(String adId, bool currentStatus) async {
    final success = await _adService.toggleAdStatus(adId, !currentStatus);
    if (mounted) {
      if (success) {
        _loadAds();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du changement de statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StyledAppBar(
        title: 'Publicités',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(VintageIcons.merchantAction('pubs')),
            onPressed: () => context.push('/merchant/add-ad'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ads.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAds,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ads.length,
                    itemBuilder: (context, index) {
                      return _buildAdCard(_ads[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune publicité',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première publicité pour promouvoir vos produits',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/merchant/add-ad'),
            icon: const Icon(Icons.add),
            label: const Text('Créer une publicité'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isActive = ad['is_active'] ?? false;
    final imageUrl = ad['image_url'];
    final title = ad['title'] ?? 'Sans titre';
    final description = ad['description'] ?? '';
    final viewCount = ad['view_count'] ?? 0;
    final clickCount = ad['click_count'] ?? 0;
    final startDate = ad['start_date'];
    final endDate = ad['end_date'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isActive ? 'Actif' : 'Inactif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Statistiques
                Row(
                  children: [
                    _buildStatItem(Icons.visibility, '$viewCount vues'),
                    const SizedBox(width: 16),
                    _buildStatItem(Icons.touch_app, '$clickCount clics'),
                  ],
                ),
                
                if (startDate != null || endDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateRange(startDate, endDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 12),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _toggleAdStatus(ad['id'], isActive),
                      icon: Icon(isActive ? Icons.pause : Icons.play_arrow, size: 16),
                      label: Text(isActive ? 'Désactiver' : 'Activer'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteAd(ad['id']),
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDateRange(String? startDate, String? endDate) {
    if (startDate == null && endDate == null) return '';
    
    try {
      final start = startDate != null ? DateTime.parse(startDate) : null;
      final end = endDate != null ? DateTime.parse(endDate) : null;
      
      if (start != null && end != null) {
        return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
      } else if (start != null) {
        return 'À partir du ${start.day}/${start.month}/${start.year}';
      } else if (end != null) {
        return 'Jusqu\'au ${end.day}/${end.month}/${end.year}';
      }
    } catch (e) {
      return '';
    }
    
    return '';
  }
}


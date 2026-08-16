import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/ad_service.dart';
import '../../../../data/services/platform_ad_service.dart';

class AdSectionWidget extends StatefulWidget {
  const AdSectionWidget({super.key});

  @override
  State<AdSectionWidget> createState() => _AdSectionWidgetState();
}

class _AdSectionWidgetState extends State<AdSectionWidget> {
  final PlatformAdService _platformAdService = PlatformAdService();
  final AdService _adService = AdService();
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final results = await Future.wait([
        _platformAdService.getActiveAds(),
        _adService.getDefaultAds(),
      ]);

      final platformAds = results[0].map((ad) {
        return {
          'id': ad['id'],
          'title': ad['title'] ?? 'Business Place',
          'description': ad['description'] ?? '',
          'image': ad['image_url'] ?? '',
          'merchantName': 'B-Place',
          'promo': 'B-Place',
          'source': 'platform',
          'targetUrl': ad['target_url'],
        };
      });

      final merchantAds = results[1].map((ad) {
        final merchant = ad['merchant'];
        String merchantName = 'Boutique';
        if (merchant is Map) {
          merchantName = merchant['business_name']?.toString() ?? merchantName;
        }
        return {
          'id': ad['id'],
          'title': ad['title'] ?? 'Offre boutique',
          'description': ad['description'] ?? '',
          'image': ad['image_url'] ?? '',
          'merchantName': merchantName,
          'promo': 'Boutique',
          'source': 'merchant',
          'targetUrl': ad['target_url'],
        };
      });

      if (!mounted) return;
      setState(() {
        _ads = [...platformAds, ...merchantAds];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ads = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Publicités',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              return _buildAdCard(_ads[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isPlatform = ad['source'] == 'platform';
    return GestureDetector(
      onTap: () {
        context.push('/customer/products');
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.lightShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: (ad['image']?.toString().isNotEmpty ?? false)
                    ? Image.network(
                        ad['image'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryColor,
                            child: const Icon(
                              Icons.campaign_outlined,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: AppTheme.primaryColor,
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPlatform
                        ? AppTheme.primaryDarkColor
                        : AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ad['promo']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['merchantName']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad['title']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ad['description']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

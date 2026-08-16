import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/admin_service.dart';

class AdminMerchantAdsPage extends StatefulWidget {
  const AdminMerchantAdsPage({super.key});

  @override
  State<AdminMerchantAdsPage> createState() => _AdminMerchantAdsPageState();
}

class _AdminMerchantAdsPageState extends State<AdminMerchantAdsPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _ads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ads = await _adminService.getMerchantAds();
      if (!mounted) return;
      setState(() => _ads = ads);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_ads.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Aucune publicité boutique pour le moment.\nElles sont créées par les e-commerçants.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _ads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final ad = _ads[index];
          final active = ad['is_active'] == true;
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              title: Text(
                ad['title']?.toString() ?? 'Publicité',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                [
                  ad['is_default'] == true ? 'Accueil client' : 'Pub boutique',
                  active ? 'Visible' : 'Masquée',
                ].join(' · '),
              ),
              trailing: Switch(
                value: active,
                onChanged: (v) async {
                  try {
                    await _adminService.setMerchantAdActive(ad['id'].toString(), v);
                    _load();
                  } catch (e) {
                    if (!context.mounted) return;
                    ErrorHandler.showError(context, e);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

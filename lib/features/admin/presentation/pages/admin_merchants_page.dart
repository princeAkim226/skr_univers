import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/admin_service.dart';

class AdminMerchantsPage extends StatefulWidget {
  const AdminMerchantsPage({super.key});

  @override
  State<AdminMerchantsPage> createState() => _AdminMerchantsPageState();
}

class _AdminMerchantsPageState extends State<AdminMerchantsPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _merchants = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final merchants = await _adminService.getMerchants();
      if (!mounted) return;
      setState(() => _merchants = merchants);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _merchants;
    return _merchants.where((m) {
      return [
        m['business_name'],
        m['business_phone'],
        m['business_city'],
      ].join(' ').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher une boutique',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final merchant = _filtered[index];
                      final verified = merchant['is_verified'] == true;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          title: Text(
                            merchant['business_name']?.toString() ?? 'Boutique',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              merchant['business_city'] ?? '',
                              merchant['business_phone'] ?? '',
                              verified ? 'Vérifiée' : 'Non vérifiée',
                            ].where((e) => e.toString().isNotEmpty).join(' · '),
                          ),
                          trailing: Switch(
                            value: verified,
                            onChanged: (v) async {
                              try {
                                await _adminService.setMerchantVerified(
                                  merchant['id'].toString(),
                                  v,
                                );
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
                ),
        ),
      ],
    );
  }
}

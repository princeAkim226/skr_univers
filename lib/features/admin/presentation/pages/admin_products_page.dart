import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/admin_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _products = [];
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
      final products = await _adminService.getProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return [
        p['title'],
        p['category'],
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
              hintText: 'Rechercher un produit',
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
                      final product = _filtered[index];
                      final active = product['is_active'] != false;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          title: Text(
                            product['title']?.toString() ?? 'Produit',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              product['category'] ?? '',
                              '${product['price'] ?? 0} FCFA',
                              active ? 'Visible' : 'Masqué',
                            ].where((e) => e.toString().isNotEmpty).join(' · '),
                          ),
                          trailing: Switch(
                            value: active,
                            onChanged: (v) async {
                              try {
                                await _adminService.setProductActive(
                                  product['id'].toString(),
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

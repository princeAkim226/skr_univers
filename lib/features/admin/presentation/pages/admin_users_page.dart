import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/admin_service.dart';
import '../widgets/admin_shell.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
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
      final users = await _adminService.getUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    try {
      await _adminService.setUserActive(
        user['id'].toString(),
        user['is_active'] != true,
      );
      _load();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) {
      final blob = [
        u['first_name'],
        u['last_name'],
        u['phone_number'],
        u['email'],
        u['business_name'],
        u['user_type'],
      ].join(' ').toLowerCase();
      return blob.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Utilisateurs',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un nom, téléphone ou boutique',
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
                        final user = _filtered[index];
                        final name = [
                          user['first_name'],
                          user['last_name'],
                        ].where((e) => (e?.toString() ?? '').trim().isNotEmpty).join(' ');
                        final type = user['user_type']?.toString() == 'merchant'
                            ? 'E-commerçant'
                            : 'Client';
                        final active = user['is_active'] != false;
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            title: Text(
                              name.isEmpty ? 'Utilisateur' : name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              [
                                type,
                                if (user['is_admin'] == true) 'Admin',
                                user['phone_number'] ?? user['email'] ?? '',
                              ].where((e) => e.toString().isNotEmpty).join(' · '),
                            ),
                            trailing: Switch(
                              value: active,
                              onChanged: (_) => _toggleActive(user),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/admin_service.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final AdminService _adminService = AdminService();
  AdminDashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Tableau de bord',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  const Text(
                    'Business Place',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryDarkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pilotage de la plateforme',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatChip(
                        label: 'Utilisateurs',
                        value: '${_stats?.users ?? 0}',
                      ),
                      _StatChip(
                        label: 'Clients',
                        value: '${_stats?.customers ?? 0}',
                      ),
                      _StatChip(
                        label: 'Boutiques',
                        value: '${_stats?.merchants ?? 0}',
                      ),
                      _StatChip(
                        label: 'Produits',
                        value: '${_stats?.products ?? 0}',
                      ),
                      _StatChip(
                        label: 'Pubs B-Place',
                        value: '${_stats?.platformAds ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AdminNavCard(
                    icon: Icons.campaign_outlined,
                    title: 'Publicités B-Place',
                    subtitle: 'Pubs propriétaires, distinctes des boutiques',
                    onTap: () => context.go('/ads'),
                  ),
                  const SizedBox(height: 12),
                  AdminNavCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Utilisateurs',
                    subtitle: 'Clients, e-commerçants et accès',
                    onTap: () => context.go('/users'),
                  ),
                  const SizedBox(height: 12),
                  AdminNavCard(
                    icon: Icons.local_offer_outlined,
                    title: 'Codes promo',
                    subtitle: 'Créer et suivre les promotions',
                    onTap: () => context.go('/promo-codes'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDarkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

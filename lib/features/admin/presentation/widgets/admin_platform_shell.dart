import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/auth_service.dart';

class _AdminDest {
  final String path;
  final IconData icon;
  final String label;

  const _AdminDest(this.path, this.icon, this.label);
}

const _destinations = [
  _AdminDest('/', Icons.dashboard_outlined, 'Tableau de bord'),
  _AdminDest('/users', Icons.people_outline, 'Utilisateurs'),
  _AdminDest('/merchants', Icons.storefront_outlined, 'Boutiques'),
  _AdminDest('/products', Icons.inventory_2_outlined, 'Produits'),
  _AdminDest('/ads', Icons.campaign_outlined, 'Pubs B-Place'),
  _AdminDest('/merchant-ads', Icons.ads_click_outlined, 'Pubs boutiques'),
  _AdminDest('/promo-codes', Icons.local_offer_outlined, 'Codes promo'),
];

class AdminPlatformShell extends StatelessWidget {
  final Widget child;

  const AdminPlatformShell({super.key, required this.child});

  String _titleFor(String location) {
    if (location.startsWith('/merchant-ads')) return 'Pubs boutiques';
    if (location.startsWith('/ads')) return 'Pubs B-Place';
    if (location.startsWith('/users')) return 'Utilisateurs';
    if (location.startsWith('/merchants')) return 'Boutiques';
    if (location.startsWith('/products')) return 'Produits';
    if (location.startsWith('/promo-codes')) return 'Codes promo';
    return 'Tableau de bord';
  }

  int _indexFor(String location) {
    if (location.startsWith('/merchant-ads')) return 5;
    if (location.startsWith('/ads')) return 4;
    if (location.startsWith('/users')) return 1;
    if (location.startsWith('/merchants')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/promo-codes')) return 6;
    return 0;
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFor(location);
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final sidebar = _AdminSidebar(
      selectedIndex: selected,
      onSelect: (i) => context.go(_destinations[i].path),
      onLogout: () => _logout(context),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      drawer: wide ? null : Drawer(child: sidebar),
      body: Row(
        children: [
          if (wide) sidebar,
          Expanded(
            child: Builder(
              builder: (context) => Column(
                children: [
                  _AdminTopBar(
                    title: _titleFor(location),
                    showMenu: !wide,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final String title;
  final bool showMenu;

  const _AdminTopBar({required this.title, required this.showMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6EDE6))),
      ),
      child: Row(
        children: [
          if (showMenu)
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            'Admin',
            style: TextStyle(
              color: AppTheme.primaryDarkColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF12351A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'B-Place',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Plateforme administration',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _destinations.length,
                itemBuilder: (context, index) {
                  final dest = _destinations[index];
                  final selected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        dest.icon,
                        color: selected ? Colors.white : Colors.white70,
                      ),
                      title: Text(
                        dest.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        onSelect(index);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.white70),
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: onLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

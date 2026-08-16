import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/vintage_icons.dart';

class RaagaNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const RaagaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barre de navigation flottante RAAGA (style pill).
class RaagaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<RaagaNavItem> items;

  const RaagaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  static final List<RaagaNavItem> customerItems = [
    RaagaNavItem(
      icon: VintageIcons.customerNav('Accueil'),
      activeIcon: VintageIcons.customerNav('Accueil', active: true),
      label: 'Accueil',
    ),
    RaagaNavItem(
      icon: VintageIcons.customerNav('Produits'),
      activeIcon: VintageIcons.customerNav('Produits', active: true),
      label: 'Produits',
    ),
    RaagaNavItem(
      icon: VintageIcons.customerNav('Panier'),
      activeIcon: VintageIcons.customerNav('Panier', active: true),
      label: 'Panier',
    ),
    RaagaNavItem(
      icon: VintageIcons.customerNav('Chat'),
      activeIcon: VintageIcons.customerNav('Chat', active: true),
      label: 'Chat',
    ),
    RaagaNavItem(
      icon: VintageIcons.customerNav('Profil'),
      activeIcon: VintageIcons.customerNav('Profil', active: true),
      label: 'Profil',
    ),
  ];

  /// Nav visible e-commerçant (6 onglets)
  static final List<RaagaNavItem> merchantItems = [
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Accueil'),
      activeIcon: VintageIcons.merchantNav('Accueil', active: true),
      label: 'Accueil',
    ),
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Produits'),
      activeIcon: VintageIcons.merchantNav('Produits', active: true),
      label: 'Produits',
    ),
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Chat'),
      activeIcon: VintageIcons.merchantNav('Chat', active: true),
      label: 'Chat',
    ),
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Pubs'),
      activeIcon: VintageIcons.merchantNav('Pubs', active: true),
      label: 'Pubs',
    ),
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Plans'),
      activeIcon: VintageIcons.merchantNav('Plans', active: true),
      label: 'Plans',
    ),
    RaagaNavItem(
      icon: VintageIcons.merchantNav('Profil'),
      activeIcon: VintageIcons.merchantNav('Profil', active: true),
      label: 'Profil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + (bottom > 0 ? bottom * 0.35 : 0)),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE6EEE6)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = index == currentIndex;
            return Expanded(
              child: _NavTile(
                item: item,
                selected: selected,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final RaagaNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        highlightColor: AppTheme.primaryColor.withValues(alpha: 0.06),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: selected
                  ? Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.22),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 22,
                  color: selected
                      ? AppTheme.primaryDarkColor
                      : const Color(0xFF8A958E),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected
                        ? AppTheme.primaryDarkColor
                        : const Color(0xFF8A958E),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

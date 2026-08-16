import 'package:flutter/material.dart';
import 'raaga_bottom_nav.dart';

/// Navigation adaptée : barre du bas sur mobile, rail à gauche sur le web / grand écran.
class AppNavShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<RaagaNavItem> items;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const AppNavShell({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.body,
    this.appBar,
    this.backgroundColor,
  });

  static const double desktopBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= desktopBreakpoint;
    final bg = backgroundColor ?? const Color(0xFFF4F7F4);
    final safeIndex = currentIndex.clamp(0, items.length - 1);

    if (!wide) {
      return Scaffold(
        backgroundColor: bg,
        appBar: appBar,
        body: body,
        bottomNavigationBar: RaagaBottomNav(
          currentIndex: safeIndex,
          onTap: onTap,
          items: items,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: safeIndex,
            onDestinationSelected: onTap,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF2E7D32).withValues(alpha: 0.12),
            selectedIconTheme: const IconThemeData(color: Color(0xFF1B5E20)),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w700,
            ),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

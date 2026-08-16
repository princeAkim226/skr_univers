import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'custom_nav_icons.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex; // index in the visible nav (0..5)
  final ValueChanged<int> onTap;
  final Color? selectedColor;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    this.selectedColor,
  }) : super(key: key);

  // Couleurs spécifiques pour chaque icône
  static Color _getItemColor(int index) {
    switch (index) {
      case 0: return AppTheme.primaryColor; // Accueil - Vert
      case 1: return Colors.blue; // Produits - Bleu
      case 2: return Colors.purple; // Conversations - Violet
      case 3: return Colors.red; // Publicités - Rouge
      case 4: return AppTheme.primaryColor; // Abonnements - Vert
      case 5: return Colors.indigo; // Profil - Indigo
      default: return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _getItemColor(selectedIndex),
      unselectedItemColor: const Color(0xFF9E9E9E),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _getItemColor(selectedIndex),
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.normal,
        color: Color(0xFF9E9E9E),
      ),
      elevation: 0,
      items: [
        BottomNavigationBarItem(
          icon: HomeNavIcon(isActive: selectedIndex == 0, size: 26),
          activeIcon: HomeNavIcon(isActive: true, size: 26),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: ProductsNavIcon(isActive: selectedIndex == 1, size: 26),
          activeIcon: ProductsNavIcon(isActive: true, size: 26),
          label: 'Produits',
        ),
        BottomNavigationBarItem(
          icon: ChatNavIcon(isActive: selectedIndex == 2, size: 26),
          activeIcon: ChatNavIcon(isActive: true, size: 26),
          label: 'Conversations',
        ),
        BottomNavigationBarItem(
          icon: AdsNavIcon(isActive: selectedIndex == 3, size: 26),
          activeIcon: AdsNavIcon(isActive: true, size: 26),
          label: 'Publicités',
        ),
        BottomNavigationBarItem(
          icon: SubscriptionsNavIcon(isActive: selectedIndex == 4, size: 26),
          activeIcon: SubscriptionsNavIcon(isActive: true, size: 26),
          label: 'Abonnements',
        ),
        BottomNavigationBarItem(
          icon: ProfileNavIcon(isActive: selectedIndex == 5, size: 26),
          activeIcon: ProfileNavIcon(isActive: true, size: 26),
          label: 'Profil',
        ),
      ],
    );
  }
}

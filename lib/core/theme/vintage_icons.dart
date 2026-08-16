import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Catalogue d'icônes rétro + rendu badge vintage RAAGA.
class VintageIcons {
  // --- Catégories ---
  static IconData category(String name) {
    switch (name) {
      case 'Électroniques':
      case 'Électronique':
        return Icons.radio;
      case 'Moteurs':
        return Icons.directions_car_filled;
      case 'Habitations':
      case 'Maison':
        return Icons.cottage;
      case 'Mode':
      case 'Vêtements':
        return Icons.checkroom;
      case 'Sport':
      case 'Équipement sport':
        return Icons.sports_soccer;
      case 'Beauté':
        return Icons.spa;
      case 'Alimentation':
        return Icons.restaurant;
      case 'Livres':
        return Icons.menu_book;
      case 'Divertissement':
        return Icons.theater_comedy;
      case 'Jobs':
        return Icons.work_history;
      case 'Art':
        return Icons.palette;
      case 'Fournitures':
        return Icons.hardware;
      case 'Animaux':
        return Icons.pets;
      default:
        return Icons.category;
    }
  }

  // --- Actions marchand ---
  static IconData merchantAction(String title) {
    final t = title.toLowerCase();
    if (t.contains('ajouter un produit')) return Icons.add_business;
    if (t.contains('créer une story')) return Icons.camera_roll;
    if (t.contains('mes stories')) return Icons.photo_album;
    if (t.contains('mes produits')) return Icons.store;
    if (t.contains('conversation') || t.contains('chat')) {
      return Icons.phone_in_talk;
    }
    if (t.contains('stats')) return Icons.insights;
    if (t.contains('profil')) return Icons.account_balance;
    if (t.contains('pub')) return Icons.campaign;
    if (t.contains('plan')) return Icons.loyalty;
    return Icons.widgets;
  }

  // --- Stats dashboard ---
  static IconData merchantStat(String key) {
    switch (key) {
      case 'produits':
        return Icons.inventory;
      case 'stories':
        return Icons.camera_roll;
      case 'attente':
      case 'en attente':
        return Icons.assignment;
      case 'abonnés':
        return Icons.groups;
      default:
        return Icons.widgets;
    }
  }

  // --- Navigation marchand ---
  static IconData merchantNav(String label, {bool active = false}) {
    switch (label.toLowerCase()) {
      case 'accueil':
        return active ? Icons.home : Icons.cottage_outlined;
      case 'produits':
        return active ? Icons.inventory : Icons.inventory_2_outlined;
      case 'chat':
        return active ? Icons.phone_in_talk : Icons.phone_outlined;
      case 'pubs':
        return active ? Icons.campaign : Icons.campaign_outlined;
      case 'plans':
        return active ? Icons.loyalty : Icons.card_membership_outlined;
      case 'profil':
        return active ? Icons.store : Icons.storefront_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  // --- Navigation client ---
  static IconData customerNav(String label, {bool active = false}) {
    switch (label.toLowerCase()) {
      case 'accueil':
        return active ? Icons.home : Icons.cottage_outlined;
      case 'produits':
        return active ? Icons.grid_view_rounded : Icons.apps_outlined;
      case 'panier':
        return active ? Icons.shopping_basket : Icons.shopping_basket_outlined;
      case 'chat':
        return active ? Icons.phone_in_talk : Icons.phone_outlined;
      case 'profil':
        return active ? Icons.person : Icons.person_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}

/// Badge icône style vintage (cadre crème + bordure verte).
class VintageIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final bool filled;

  const VintageIconBadge({
    super.key,
    required this.icon,
    this.size = 22,
    this.color,
    this.backgroundColor,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppTheme.primaryDarkColor;
    final bg = backgroundColor ?? const Color(0xFFEAF3EA);

    return Container(
      width: size + 20,
      height: size + 20,
      decoration: BoxDecoration(
        color: filled ? bg : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.28),
          width: 1.4,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          icon,
          size: size,
          color: iconColor,
        ),
      ),
    );
  }
}

/// Petite icône vintage sans badge (pour nav / stats).
class VintageIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const VintageIcon({
    super.key,
    required this.icon,
    this.size = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color ?? AppTheme.primaryDarkColor,
    );
  }
}

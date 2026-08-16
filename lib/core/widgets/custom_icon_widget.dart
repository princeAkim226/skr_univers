import 'package:flutter/material.dart';
import 'custom_icon.dart';

class CustomIconWidget extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  const CustomIconWidget(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size ?? 24,
      color: color ?? Theme.of(context).iconTheme.color,
      semanticLabel: semanticLabel,
    );
  }
}

// Widgets spécialisés pour les icônes courantes
class HomeIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const HomeIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.home,
      size: size,
      color: color,
      semanticLabel: 'Accueil',
    );
  }
}

class SearchIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const SearchIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.search,
      size: size,
      color: color,
      semanticLabel: 'Rechercher',
    );
  }
}

class CartIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const CartIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.cart,
      size: size,
      color: color,
      semanticLabel: 'Panier',
    );
  }
}

class ProductsIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const ProductsIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.products,
      size: size,
      color: color,
      semanticLabel: 'Produits',
    );
  }
}

class OrdersIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const OrdersIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.orders,
      size: size,
      color: color,
      semanticLabel: 'Commandes',
    );
  }
}

class ProfileIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const ProfileIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.profile,
      size: size,
      color: color,
      semanticLabel: 'Profil',
    );
  }
}

class NotificationsIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const NotificationsIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.notifications,
      size: size,
      color: color,
      semanticLabel: 'Notifications',
    );
  }
}

class MenuIcon extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const MenuIcon({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return CustomIconWidget(
      CustomIcon.menu,
      size: size,
      color: color,
      semanticLabel: 'Menu',
    );
  }
}

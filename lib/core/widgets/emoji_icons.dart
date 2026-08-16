import 'package:flutter/material.dart';

class EmojiIcons {
  // Navigation
  static const String home = '🏠';
  static const String products = '🛍️';
  static const String cart = '🛒';
  static const String orders = '📋';
  static const String profile = '👤';
  
  // Actions
  static const String search = '🔍';
  static const String notifications = '🔔';
  static const String menu = '☰';
  static const String settings = '⚙️';
  
  // Catégories
  static const String electronics = '📱';
  static const String fashion = '👕';
  static const String food = '🍕';
  static const String home_garden = '🏠';
  static const String sports = '⚽';
  static const String beauty = '💄';
  
  // Actions produit
  static const String favorite = '❤️';
  static const String favorite_border = '🤍';
  static const String share = '📤';
  static const String add = '➕';
  static const String remove = '➖';
  
  // Statut
  static const String check = '✅';
  static const String close = '❌';
  static const String star = '⭐';
  static const String star_border = '☆';
  
  // Navigation
  static const String arrow_back = '⬅️';
  static const String arrow_forward = '➡️';
  static const String arrow_upward = '⬆️';
  static const String arrow_downward = '⬇️';
  
  // Communication
  static const String phone = '📞';
  static const String email = '📧';
  static const String location = '📍';
  static const String edit = '✏️';
  static const String delete = '🗑️';
  
  // Paiement
  static const String payment = '💳';
  static const String credit_card = '💳';
  static const String money = '💰';
  
  // Livraison
  static const String local_shipping = '🚚';
  static const String delivery_dining = '🚚';
  
  // Sécurité
  static const String security = '🔒';
  static const String lock = '🔒';
  static const String lock_open = '🔓';
  
  // Information
  static const String info = 'ℹ️';
  static const String help = '❓';
  static const String warning = '⚠️';
  static const String error = '❌';
  
  // Statut de commande
  static const String pending = '⏳';
  static const String processing = '⚙️';
  static const String shipped = '🚚';
  static const String delivered = '✅';
  static const String cancelled = '❌';
}

class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double? size;
  final Color? color;

  const EmojiIcon(
    this.emoji, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: size ?? 24,
        color: color,
      ),
    );
  }
}

// Widgets spécialisés
class HomeEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const HomeEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.home, size: size, color: color);
  }
}

class SearchEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const SearchEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.search, size: size, color: color);
  }
}

class CartEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const CartEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.cart, size: size, color: color);
  }
}

class ProductsEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const ProductsEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.products, size: size, color: color);
  }
}

class OrdersEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const OrdersEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.orders, size: size, color: color);
  }
}

class ProfileEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const ProfileEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.profile, size: size, color: color);
  }
}

class NotificationsEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const NotificationsEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.notifications, size: size, color: color);
  }
}

class MenuEmoji extends StatelessWidget {
  final double? size;
  final Color? color;
  
  const MenuEmoji({super.key, this.size, this.color});
  
  @override
  Widget build(BuildContext context) {
    return EmojiIcon(EmojiIcons.menu, size: size, color: color);
  }
}

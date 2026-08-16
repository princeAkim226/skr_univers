import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _productsKey = 'cached_products';
  static const String _categoriesKey = 'cached_categories';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _cartKey = 'cached_cart';
  static const String _lastSyncKey = 'last_sync_timestamp';
  
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Sauvegarder des produits en cache
  static Future<void> cacheProducts(List<Map<String, dynamic>> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = jsonEncode(products);
      await prefs.setString(_productsKey, productsJson);
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erreur lors de la sauvegarde du cache: $e');
    }
  }

  // Récupérer les produits du cache
  static Future<List<Map<String, dynamic>>> getCachedProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productsJson = prefs.getString(_productsKey);
      
      if (productsJson != null) {
        final List<dynamic> productsList = jsonDecode(productsJson);
        return productsList.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Erreur lors de la récupération du cache: $e');
      return [];
    }
  }

  // Vérifier si le cache est valide
  static Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(_lastSyncKey);
      
      if (lastSync == null) return false;
      
      final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
      final now = DateTime.now();
      
      return now.difference(lastSyncTime) < _cacheExpiry;
    } catch (e) {
      return false;
    }
  }

  // Sauvegarder les catégories en cache
  static Future<void> cacheCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, categories);
    } catch (e) {
      print('Erreur lors de la sauvegarde des catégories: $e');
    }
  }

  // Récupérer les catégories du cache
  static Future<List<String>> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_categoriesKey) ?? [];
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // Sauvegarder le profil utilisateur en cache
  static Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile);
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde du profil: $e');
    }
  }

  // Récupérer le profil utilisateur du cache
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_userProfileKey);
      
      if (profileJson != null) {
        return Map<String, dynamic>.from(jsonDecode(profileJson));
      }
      
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Sauvegarder le panier en cache
  static Future<void> cacheCart(List<Map<String, dynamic>> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(cartItems);
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Erreur lors de la sauvegarde du panier: $e');
    }
  }

  // Récupérer le panier du cache
  static Future<List<Map<String, dynamic>>> getCachedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        final List<dynamic> cartList = jsonDecode(cartJson);
        return cartList.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Erreur lors de la récupération du panier: $e');
      return [];
    }
  }

  // Vider le cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productsKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_userProfileKey);
      await prefs.remove(_cartKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      print('Erreur lors du vidage du cache: $e');
    }
  }

  // Obtenir la taille du cache
  static Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int totalSize = 0;
      
      final products = prefs.getString(_productsKey);
      if (products != null) totalSize += products.length;
      
      final categories = prefs.getStringList(_categoriesKey);
      if (categories != null) {
        totalSize += categories.join().length;
      }
      
      final profile = prefs.getString(_userProfileKey);
      if (profile != null) totalSize += profile.length;
      
      final cart = prefs.getString(_cartKey);
      if (cart != null) totalSize += cart.length;
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  // Obtenir la taille du cache en format lisible
  static Future<String> getCacheSizeString() async {
    final size = await getCacheSize();
    
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Vérifier la connectivité (simulation)
  static Future<bool> isOnline() async {
    // Dans une vraie app, utiliser connectivity_plus
    // Ici on simule une vérification
    try {
      // Simuler une vérification de connectivité
      await Future.delayed(const Duration(milliseconds: 100));
      return true; // Simuler une connexion disponible
    } catch (e) {
      return false;
    }
  }

  // Synchroniser les données
  static Future<void> syncData() async {
    try {
      // Dans une vraie app, synchroniser avec le serveur
      // Ici on simule une synchronisation
      await Future.delayed(const Duration(seconds: 1));
      print('Données synchronisées');
    } catch (e) {
      print('Erreur lors de la synchronisation: $e');
    }
  }
}

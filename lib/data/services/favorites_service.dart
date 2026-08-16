import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Favoris locaux (par utilisateur Auth).
class FavoritesService {
  static const _prefix = 'raaga_favorites_';

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  String get _key {
    final uid = _userId;
    if (uid == null) return '${_prefix}guest';
    return '$_prefix$uid';
  }

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.toSet();
  }

  Future<bool> isFavorite(String productId) async {
    final ids = await getFavoriteIds();
    return ids.contains(productId);
  }

  Future<bool> toggleFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await getFavoriteIds();
    if (ids.contains(productId)) {
      ids.remove(productId);
      await prefs.setStringList(_key, ids.toList());
      return false;
    } else {
      ids.add(productId);
      await prefs.setStringList(_key, ids.toList());
      return true;
    }
  }
}

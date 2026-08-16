import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardStats {
  final int users;
  final int customers;
  final int merchants;
  final int products;
  final int platformAds;

  const AdminDashboardStats({
    required this.users,
    required this.customers,
    required this.merchants,
    required this.products,
    required this.platformAds,
  });
}

class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<int> _count(String table, {String? column, Object? equals}) async {
    dynamic query = _supabase.from(table).select('id');
    if (column != null && equals != null) {
      query = query.eq(column, equals);
    }
    final rows = await query;
    return (rows as List).length;
  }

  Future<AdminDashboardStats> getDashboardStats() async {
    final users = await _count('users');
    final customers = await _count('users', column: 'user_type', equals: 'customer');
    final merchants = await _count('merchants');
    final products = await _count('products');
    int platformAds = 0;
    try {
      platformAds = await _count('platform_ads');
    } catch (_) {
      platformAds = 0;
    }

    return AdminDashboardStats(
      users: users,
      customers: customers,
      merchants: merchants,
      products: products,
      platformAds: platformAds,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase
        .from('users')
        .select(
          'id, first_name, last_name, phone_number, email, user_type, is_admin, is_active, business_name, created_at',
        )
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> setUserActive(String userId, bool isActive) async {
    await _supabase.from('users').update({'is_active': isActive}).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getMerchants() async {
    final response = await _supabase
        .from('merchants')
        .select(
          'id, user_id, business_name, business_phone, business_city, is_verified, created_at',
        )
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> setMerchantVerified(String merchantId, bool verified) async {
    await _supabase
        .from('merchants')
        .update({'is_verified': verified})
        .eq('id', merchantId);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await _supabase
        .from('products')
        .select('id, title, price, category, is_active, is_featured, created_at, merchant_id')
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> setProductActive(String productId, bool isActive) async {
    await _supabase.from('products').update({'is_active': isActive}).eq('id', productId);
  }

  Future<List<Map<String, dynamic>>> getMerchantAds() async {
    final response = await _supabase
        .from('ads')
        .select('id, title, is_active, is_default, created_at, merchant_id')
        .order('created_at', ascending: false)
        .limit(200);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> setMerchantAdActive(String adId, bool isActive) async {
    await _supabase.from('ads').update({'is_active': isActive}).eq('id', adId);
  }
}

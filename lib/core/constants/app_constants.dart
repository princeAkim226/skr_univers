import '../config/supabase_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Business Place';
  static const String appShortName = 'B-Place';
  static const String appTagline = 'Votre marché local';
  static const String appVersion = '1.0.0';
  static const String adminAppName = 'B-Place Admin';
  
  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeMerchant = 'merchant';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  
  // Supabase : utiliser SupabaseConfig.supabaseUrl et SupabaseConfig.supabaseAnonKey
  // (défini dans lib/core/config/supabase_config.dart pour gérer ancien/nouveau projet)
  static String get supabaseUrl => SupabaseConfig.supabaseUrl;
  static String get supabaseAnonKey => SupabaseConfig.supabaseAnonKey;
  
  // Storage Buckets
  static const String productImagesBucket = 'product-images';
  
  // Image Placeholders
  static const String productPlaceholder = 'https://via.placeholder.com/300x300?text=Produit';
  static const String userPlaceholder = 'https://via.placeholder.com/150x150?text=Utilisateur';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxProductTitleLength = 100;
  static const int maxProductDescriptionLength = 500;
  
  // Pagination
  static const int productsPerPage = 10;
  static const int ordersPerPage = 5;
}
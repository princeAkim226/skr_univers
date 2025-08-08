class AppConstants {
  // App Info
  static const String appName = 'SKR Univers';
  static const String appVersion = '1.0.0';
  
  // User Types
  static const String userTypeCustomer = 'customer';
  static const String userTypeMerchant = 'merchant';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userTypeKey = 'user_type';
  static const String userIdKey = 'user_id';
  
  // API Endpoints (à remplacer par vos vraies URLs Supabase)
  static const String supabaseUrl = 'https://jsobtcjxsurmlersugvc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impzb2J0Y2p4c3VybWxlcnN1Z3ZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ2NTEyMzgsImV4cCI6MjA3MDIyNzIzOH0.2Xb4tYt2rt2c7EgGV3agZjidS3-yh-Ryvm0VvnqEBRw';
  
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
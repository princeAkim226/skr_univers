class AppConfig {
  // Configuration de l'application
  static const String appName = 'Business Place';
  static const String appShortName = 'B-Place';
  static const String appVersion = '1.0.0';
  
  // Configuration des images
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxProductImages = 5;
  
  // Configuration des produits
  static const String defaultCurrency = 'FCFA';
  static const int productsPerPage = 10;
  static const int ordersPerPage = 5;
  
  // Configuration des notifications
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  
  // Configuration du cache
  static const int cacheExpirationHours = 24;
  
  // Configuration des limites
  static const int maxProductTitleLength = 100;
  static const int maxProductDescriptionLength = 500;
  static const int minPasswordLength = 6;
  
  // Configuration des catégories
  static const List<String> defaultCategories = [
    'Électronique',
    'Mode',
    'Maison',
    'Sport',
    'Livres',
    'Beauté',
    'Art',
    'Fournitures',
    'Animaux',
    'Jobs',
    'Divertissement',
    'Habitations',
    'Moteurs',
  ];
}

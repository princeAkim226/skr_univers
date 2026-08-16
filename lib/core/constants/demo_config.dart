class DemoConfig {
  // Configuration de démonstration (sans Supabase)
  static const bool isDemoMode = true;
  static const String demoMessage = 'Mode démonstration - Configuration Supabase requise';
  
  // Données de démonstration
  static const Map<String, dynamic> demoUser = {
    'id': 'demo-user-123',
    'email': 'demo@example.com',
    'user_metadata': {
      'first_name': 'Utilisateur',
      'last_name': 'Démo',
    }
  };
  
  static const List<Map<String, dynamic>> demoProducts = [
    {
      'id': '1',
      'name': 'Smartphone Samsung',
      'description': 'Smartphone Android dernier cri',
      'price': 150000.0,
      'image_url': 'https://via.placeholder.com/300x300?text=Smartphone',
      'merchant_name': 'Tech Store',
    },
    {
      'id': '2', 
      'name': 'Ordinateur Portable',
      'description': 'Laptop performant pour le travail',
      'price': 350000.0,
      'image_url': 'https://via.placeholder.com/300x300?text=Laptop',
      'merchant_name': 'Computer World',
    },
  ];
  
  static const List<Map<String, dynamic>> demoCategories = [
    {'id': '1', 'name': 'Électronique', 'icon': '📱'},
    {'id': '2', 'name': 'Mode', 'icon': '👕'},
    {'id': '3', 'name': 'Maison', 'icon': '🏠'},
    {'id': '4', 'name': 'Sport', 'icon': '⚽'},
  ];
}

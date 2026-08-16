import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtenir toutes les catégories uniques des produits
  Future<List<String>> getAllCategories() async {
    try {
      final response = await _supabase
          .from('products')
          .select('category')
          .eq('is_active', true);

      // Extraire les catégories uniques
      final categories = response
          .map((product) => product['category'] as String?)
          .where((category) => category != null && category.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      // Trier par ordre alphabétique
      categories.sort();
      
      return categories;
    } catch (e) {
      print('Erreur lors de la récupération des catégories: $e');
      return [];
    }
  }

  // Obtenir les produits par catégorie
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      print('🔍 Recherche de produits pour la catégorie: $category');
      
      // Récupérer les produits sans jointure (plus robuste si les FK ne sont pas configurées)
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final products = List<Map<String, dynamic>>.from(response);
      print('📦 Produits récupérés: ${products.length}');

      // Enrichir avec les données marchands (table merchants)
      for (final product in products) {
        try {
          final merchantId = product['merchant_id']?.toString();
          if (merchantId != null && merchantId.isNotEmpty) {
            final merchant = await _supabase
                .from('merchants')
                .select('id, business_name, business_description, business_image, business_phone, business_address, is_verified')
                .eq('id', merchantId)
                .maybeSingle();
            product['merchant'] = merchant ??
                {
                  'id': merchantId,
                  'business_name': 'Marchand inconnu',
                  'business_description': null,
                  'business_image': null,
                  'business_phone': null,
                  'business_address': null,
                  'is_verified': false,
                };
          } else {
            product['merchant'] = {
              'id': null,
              'business_name': 'Marchand inconnu',
              'business_description': null,
              'business_image': null,
              'business_phone': null,
              'business_address': null,
              'is_verified': false,
            };
          }
        } catch (e) {
          product['merchant'] = {
            'id': product['merchant_id']?.toString(),
            'business_name': 'Marchand inconnu',
            'business_description': null,
            'business_image': null,
            'business_phone': null,
            'business_address': null,
            'is_verified': false,
          };
        }
      }

      return products;
    } catch (e) {
      print('❌ Erreur lors de la récupération des produits par catégorie: $e');
      return [];
    }
  }

  // Obtenir les statistiques des catégories (nombre de produits par catégorie) - Version corrigée
  Future<Map<String, int>> getCategoryStats() async {
    try {
      print('📊 Calcul des statistiques des catégories (version corrigée)...');
      
      // Utiliser exactement la même logique que getProductsByCategory
      final categories = await getAllCategories();
      final Map<String, int> stats = {};
      
      for (final category in categories) {
        try {
          // Utiliser la même requête que getProductsByCategory mais sans jointure
          final response = await _supabase
              .from('products')
              .select('id, title, category, merchant_id, description, price, images, is_active')
              .eq('category', category)
              .eq('is_active', true);
          
          stats[category] = response.length;
          print('📈 $category: ${response.length} produits (méthode corrigée)');
        } catch (e) {
          print('❌ Erreur pour la catégorie $category: $e');
          stats[category] = 0;
        }
      }

      print('📈 Statistiques finales (corrigées): $stats');
      return stats;
    } catch (e) {
      print('❌ Erreur lors de la récupération des statistiques des catégories: $e');
      return {};
    }
  }

  // Vérifier la cohérence entre les statistiques et les produits réels
  Future<Map<String, bool>> verifyCategoryConsistency() async {
    try {
      print('🔍 Vérification de la cohérence des catégories...');
      
      final stats = await getCategoryStats();
      final Map<String, bool> consistency = {};
      
      for (final category in stats.keys) {
        final actualProducts = await getProductsByCategory(category);
        final expectedCount = stats[category] ?? 0;
        final actualCount = actualProducts.length;
        
        consistency[category] = expectedCount == actualCount;
        
        if (expectedCount != actualCount) {
          print('⚠️ Incohérence détectée pour "$category":');
          print('   Statistiques: $expectedCount produits');
          print('   Produits réels: $actualCount produits');
        } else {
          print('✅ "$category": cohérent ($actualCount produits)');
        }
      }
      
      return consistency;
    } catch (e) {
      print('❌ Erreur lors de la vérification de cohérence: $e');
      return {};
    }
  }

  // Nettoyer les catégories vides des statistiques
  Future<Map<String, int>> getCleanCategoryStats() async {
    try {
      print('🧹 Nettoyage des statistiques des catégories...');
      
      final stats = await getCategoryStats();
      final Map<String, int> cleanStats = {};
      
      for (final entry in stats.entries) {
        final category = entry.key;
        final count = entry.value;
        
        // Vérifier que la catégorie a vraiment des produits
        if (count > 0) {
          final actualProducts = await getProductsByCategory(category);
          if (actualProducts.isNotEmpty) {
            cleanStats[category] = actualProducts.length;
            print('✅ $category: ${actualProducts.length} produits (confirmé)');
          } else {
            print('❌ $category: $count dans stats mais 0 produits réels - SUPPRIMÉ');
          }
        } else {
          print('❌ $category: 0 produits - SUPPRIMÉ');
        }
      }
      
      print('🧹 Statistiques nettoyées: $cleanStats');
      return cleanStats;
    } catch (e) {
      print('❌ Erreur lors du nettoyage des statistiques: $e');
      return {};
    }
  }

  // Méthode de débogage approfondie pour une catégorie spécifique
  Future<void> debugCategoryThoroughly(String category) async {
    try {
      print('🔍 === DÉBOGAGE APPROFONDI: $category ===');
      
      // 1. Vérifier tous les produits de cette catégorie (même inactifs)
      final allProducts = await _supabase
          .from('products')
          .select('id, title, category, is_active, merchant_id, created_at')
          .eq('category', category);
      
      print('📦 Tous les produits pour "$category": ${allProducts.length}');
      for (final product in allProducts) {
        print('  - ID: ${product['id']}, Titre: ${product['title']}, Actif: ${product['is_active']}, Merchant: ${product['merchant_id']}, Créé: ${product['created_at']}');
      }
      
      // 2. Vérifier les produits actifs seulement
      final activeProducts = await _supabase
          .from('products')
          .select('id, title, category, is_active, merchant_id')
          .eq('category', category)
          .eq('is_active', true);
      
      print('✅ Produits actifs pour "$category": ${activeProducts.length}');
      
      // 3. Vérifier avec la même requête que getProductsByCategory
      final productsWithJoin = await _supabase
          .from('products')
          .select('''
            id,
            merchant_id,
            title,
            description,
            price,
            original_price,
            stock_quantity,
            images,
            category,
            tags,
            is_active,
            is_featured,
            created_at,
            updated_at,
            latitude,
            longitude,
            address,
            merchant:users!products_merchant_id_fkey(
              id,
              first_name,
              last_name,
              business_name,
              business_description,
              profile_image,
              phone_number
            )
          ''')
          .eq('category', category)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      print('🔗 Produits avec jointure pour "$category": ${productsWithJoin.length}');
      
      // 4. Vérifier sans jointure (comme dans le fallback)
      final productsWithoutJoin = await _supabase
          .from('products')
          .select('id, title, category, merchant_id, description, price, images, is_active')
          .eq('category', category)
          .eq('is_active', true);
      
      print('📋 Produits sans jointure pour "$category": ${productsWithoutJoin.length}');
      
      // 5. Vérifier les merchants associés
      if (activeProducts.isNotEmpty) {
        final merchantIds = activeProducts.map((p) => p['merchant_id']).toSet();
        print('👥 Merchants impliqués: $merchantIds');
        
        for (final merchantId in merchantIds) {
          try {
            final merchant = await _supabase
                .from('users')
                .select('id, business_name, first_name, last_name, user_type')
                .eq('id', merchantId)
                .single();
            print('  - Merchant $merchantId: ${merchant['business_name']} (${merchant['first_name']} ${merchant['last_name']}) - Type: ${merchant['user_type']}');
          } catch (e) {
            print('  - Merchant $merchantId: ERREUR - $e');
          }
        }
      }
      
      print('🔍 === FIN DÉBOGAGE APPROFONDI ===\n');
    } catch (e) {
      print('❌ Erreur lors du débogage approfondi: $e');
    }
  }

  // Méthode de débogage pour vérifier les données de la base
  Future<void> debugCategoryData(String category) async {
    try {
      print('🔍 === DÉBOGAGE CATÉGORIE: $category ===');
      
      // 1. Vérifier tous les produits de cette catégorie (même inactifs)
      final allProducts = await _supabase
          .from('products')
          .select('id, title, category, is_active, merchant_id')
          .eq('category', category);
      
      print('📦 Tous les produits pour "$category": ${allProducts.length}');
      for (final product in allProducts) {
        print('  - ${product['title']} (actif: ${product['is_active']}, merchant: ${product['merchant_id']})');
      }
      
      // 2. Vérifier les produits actifs seulement
      final activeProducts = await _supabase
          .from('products')
          .select('id, title, category, is_active, merchant_id')
          .eq('category', category)
          .eq('is_active', true);
      
      print('✅ Produits actifs pour "$category": ${activeProducts.length}');
      
      // 3. Vérifier les merchants associés
      if (activeProducts.isNotEmpty) {
        final merchantIds = activeProducts.map((p) => p['merchant_id']).toSet();
        print('👥 Merchants impliqués: $merchantIds');
        
        for (final merchantId in merchantIds) {
          final merchant = await _supabase
              .from('users')
              .select('id, business_name, first_name, last_name')
              .eq('id', merchantId)
              .single();
          print('  - Merchant $merchantId: ${merchant['business_name']} (${merchant['first_name']} ${merchant['last_name']})');
        }
      }
      
      print('🔍 === FIN DÉBOGAGE ===\n');
    } catch (e) {
      print('❌ Erreur lors du débogage: $e');
    }
  }

  // Obtenir les e-commerçants par catégorie
  Future<List<Map<String, dynamic>>> getMerchantsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select('''
            merchant:users!products_merchant_id_fkey(
              id,
              first_name,
              last_name,
              business_name,
              business_description,
              profile_image,
              phone_number,
              created_at
            )
          ''')
          .eq('category', category)
          .eq('is_active', true);

      // Extraire les e-commerçants uniques
      final merchants = <String, Map<String, dynamic>>{};
      
      for (final product in response) {
        final merchant = product['merchant'] as Map<String, dynamic>?;
        if (merchant != null) {
          final merchantId = merchant['id'] as String;
          if (!merchants.containsKey(merchantId)) {
            merchants[merchantId] = merchant;
          }
        }
      }

      return merchants.values.toList();
    } catch (e) {
      print('Erreur lors de la récupération des e-commerçants par catégorie: $e');
      return [];
    }
  }
}

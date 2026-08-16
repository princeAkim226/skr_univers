import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createProduct({
    required String title,
    required String description,
    required double price,
    double? originalPrice,
    required int stockQuantity,
    required String category,
    List<String> images = const [],
    List<String> tags = const [],
    double? latitude,
    double? longitude,
    String? address,
    // Champs spécifiques aux habitations
    String? propertyType,
    int? propertyRooms,
    double? propertySurface,
    String? propertyGoal,
    String? propertyCity,
    String? propertyZone,
    String? propertyQuarter,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer l'ID du profil marchand de l'utilisateur
    String merchantId;
    try {
      final merchantResponse = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      merchantId = merchantResponse['id'] as String;
    } catch (e) {
      // Si aucun profil marchand n'existe, en créer un automatiquement
      print('Aucun profil marchand trouvé, création automatique...');
      
      final newMerchantResponse = await _supabase
          .from('merchants')
          .insert({
            'user_id': user.id,
            'business_name': 'Mon Commerce',
            'business_email': user.email,
            'business_description': 'Description de mon commerce',
            'is_verified': false,
          })
          .select('id')
          .single();
      
      merchantId = newMerchantResponse['id'] as String;
      print('Profil marchand créé avec l\'ID: $merchantId');
    }

    final productData = {
      'merchant_id': merchantId, // Utiliser l'ID du profil marchand, pas l'ID utilisateur
      'title': title,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'stock_quantity': stockQuantity,
      'images': images,
      'category': category,
      'tags': tags,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'is_active': true,
      'is_featured': false,
      // Champs spécifiques aux habitations
      if (propertyType != null) 'property_type': propertyType,
      if (propertyRooms != null) 'property_rooms': propertyRooms,
      if (propertySurface != null) 'property_surface': propertySurface,
      if (propertyGoal != null) 'property_goal': propertyGoal,
      if (propertyCity != null) 'property_city': propertyCity,
      if (propertyZone != null) 'property_zone': propertyZone,
      if (propertyQuarter != null) 'property_quarter': propertyQuarter,
    };

    print('Tentative de création du produit avec: $productData');
    print('Merchant ID utilisé: $merchantId');

    final response = await _supabase
        .from('products')
        .insert(productData)
        .select()
        .single();
        
    print('Produit créé avec succès: $response');
    return response;
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      print('Tentative de récupération des produits...');
      final response = await _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name)')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      print('Réponse brute de Supabase: $response');
      print('Type de la réponse: ${response.runtimeType}');
      print('Nombre de produits: ${response.length}');
      
      final products = List<Map<String, dynamic>>.from(response);
      print('Produits convertis: $products');
      return products;
    } catch (e) {
      print('Erreur lors de la récupération des produits: $e');
      throw Exception('Impossible de récupérer les produits.');
    }
  }

  // Nouvelle méthode pour récupérer les produits récents (pour les cercles)
  Future<List<Map<String, dynamic>>> getRecentProducts({int limit = 10}) async {
    try {
      print('Récupération des produits récents...');
      final response = await _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);
      
      final products = List<Map<String, dynamic>>.from(response);
      print('Produits récents récupérés: ${products.length}');
      return products;
    } catch (e) {
      print('Erreur lors de la récupération des produits récents: $e');
      throw Exception('Impossible de récupérer les produits récents.');
    }
  }

  // Méthode pour récupérer les produits par catégorie
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      print('🔍 Récupération des produits pour la catégorie: $category');
      
      // Étape 1: Récupérer d'abord les produits sans jointure pour vérifier qu'ils existent
      print('📊 Étape 1: Récupération des produits sans jointure...');
      final productsResponse = await _supabase
          .from('products')
          .select('*')
          .eq('is_active', true)
          .eq('category', category)
          .order('created_at', ascending: false);
      
      print('📊 Produits trouvés (sans jointure): ${productsResponse.length}');
      
      if (productsResponse.isEmpty) {
        print('⚠️ Aucun produit trouvé pour la catégorie: $category');
        print('🔍 Vérification: category=$category, is_active=true');
        return [];
      }
      
      // Afficher les détails des premiers produits
      for (var i = 0; i < productsResponse.length && i < 3; i++) {
        final p = productsResponse[i];
        print('📦 Produit ${i + 1}: ${p['title']}, goal=${p['property_goal']}, merchant_id=${p['merchant_id']}');
      }
      
      // Étape 2: Enrichir avec les données des marchands
      print('📊 Étape 2: Enrichissement avec les données des marchands...');
      final products = <Map<String, dynamic>>[];
      for (final product in productsResponse) {
        try {
          final merchantId = product['merchant_id'] as String?;
          if (merchantId != null) {
            final merchantResponse = await _supabase
                .from('merchants')
                .select('business_name, business_image, is_verified')
                .eq('id', merchantId)
                .maybeSingle();
            
            product['merchant'] = merchantResponse ?? {
              'business_name': 'Marchand inconnu',
              'business_image': null,
              'is_verified': false,
            };
            print('✅ Marchand récupéré pour ${product['title']}: ${product['merchant']['business_name']}');
          } else {
            print('⚠️ Produit ${product['title']} sans merchant_id');
            product['merchant'] = {
              'business_name': 'Marchand inconnu',
              'business_image': null,
              'is_verified': false,
            };
          }
        } catch (e) {
          print('⚠️ Erreur lors de la récupération du marchand pour le produit ${product['id']}: $e');
          product['merchant'] = {
            'business_name': 'Marchand inconnu',
            'business_image': null,
            'is_verified': false,
          };
        }
        products.add(product);
      }
      
      print('✅ Produits récupérés avec marchands: ${products.length}');
      if (products.isNotEmpty) {
        print('📦 Premier produit final: ${products.first['title']}');
        print('📦 Property goal: ${products.first['property_goal']}');
        print('📦 Merchant: ${products.first['merchant']}');
      }
      return products;
    } catch (e, stackTrace) {
      print('❌ Erreur lors de la récupération des produits par catégorie: $e');
      print('📚 Stack trace: $stackTrace');
      print('🔍 Détails de l\'erreur: ${e.toString()}');
      throw Exception('Impossible de récupérer les produits de cette catégorie.');
    }
  }

  // Méthode pour récupérer les produits d'un e-commerçant spécifique
  Future<List<Map<String, dynamic>>> getProductsByMerchant(String merchantId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image, business_phone, business_address)')
          .eq('is_active', true)
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des produits du e-commerçant: $e');
      throw Exception('Impossible de récupérer les produits de ce e-commerçant.');
    }
  }

  // Méthode pour récupérer les produits du marchand connecté (sécurisée)
  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Récupérer l'ID du marchand connecté
      final merchantResponse = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final merchantId = merchantResponse['id'] as String;
      
      // Récupérer les produits de ce marchand (tous, même inactifs)
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération de mes produits: $e');
      throw Exception('Impossible de récupérer vos produits.');
    }
  }

  // Méthode pour récupérer les produits proches du client connecté
  Future<List<Map<String, dynamic>>> getNearbyProducts({
    double maxDistanceKm = 50.0,
    String? category,
  }) async {
    try {
      // Récupérer tous les produits actifs avec géolocalisation
      var query = _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image, business_phone, business_address, latitude, longitude)')
          .eq('is_active', true)
          .not('latitude', 'is', null)
          .not('longitude', 'is', null);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);
      final products = List<Map<String, dynamic>>.from(response);
      
      // Filtrer par distance (cette logique sera implémentée côté client)
      return products;
    } catch (e) {
      print('Erreur lors de la récupération des produits proches: $e');
      throw Exception('Impossible de récupérer les produits proches.');
    }
  }

  // Méthode pour récupérer un produit par ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image, business_phone, business_address)')
          .eq('id', id)
          .single();
      
      return response;
    } catch (e) {
      print('Erreur lors de la récupération du produit: $e');
      throw Exception('Impossible de récupérer ce produit.');
    }
  }

  // Méthode pour rechercher des produits
  Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String sortBy = 'created_at',
    bool ascending = false,
    int limit = 20,
  }) async {
    try {
      print('Recherche de produits avec: $query');
      
      var queryBuilder = _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image)')
          .eq('is_active', true);

      // Recherche textuelle
      if (query.isNotEmpty) {
        queryBuilder = queryBuilder.or(
          'title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}'
        );
      }

      // Filtre par catégorie
      if (category != null && category.isNotEmpty) {
        queryBuilder = queryBuilder.eq('category', category);
      }

      // Filtre par prix minimum
      if (minPrice != null) {
        queryBuilder = queryBuilder.gte('price', minPrice);
      }

      // Filtre par prix maximum
      if (maxPrice != null) {
        queryBuilder = queryBuilder.lte('price', maxPrice);
      }

      // Tri et limite
      final response = await queryBuilder
          .order(sortBy, ascending: ascending)
          .limit(limit);
      final products = List<Map<String, dynamic>>.from(response);
      
      print('Produits trouvés: ${products.length}');
      return products;
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      throw Exception('Impossible de rechercher les produits.');
    }
  }

  // Méthode pour récupérer les produits basés sur les centres d'intérêt
  Future<List<Map<String, dynamic>>> getProductsByInterests(List<String> interests) async {
    try {
      if (interests.isEmpty) {
        return await getProducts();
      }

      final response = await _supabase
          .from('products')
          .select('*, merchant:merchant_id(business_name, business_image)')
          .eq('is_active', true)
          .or(interests.map((interest) => 'category.ilike.%$interest%').join(','))
          .order('created_at', ascending: false)
          .limit(20);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des produits par centres d\'intérêt: $e');
      // En cas d'erreur, retourner les produits normaux
      return await getProducts();
    }
  }

  // Méthode pour obtenir les suggestions de recherche
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      if (query.length < 2) return [];

      final response = await _supabase
          .from('products')
          .select('title, category, tags')
          .eq('is_active', true)
          .or('title.ilike.%$query%,category.ilike.%$query%')
          .limit(10);

      final suggestions = <String>{};
      
      for (final product in response) {
        // Ajouter le titre du produit
        final title = product['title'] as String?;
        if (title != null && title.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(title);
        }

        // Ajouter la catégorie
        final category = product['category'] as String?;
        if (category != null && category.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(category);
        }

        // Ajouter les tags
        final tags = product['tags'] as List?;
        if (tags != null) {
          for (final tag in tags) {
            if (tag.toString().toLowerCase().contains(query.toLowerCase())) {
              suggestions.add(tag.toString());
            }
          }
        }
      }

      return suggestions.take(8).toList();
    } catch (e) {
      print('Erreur lors de la récupération des suggestions: $e');
      return [];
    }
  }
}


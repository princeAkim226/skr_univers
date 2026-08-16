import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Ajouter un produit au panier
  Future<void> addToCart(String productId, int quantity) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer l'ID du client ou en créer un si nécessaire
    String customerId;
    try {
      final customerResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (customerResponse != null) {
        customerId = customerResponse['id'] as String;
      } else {
        throw Exception('Aucun profil client trouvé');
      }
    } catch (e) {
      // Si aucun profil client n'existe, en créer un automatiquement
      print('Aucun profil client trouvé, création automatique...');
      
      final newCustomerResponse = await _supabase
          .from('customers')
          .insert({
            'user_id': user.id,
            'name': user.userMetadata?['name'] ?? 'Client',
            'email': user.email ?? 'client@example.com',
          })
          .select('id')
          .single();
      
      customerId = newCustomerResponse['id'] as String;
      print('Profil client créé avec l\'ID: $customerId');
    }

    // Vérifier si le produit est déjà dans le panier
    final existingItem = await _supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (existingItem != null) {
      // Mettre à jour la quantité
      await _supabase
          .from('cart_items')
          .update({'quantity': existingItem['quantity'] + quantity})
          .eq('id', existingItem['id']);
    } else {
      // Ajouter un nouvel article
      await _supabase.from('cart_items').insert({
        'customer_id': customerId,
        'product_id': productId,
        'quantity': quantity,
      });
    }
  }

  // Récupérer le contenu du panier
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer l'ID du client ou en créer un si nécessaire
    String customerId;
    try {
      final customerResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (customerResponse != null) {
        customerId = customerResponse['id'] as String;
      } else {
        throw Exception('Aucun profil client trouvé');
      }
    } catch (e) {
      // Si aucun profil client n'existe, en créer un automatiquement
      print('Aucun profil client trouvé, création automatique...');
      
      final newCustomerResponse = await _supabase
          .from('customers')
          .insert({
            'user_id': user.id,
            'name': user.userMetadata?['name'] ?? 'Client',
            'email': user.email ?? 'client@example.com',
          })
          .select('id')
          .single();
      
      customerId = newCustomerResponse['id'] as String;
      print('Profil client créé avec l\'ID: $customerId');
    }

    final response = await _supabase
        .from('cart_items')
        .select('''
          *,
          product:product_id(
            id,
            title,
            price,
            original_price,
            images,
            stock_quantity,
            merchant:merchant_id(business_name)
          )
        ''')
        .eq('customer_id', customerId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Mettre à jour la quantité d'un article
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  // Supprimer un article du panier
  Future<void> removeFromCart(String cartItemId) async {
    await _supabase
        .from('cart_items')
        .delete()
        .eq('id', cartItemId);
  }

  // Vider le panier
  Future<void> clearCart() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer l'ID du client ou en créer un si nécessaire
    String customerId;
    try {
      final customerResponse = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();
      
      if (customerResponse != null) {
        customerId = customerResponse['id'] as String;
      } else {
        throw Exception('Aucun profil client trouvé');
      }
    } catch (e) {
      // Si aucun profil client n'existe, en créer un automatiquement
      print('Aucun profil client trouvé, création automatique...');
      
      final newCustomerResponse = await _supabase
          .from('customers')
          .insert({
            'user_id': user.id,
            'name': user.userMetadata?['name'] ?? 'Client',
            'email': user.email ?? 'client@example.com',
          })
          .select('id')
          .single();
      
      customerId = newCustomerResponse['id'] as String;
      print('Profil client créé avec l\'ID: $customerId');
    }

    await _supabase
        .from('cart_items')
        .delete()
        .eq('customer_id', customerId);
  }

  // Calculer le total du panier
  double calculateTotal(List<Map<String, dynamic>> cartItems) {
    double total = 0;
    for (final item in cartItems) {
      final product = item['product'];
      if (product != null) {
        final price = (product['price'] ?? 0).toDouble();
        final quantity = (item['quantity'] ?? 0).toInt();
        total += price * quantity;
      }
    }
    return total;
  }

  // Vérifier la disponibilité des produits
  Future<List<String>> checkAvailability(List<Map<String, dynamic>> cartItems) async {
    final List<String> unavailableProducts = [];

    for (final item in cartItems) {
      final product = item['product'];
      if (product != null) {
        final stockQuantity = (product['stock_quantity'] ?? 0).toInt();
        final requestedQuantity = (item['quantity'] ?? 0).toInt();
        
        if (requestedQuantity > stockQuantity) {
          unavailableProducts.add(product['title']);
        }
      }
    }

    return unavailableProducts;
  }
}

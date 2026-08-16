import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Créer une commande
  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> cartItems,
    required String shippingAddress,
    String? notes,
    String? promoCodeId,
    double discountAmount = 0,
    double? subtotalAmount,
    double? finalAmount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Récupérer l'ID du client
    final customerResponse = await _supabase
        .from('customers')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final customerId = customerResponse['id'];

    // Calculer le total
    double totalAmount = 0;
    for (final item in cartItems) {
      final product = item['product'];
      if (product != null) {
        final price = (product['price'] ?? 0).toDouble();
        final quantity = (item['quantity'] ?? 0).toInt();
        totalAmount += price * quantity;
      }
    }

    // Déterminer l'ID du marchand (products.merchant_id = merchants.id)
    String? merchantId;
    if (cartItems.isNotEmpty) {
      final firstProduct = cartItems.first['product'];
      if (firstProduct != null) {
        merchantId = firstProduct['merchant_id']?.toString();
        if ((merchantId == null || merchantId.isEmpty) && firstProduct['merchant'] is Map) {
          merchantId = (firstProduct['merchant'] as Map)['id']?.toString();
        }
      }
    }

    final computedSubtotal = subtotalAmount ?? totalAmount;
    final computedFinalTotal = finalAmount ?? (computedSubtotal - discountAmount).clamp(0, double.infinity);

    // Créer la commande
    final orderResponse = await _supabase
        .from('orders')
        .insert({
          'customer_id': customerId,
          'merchant_id': merchantId,
          'total_amount': computedFinalTotal,
          'subtotal_amount': computedSubtotal,
          'discount_amount': discountAmount,
          'final_amount': computedFinalTotal,
          'promo_code_id': promoCodeId,
          'status': 'pending',
          'shipping_address': shippingAddress,
          'notes': notes,
        })
        .select()
        .single();

    final orderId = orderResponse['id'];

    // Créer les articles de commande
    for (final item in cartItems) {
      final product = item['product'];
      if (product != null) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': product['id'],
          'quantity': item['quantity'],
          'price': product['price'],
        });
      }
    }

    // Vider le panier
    await _supabase
        .from('cart_items')
        .delete()
        .eq('customer_id', customerId);

    return orderResponse;
  }

  // Récupérer les commandes du client
  Future<List<Map<String, dynamic>>> getCustomerOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final customerResponse = await _supabase
        .from('customers')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final customerId = customerResponse['id'];

    final response = await _supabase
        .from('orders')
        .select('''
          *,
          order_items(
            id,
            quantity,
            price,
            product:product_id(
              id,
              title,
              images,
              merchant:merchant_id(business_name)
            )
          )
        ''')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Récupérer les commandes de l'e-commerçant
  Future<List<Map<String, dynamic>>> getMerchantOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final merchantResponse = await _supabase
        .from('merchants')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final merchantId = merchantResponse['id'];

    final response = await _supabase
        .from('orders')
        .select('''
          *,
          customer:customer_id(
            id,
            name,
            phone,
            address
          ),
          order_items(
            id,
            quantity,
            price,
            product:product_id(
              id,
              title,
              images
            )
          )
        ''')
        .eq('merchant_id', merchantId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Mettre à jour le statut d'une commande
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', orderId);
  }

  // Récupérer une commande par ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await _supabase
        .from('orders')
        .select('''
          *,
          customer:customer_id(
            id,
            name,
            phone,
            address
          ),
          merchant:merchant_id(
            id,
            business_name,
            business_phone,
            business_address
          ),
          order_items(
            id,
            quantity,
            price,
            product:product_id(
              id,
              title,
              images,
              description
            )
          )
        ''')
        .eq('id', orderId)
        .single();

    return response;
  }

  // Obtenir les statistiques des commandes pour l'e-commerçant
  Future<Map<String, dynamic>> getOrderStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final merchantResponse = await _supabase
        .from('merchants')
        .select('id')
        .eq('user_id', user.id)
        .single();

    final merchantId = merchantResponse['id'];

    // Compter les commandes par statut
    final pendingOrders = await _supabase
        .from('orders')
        .select('id')
        .eq('merchant_id', merchantId)
        .eq('status', 'pending');

    final confirmedOrders = await _supabase
        .from('orders')
        .select('id')
        .eq('merchant_id', merchantId)
        .eq('status', 'confirmed');

    final shippedOrders = await _supabase
        .from('orders')
        .select('id')
        .eq('merchant_id', merchantId)
        .eq('status', 'shipped');

    final deliveredOrders = await _supabase
        .from('orders')
        .select('id')
        .eq('merchant_id', merchantId)
        .eq('status', 'delivered');

    // Calculer le chiffre d'affaires
    final revenueResponse = await _supabase
        .from('orders')
        .select('total_amount')
        .eq('merchant_id', merchantId)
        .eq('status', 'delivered');

    double totalRevenue = 0;
    for (final order in revenueResponse) {
      totalRevenue += (order['total_amount'] ?? 0).toDouble();
    }

    return {
      'pending': pendingOrders.length,
      'confirmed': confirmedOrders.length,
      'shipped': shippedOrders.length,
      'delivered': deliveredOrders.length,
      'total_revenue': totalRevenue,
    };
  }
}
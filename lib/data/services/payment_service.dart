import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PaymentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Simuler un paiement Mobile Money
  Future<Map<String, dynamic>> processMobileMoneyPayment({
    required String phoneNumber,
    required double amount,
    required String orderId,
  }) async {
    try {
      // Simulation d'un délai de traitement
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulation d'une réponse de paiement (toujours réussie pour la démo)
      final paymentId = _uuid.v4();
      
      // Enregistrer le paiement dans la base de données
      final paymentResponse = await _supabase
          .from('payments')
          .insert({
            'id': paymentId,
            'order_id': orderId,
            'amount': amount,
            'payment_method': 'mobile_money',
            'phone_number': phoneNumber,
            'status': 'completed',
            'transaction_id': 'MM_${DateTime.now().millisecondsSinceEpoch}',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'payment_id': paymentId,
        'transaction_id': paymentResponse['transaction_id'],
        'message': 'Paiement effectué avec succès',
      };
    } catch (e) {
      print('Erreur lors du paiement: $e');
      return {
        'success': false,
        'error': 'Impossible de traiter le paiement. Réessayez.',
      };
    }
  }

  // Simuler un paiement par carte bancaire
  Future<Map<String, dynamic>> processCardPayment({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
    required double amount,
    required String orderId,
  }) async {
    try {
      // Simulation d'un délai de traitement
      await Future.delayed(const Duration(seconds: 3));
      
      // Simulation d'une réponse de paiement (toujours réussie pour la démo)
      final paymentId = _uuid.v4();
      
      // Enregistrer le paiement dans la base de données
      final paymentResponse = await _supabase
          .from('payments')
          .insert({
            'id': paymentId,
            'order_id': orderId,
            'amount': amount,
            'payment_method': 'card',
            'card_last_four': cardNumber.substring(cardNumber.length - 4),
            'status': 'completed',
            'transaction_id': 'CARD_${DateTime.now().millisecondsSinceEpoch}',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return {
        'success': true,
        'payment_id': paymentId,
        'transaction_id': paymentResponse['transaction_id'],
        'message': 'Paiement par carte effectué avec succès',
      };
    } catch (e) {
      print('Erreur lors du paiement par carte: $e');
      return {
        'success': false,
        'error': 'Impossible de traiter le paiement par carte. Réessayez.',
      };
    }
  }

  // Obtenir l'historique des paiements d'un client
  Future<List<Map<String, dynamic>>> getPaymentHistory(String customerId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*, order:order_id(*)')
          .eq('order.customer_id', customerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique des paiements: $e');
      return [];
    }
  }

  // Vérifier le statut d'un paiement
  Future<Map<String, dynamic>?> getPaymentStatus(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('id', paymentId)
          .single();

      return response;
    } catch (e) {
      print('Erreur lors de la vérification du statut du paiement: $e');
      return null;
    }
  }
}
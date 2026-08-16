import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/subscription_plans.dart';

/// Service pour gérer les abonnements publicitaires (séparés des plans d'abonnement)
class AdSubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Activer un abonnement publicitaire
  Future<bool> activateAdSubscription({
    required String merchantId,
    required double price,
    int? durationInDays,
  }) async {
    try {
      final duration = durationInDays ?? AdSubscriptionPlans.getDurationInDays();
      final endDate = DateTime.now().add(Duration(days: duration));
      
      // Créer ou mettre à jour l'abonnement publicitaire
      await _supabase
          .from('ad_subscriptions')
          .upsert({
            'merchant_id': merchantId,
            'price': price,
            'currency': 'FCFA',
            'start_date': DateTime.now().toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'is_active': true,
          });

      print('Abonnement publicitaire activé avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de l\'activation de l\'abonnement publicitaire: $e');
      return false;
    }
  }

  // Vérifier si un e-commerçant a un abonnement publicitaire actif
  Future<bool> hasActiveAdSubscription(String merchantId) async {
    try {
      final response = await _supabase
          .from('ad_subscriptions')
          .select('end_date, is_active')
          .eq('merchant_id', merchantId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return false;

      // Vérifier si l'abonnement n'a pas expiré
      if (response['end_date'] != null) {
        final endDate = DateTime.parse(response['end_date']);
        return DateTime.now().isBefore(endDate);
      }

      return true; // Abonnement permanent
    } catch (e) {
      print('Erreur lors de la vérification de l\'abonnement publicitaire: $e');
      return false;
    }
  }

  // Obtenir les informations de l'abonnement publicitaire actif
  Future<Map<String, dynamic>?> getActiveAdSubscription(String merchantId) async {
    try {
      final response = await _supabase
          .from('ad_subscriptions')
          .select('*')
          .eq('merchant_id', merchantId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      // Vérifier si l'abonnement n'a pas expiré
      if (response['end_date'] != null) {
        final endDate = DateTime.parse(response['end_date']);
        if (DateTime.now().isAfter(endDate)) {
          return null; // Abonnement expiré
        }
      }

      return response;
    } catch (e) {
      print('Erreur lors de la récupération de l\'abonnement publicitaire: $e');
      return null;
    }
  }

  // Désactiver un abonnement publicitaire
  Future<bool> deactivateAdSubscription(String merchantId) async {
    try {
      await _supabase
          .from('ad_subscriptions')
          .update({'is_active': false})
          .eq('merchant_id', merchantId)
          .eq('is_active', true);

      print('Abonnement publicitaire désactivé');
      return true;
    } catch (e) {
      print('Erreur lors de la désactivation de l\'abonnement publicitaire: $e');
      return false;
    }
  }
}


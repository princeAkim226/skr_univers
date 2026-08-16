import 'package:supabase_flutter/supabase_flutter.dart';
import 'ad_subscription_service.dart';

class AdService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AdSubscriptionService _adSubscriptionService = AdSubscriptionService();

  // Créer une publicité
  Future<Map<String, dynamic>?> createAd({
    required String merchantId,
    required String title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool isDefault = false, // Publicité par défaut (nécessite abonnement publicitaire)
  }) async {
    try {
      // Vérifier si l'e-commerçant a un abonnement publicitaire actif
      final hasAdSubscription = await _adSubscriptionService.hasActiveAdSubscription(merchantId);
      if (!hasAdSubscription) {
        throw Exception('Vous devez avoir un abonnement publicitaire actif pour créer des publicités. Prix: 25 000 FCFA/mois.');
      }

      // Les publicités par défaut nécessitent aussi un abonnement publicitaire actif
      // (toutes les publicités créées avec un abonnement actif peuvent être affichées par défaut)

      final response = await _supabase
          .from('ads')
          .insert({
            'merchant_id': merchantId,
            'title': title,
            'description': description,
            'image_url': imageUrl,
            'target_url': targetUrl,
            'start_date': (startDate ?? DateTime.now()).toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'is_active': true,
            'is_default': isDefault, // Publicité par défaut (nécessite abonnement publicitaire)
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('Erreur lors de la création de la publicité: $e');
      rethrow;
    }
  }

  // Obtenir toutes les publicités d'un e-commerçant
  Future<List<Map<String, dynamic>>> getMerchantAds(String merchantId) async {
    try {
      final response = await _supabase
          .from('ads')
          .select('*')
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des publicités: $e');
      return [];
    }
  }

  // Mettre à jour une publicité
  Future<bool> updateAd({
    required String adId,
    String? title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (targetUrl != null) updateData['target_url'] = targetUrl;
      if (isActive != null) updateData['is_active'] = isActive;
      if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();

      await _supabase
          .from('ads')
          .update(updateData)
          .eq('id', adId);

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la publicité: $e');
      return false;
    }
  }

  // Supprimer une publicité
  Future<bool> deleteAd(String adId) async {
    try {
      await _supabase
          .from('ads')
          .delete()
          .eq('id', adId);

      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la publicité: $e');
      return false;
    }
  }

  // Activer/Désactiver une publicité
  Future<bool> toggleAdStatus(String adId, bool isActive) async {
    try {
      await _supabase
          .from('ads')
          .update({'is_active': isActive})
          .eq('id', adId);

      return true;
    } catch (e) {
      print('Erreur lors du changement de statut de la publicité: $e');
      return false;
    }
  }

  // Obtenir les statistiques d'une publicité
  Future<Map<String, dynamic>> getAdStats(String adId) async {
    try {
      final response = await _supabase
          .from('ads')
          .select('view_count, click_count')
          .eq('id', adId)
          .single();

      return {
        'view_count': response['view_count'] ?? 0,
        'click_count': response['click_count'] ?? 0,
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {'view_count': 0, 'click_count': 0};
    }
  }

  // Obtenir les publicités par défaut à afficher sur la partie client
  Future<List<Map<String, dynamic>>> getDefaultAds() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('ads')
          .select('''
            *,
            merchant:merchants!ads_merchant_id_fkey(
              id,
              business_name,
              business_image
            )
          ''')
          .eq('is_default', true)
          .eq('is_active', true)
          .lte('start_date', now)
          .or('end_date.is.null,end_date.gte.$now')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des publicités par défaut: $e');
      try {
        final now = DateTime.now().toIso8601String();
        final response = await _supabase
            .from('ads')
            .select('*')
            .eq('is_default', true)
            .eq('is_active', true)
            .lte('start_date', now)
            .or('end_date.is.null,end_date.gte.$now')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }
}


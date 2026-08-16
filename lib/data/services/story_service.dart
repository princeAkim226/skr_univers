import 'package:supabase_flutter/supabase_flutter.dart';

class StoryService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createStory({
    required String title,
    String? description,
    required List<String> images,
    String? videoUrl,
    List<String> tags = const [],
    String? location,
    double? latitude,
    double? longitude,
    int durationHours = 24,
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
      throw Exception('Profil marchand non trouvé');
    }

    final now = DateTime.now();
    final expiresAt = now.add(Duration(hours: durationHours));

    final storyData = {
      'merchant_id': merchantId,
      'title': title,
      'description': description,
      'images': images,
      'video_url': videoUrl,
      'tags': tags,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'expires_at': expiresAt.toIso8601String(),
      'is_active': true,
      'view_count': 0,
    };

    final response = await _supabase
        .from('stories')
        .insert(storyData)
        .select()
        .single();
        
    return response;
  }

  Future<List<Map<String, dynamic>>> getActiveStories() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('stories')
          .select('*, merchant:merchant_id(business_name, business_image)')
          .eq('is_active', true)
          .gt('expires_at', now)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des stories: $e');
      throw Exception('Impossible de récupérer les stories: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStoriesByMerchant(String merchantId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('stories')
          .select('*, merchant:merchant_id(business_name, business_image)')
          .eq('merchant_id', merchantId)
          .eq('is_active', true)
          .gt('expires_at', now)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des stories du marchand: $e');
      throw Exception('Impossible de récupérer les stories de ce marchand: $e');
    }
  }

  Future<void> incrementViewCount(String storyId) async {
    try {
      await _supabase
          .from('stories')
          .update({'view_count': 'view_count + 1'})
          .eq('id', storyId);
    } catch (e) {
      print('Erreur lors de l\'incrémentation du compteur de vues: $e');
    }
  }

  Future<void> deleteStory(String storyId) async {
    try {
      await _supabase
          .from('stories')
          .update({'is_active': false})
          .eq('id', storyId);
    } catch (e) {
      print('Erreur lors de la suppression de la story: $e');
      throw Exception('Impossible de supprimer cette story: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyStories() async {
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
      
      // Récupérer les stories de ce marchand
      final response = await _supabase
          .from('stories')
          .select('*')
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération de mes stories: $e');
      throw Exception('Impossible de récupérer vos stories: $e');
    }
  }

  Future<Map<String, dynamic>> republishStory({
    required String storyId,
    int durationHours = 24,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // Vérifier que la story appartient au marchand connecté
      final merchantResponse = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id)
          .single();
      
      final merchantId = merchantResponse['id'] as String;
      
      // Vérifier que la story appartient à ce marchand
      final storyCheck = await _supabase
          .from('stories')
          .select('merchant_id')
          .eq('id', storyId)
          .single();
      
      if (storyCheck['merchant_id'] != merchantId) {
        throw Exception('Vous n\'avez pas la permission de republier cette story');
      }

      // Calculer la nouvelle date d'expiration
      final now = DateTime.now();
      final expiresAt = now.add(Duration(hours: durationHours));

      // Mettre à jour la story
      final response = await _supabase
          .from('stories')
          .update({
            'expires_at': expiresAt.toIso8601String(),
            'is_active': true,
            'view_count': 0, // Réinitialiser le compteur de vues
          })
          .eq('id', storyId)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Erreur lors de la republication de la story: $e');
      throw Exception('Impossible de republier cette story: $e');
    }
  }
}

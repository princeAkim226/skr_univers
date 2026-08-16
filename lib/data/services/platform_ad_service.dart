import 'package:supabase_flutter/supabase_flutter.dart';

/// Publicités du propriétaire de la plateforme (Business Place),
/// distinctes des publicités payantes des e-commerçants (`ads`).
class PlatformAdService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getActiveAds() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('platform_ads')
          .select('*')
          .eq('is_active', true)
          .lte('start_date', now)
          .or('end_date.is.null,end_date.gte.$now')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('PlatformAdService.getActiveAds: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllAdsForAdmin() async {
    final response = await _supabase
        .from('platform_ads')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createAd({
    required String title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    String placement = 'home_banner',
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final response = await _supabase
        .from('platform_ads')
        .insert({
          'title': title,
          'description': description,
          'image_url': imageUrl,
          'target_url': targetUrl,
          'placement': placement,
          'start_date': (startDate ?? DateTime.now()).toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'is_active': isActive,
          'created_by': userId,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(response);
  }

  Future<void> updateAd({
    required String id,
    String? title,
    String? description,
    String? imageUrl,
    String? targetUrl,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (targetUrl != null) data['target_url'] = targetUrl;
    if (isActive != null) data['is_active'] = isActive;
    if (startDate != null) data['start_date'] = startDate.toIso8601String();
    if (endDate != null) data['end_date'] = endDate.toIso8601String();

    await _supabase.from('platform_ads').update(data).eq('id', id);
  }

  Future<void> deleteAd(String id) async {
    await _supabase.from('platform_ads').delete().eq('id', id);
  }
}

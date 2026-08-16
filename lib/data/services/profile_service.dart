import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getCustomerProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final rows = await _supabase
        .from('customers')
        .select('*')
        .eq('user_id', user.id);

    if (rows is List && rows.isNotEmpty) {
      final profile = Map<String, dynamic>.from(rows.first as Map);
      // Enrichir avec email auth si absent
      profile['email'] ??= user.email;
      return profile;
    }

    // Fallback: créer un profil minimal à partir de Auth metadata
    final meta = user.userMetadata ?? {};
    final firstName = (meta['first_name'] ?? '').toString();
    final lastName = (meta['last_name'] ?? '').toString();
    final phone = (meta['phone_number'] ?? '').toString();
    final name = ('$firstName $lastName').trim().isEmpty
        ? 'Client B-Place'
        : ('$firstName $lastName').trim();

    try {
      final created = await _supabase
          .from('customers')
          .insert({
            'user_id': user.id,
            'name': name,
            'email': user.email,
            'phone': phone.isEmpty ? null : phone,
          })
          .select('*')
          .single();
      return Map<String, dynamic>.from(created);
    } catch (_) {
      return {
        'name': name,
        'email': user.email,
        'phone': phone,
        'address': null,
        'profile_image': null,
      };
    }
  }

  Future<Map<String, dynamic>?> getMerchantProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final rows = await _supabase
        .from('merchants')
        .select('*')
        .eq('user_id', user.id);

    if (rows is List && rows.isNotEmpty) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    return null;
  }

  Future<void> updateCustomerProfile({
    required String name,
    String? phone,
    String? address,
    String? profileImage,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final payload = <String, dynamic>{
      'name': name,
      'phone': phone,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (profileImage != null) {
      payload['profile_image'] = profileImage;
    }

    final existing = await _supabase
        .from('customers')
        .select('id')
        .eq('user_id', user.id);

    if (existing is List && existing.isNotEmpty) {
      await _supabase.from('customers').update(payload).eq('user_id', user.id);
    } else {
      await _supabase.from('customers').insert({
        'user_id': user.id,
        'email': user.email,
        ...payload,
      });
    }

    // Sync aussi users.profile_image si fourni
    if (profileImage != null) {
      try {
        await _supabase.from('users').update({
          'profile_image': profileImage,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      } catch (_) {}
    }
  }

  Future<void> updateMerchantProfile({
    required String businessName,
    String? businessDescription,
    String? businessPhone,
    String? businessAddress,
    String? businessImage,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _supabase.from('merchants').update({
      'business_name': businessName,
      'business_description': businessDescription,
      'business_phone': businessPhone,
      'business_address': businessAddress,
      'business_image': businessImage,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);
  }

  Future<void> createCustomerProfile({
    required String name,
    required String email,
    String? phone,
    String? address,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _supabase.from('customers').insert({
      'user_id': user.id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
    });
  }

  Future<void> createMerchantProfile({
    required String businessName,
    String? businessDescription,
    String? businessPhone,
    String? businessAddress,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    await _supabase.from('merchants').insert({
      'user_id': user.id,
      'business_name': businessName,
      'business_description': businessDescription,
      'business_phone': businessPhone,
      'business_address': businessAddress,
    });
  }

  Future<bool> profileExists() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final rows = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id);
      if (rows is List && rows.isNotEmpty) return true;
    } catch (_) {}

    try {
      final rows = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id);
      if (rows is List && rows.isNotEmpty) return true;
    } catch (_) {}
    return false;
  }

  Future<String?> getUserType() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final rows = await _supabase
          .from('customers')
          .select('id')
          .eq('user_id', user.id);
      if (rows is List && rows.isNotEmpty) return 'customer';
    } catch (_) {}

    try {
      final rows = await _supabase
          .from('merchants')
          .select('id')
          .eq('user_id', user.id);
      if (rows is List && rows.isNotEmpty) return 'merchant';
    } catch (_) {}
    return null;
  }

  /// Upload photo de profil (galeri/camera) + sauvegarde en base.
  Future<String> uploadProfileImageFromXFile(XFile imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Image invalide');
    }

    final nameLower = imageFile.name.toLowerCase();
    final ext = nameLower.endsWith('.png')
        ? 'png'
        : nameLower.endsWith('.webp')
            ? 'webp'
            : 'jpg';

    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage.from('profile-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );

    final publicUrl =
        _supabase.storage.from('profile-images').getPublicUrl(fileName);

    final existing = await _supabase
        .from('customers')
        .select('id, name')
        .eq('user_id', user.id);

    if (existing is List && existing.isNotEmpty) {
      await _supabase.from('customers').update({
        'profile_image': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', user.id);
    } else {
      final meta = user.userMetadata ?? {};
      final displayName =
          '${meta['first_name'] ?? ''} ${meta['last_name'] ?? ''}'.trim();
      await _supabase.from('customers').insert({
        'user_id': user.id,
        'name': displayName.isEmpty ? 'Client B-Place' : displayName,
        'email': user.email,
        'profile_image': publicUrl,
      });
    }

    try {
      await _supabase.from('users').update({
        'profile_image': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (_) {}

    return publicUrl;
  }

  Future<String> uploadBusinessImageFromXFile(XFile imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) throw Exception('Image invalide');

    final nameLower = imageFile.name.toLowerCase();
    final ext = nameLower.endsWith('.png')
        ? 'png'
        : nameLower.endsWith('.webp')
            ? 'webp'
            : 'jpg';
    final fileName =
        'business_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage.from('profile-images').uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
        );

    final publicUrl =
        _supabase.storage.from('profile-images').getPublicUrl(fileName);

    await _supabase.from('merchants').update({
      'business_image': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', user.id);

    return publicUrl;
  }

  @Deprecated('Utiliser uploadProfileImageFromXFile')
  Future<String> uploadProfileImage(String imagePath) async {
    return uploadProfileImageFromXFile(XFile(imagePath));
  }
}

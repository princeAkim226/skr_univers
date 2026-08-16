import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_models;

class SimpleAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Normaliser le numéro de téléphone
  String _normalizePhoneNumber(String phone) {
    // Supprimer tous les caractères non numériques
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si le numéro commence par 226, le garder tel quel
    if (cleaned.startsWith('226')) {
      return cleaned;
    }
    
    // Si le numéro commence par 0, remplacer par 226
    if (cleaned.startsWith('0')) {
      return '226${cleaned.substring(1)}';
    }
    
    // Si le numéro fait 8 chiffres, ajouter 226
    if (cleaned.length == 8) {
      return '226$cleaned';
    }
    
    return cleaned;
  }

  // Valider le format du numéro de téléphone
  bool isValidPhoneNumber(String phone) {
    final normalized = _normalizePhoneNumber(phone);
    return normalized.length >= 10 && normalized.startsWith('226');
  }

  /// Vérifie si une chaîne ressemble à un email valide
  bool _isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return RegExp(r'^[\w+.=-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim());
  }

  // Inscription client : email optionnel (téléphone obligatoire)
  Future<AuthResponse> signUpCustomer({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
  }) async {
    print('SimpleAuthService: Inscription client avec téléphone: $phoneNumber');
    
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      // Email optionnel : si fourni et valide, on l'utilise ; sinon email technique pour l'auth
      final emailForAuth = (email != null && _isValidEmail(email))
          ? email.trim()
          : 'user+$normalizedPhone@gmail.com';
      final emailToStore = (email != null && _isValidEmail(email)) ? email.trim() : null;
      
      // Inscription avec Supabase Auth
      final response = await _supabase.auth.signUp(
        email: emailForAuth,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': normalizedPhone,
          'user_type': 'customer',
        },
      );

      if (response.user != null) {
        print('SimpleAuthService: Utilisateur créé, ajout dans la table users...');
        print('SimpleAuthService: Numéro normalisé pour insertion: $normalizedPhone');
        
        // Ajouter dans la table users
        final insertResult = await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': emailToStore,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': normalizedPhone,
          'user_type': 'customer',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        // Créer aussi le profil dans la table customers
        await _supabase.from('customers').insert({
          'user_id': response.user!.id,
          'name': '$firstName $lastName',
          'email': emailToStore,
          'phone': normalizedPhone,
          'address': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('SimpleAuthService: Résultat insertion: $insertResult');
        print('SimpleAuthService: Profil client créé avec succès');
      }
      
      return response;
    } catch (e) {
      print('SimpleAuthService: Erreur inscription client: $e');
      rethrow;
    }
  }

  // Inscription e-commerçant : email optionnel (téléphone obligatoire)
  Future<AuthResponse> signUpMerchant({
    required String phoneNumber,
    required String password,
    required String firstName,
    required String lastName,
    required String businessName,
    required String businessDescription,
    required String businessAddress,
    required String businessPhone,
    String? email,
  }) async {
    print('SimpleAuthService: Inscription e-commerçant avec téléphone: $phoneNumber');
    
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      final emailForAuth = (email != null && _isValidEmail(email))
          ? email.trim()
          : 'user+$normalizedPhone@gmail.com';
      final emailToStore = (email != null && _isValidEmail(email)) ? email.trim() : null;
      
      // Inscription avec Supabase Auth
      final response = await _supabase.auth.signUp(
        email: emailForAuth,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': normalizedPhone,
          'user_type': 'merchant',
          'business_name': businessName,
        },
      );

      if (response.user != null) {
        print('SimpleAuthService: Utilisateur créé, ajout dans la table users...');
        
        // Ajouter dans la table users
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': emailToStore,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': normalizedPhone,
          'user_type': 'merchant',
          'business_name': businessName,
          'business_description': businessDescription,
          'business_address': businessAddress,
          'business_phone': businessPhone,
          'business_email': emailToStore,
          'is_verified': false,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        // Créer aussi le profil dans la table merchants
        await _supabase.from('merchants').insert({
          'user_id': response.user!.id,
          'business_name': businessName,
          'business_description': businessDescription,
          'business_phone': businessPhone,
          'business_address': businessAddress,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('SimpleAuthService: Profil e-commerçant créé avec succès');
      }
      
      return response;
    } catch (e) {
      print('SimpleAuthService: Erreur inscription e-commerçant: $e');
      rethrow;
    }
  }

  // Connexion avec numéro de téléphone
  Future<AuthResponse> signIn({
    required String phoneNumber,
    required String password,
  }) async {
    print('SimpleAuthService: Connexion avec téléphone: $phoneNumber');
    
    try {
      final normalizedPhone = _normalizePhoneNumber(phoneNumber);
      print('SimpleAuthService: Numéro normalisé: $normalizedPhone');
      
      // Chercher l'utilisateur dans la table users avec différents formats
      // Utiliser .select() au lieu de .maybeSingle() pour gérer les doublons
      var usersResponse = await _supabase
          .from('users')
          .select('*')
          .eq('phone_number', normalizedPhone);
      
      print('SimpleAuthService: Résultat de la recherche normalisé: $usersResponse');
      
      if (usersResponse.isEmpty) {
        // Essayer avec le numéro original
        usersResponse = await _supabase
            .from('users')
            .select('*')
            .eq('phone_number', phoneNumber);
        
        print('SimpleAuthService: Recherche avec numéro original: $usersResponse');
      }
      
      if (usersResponse.isEmpty) {
        // Essayer avec le format +226
        final phoneWithPlus = '+$normalizedPhone';
        usersResponse = await _supabase
            .from('users')
            .select('*')
            .eq('phone_number', phoneWithPlus);
        
        print('SimpleAuthService: Recherche avec +226: $usersResponse');
      }
      
      if (usersResponse.isEmpty) {
        // Essayer avec le format 0X
        final phoneWithZero = '0${phoneNumber.replaceAll(RegExp(r'[^\d]'), '').substring(3)}';
        usersResponse = await _supabase
            .from('users')
            .select('*')
            .eq('phone_number', phoneWithZero);
        
        print('SimpleAuthService: Recherche avec 0X: $usersResponse');
      }
      
      // Prendre le premier utilisateur trouvé (le plus récent si trié)
      var userResponse = usersResponse.isNotEmpty ? usersResponse.first : null;
      String emailToUse;
      
      if (userResponse != null) {
        // Utiliser l'email de l'utilisateur trouvé pour la connexion Supabase Auth
        if (userResponse['email'] != null && userResponse['email'].toString().isNotEmpty) {
          emailToUse = userResponse['email'].toString();
          print('SimpleAuthService: Utilisation de l\'email réel: $emailToUse');
        } else {
          emailToUse = 'user+$normalizedPhone@gmail.com';
          print('SimpleAuthService: Utilisation de l\'email temporaire: $emailToUse');
        }
      } else {
        // Aucune ligne dans users : tenter quand même avec l'email technique
        // (compte créé dans Auth mais insertion users/customers a échoué)
        emailToUse = 'user+$normalizedPhone@gmail.com';
        print('SimpleAuthService: Aucun profil en base, tentative avec email technique: $emailToUse');
      }
      
      // Connexion avec Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Mot de passe incorrect');
      }
      
      // Si on a réussi sans avoir trouvé de ligne dans users, créer le profil si possible
      if (userResponse == null && response.user != null) {
        try {
          final uid = response.user!.id;
          final meta = response.user!.userMetadata ?? {};
          final firstName = (meta['first_name'] ?? 'Utilisateur').toString();
          final lastName = (meta['last_name'] ?? '').toString();
          await _supabase.from('users').upsert({
            'id': uid,
            'email': response.user!.email,
            'first_name': firstName,
            'last_name': lastName,
            'phone_number': normalizedPhone,
            'user_type': meta['user_type'] ?? 'customer',
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
          await _supabase.from('customers').insert({
            'user_id': uid,
            'name': '$firstName $lastName'.trim(),
            'email': response.user!.email,
            'phone': normalizedPhone,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {
          // Ignorer si tables absentes, RLS ou doublon
        }
      }
      
      print('SimpleAuthService: Connexion réussie');
      return response;
    } catch (e) {
      print('SimpleAuthService: Erreur connexion: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Mot de passe oublié via téléphone (résolution email technique / réel)
  Future<void> resetPasswordByPhone(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final rows = await _supabase
        .from('users')
        .select('email, phone_number')
        .eq('phone_number', normalizedPhone);

    var email = rows.isNotEmpty ? rows.first['email']?.toString() : null;
    if (email == null || email.isEmpty) {
      // fallback formats
      final alt = await _supabase
          .from('users')
          .select('email')
          .eq('phone_number', phoneNumber);
      if (alt.isNotEmpty) {
        email = alt.first['email']?.toString();
      }
    }

    email ??= 'user+$normalizedPhone@gmail.com';

    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Obtenir le type d'utilisateur
  String? get userType {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user.userMetadata?['user_type'] as String?;
  }

  // Obtenir l'utilisateur actuel
  app_models.User? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    // Récupérer les données complètes depuis la table users
    // Cette méthode sera appelée de manière asynchrone dans l'UI
    return null;
  }

  // Récupérer le profil utilisateur complet
  Future<app_models.User?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response.isNotEmpty) {
        return app_models.User(
          id: response['id'],
          email: response['email'],
          firstName: response['first_name'],
          lastName: response['last_name'],
          phoneNumber: response['phone_number'],
          userType: response['user_type'],
          profileImage: response['profile_image'],
          createdAt: DateTime.parse(response['created_at']),
          updatedAt: DateTime.parse(response['updated_at']),
          isActive: response['is_active'],
          businessName: response['business_name'],
          businessDescription: response['business_description'],
          businessAddress: response['business_address'],
          businessPhone: response['business_phone'],
          businessEmail: response['business_email'],
          isVerified: response['is_verified'],
        );
      }
    } catch (e) {
      print('SimpleAuthService: Erreur récupération profil: $e');
    }
    return null;
  }
}

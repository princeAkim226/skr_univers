import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_models;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtenir l'utilisateur actuel
  app_models.User? get currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    // Ici vous devrez récupérer les données complètes de l'utilisateur depuis votre table
    // Pour l'instant, retournons null
    return null;
  }

  // Inscription d'un client
  Future<AuthResponse> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    print('AuthService: Tentative d\'inscription client avec email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'user_type': 'customer',
        },
      );
      print('AuthService: Réponse Supabase Auth (client): $response');

      if (response.user != null) {
        print('AuthService: Utilisateur authentifié, création du profil dans la table users...');
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email.startsWith('temp_') && email.endsWith('@gmail.com') ? null : email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'user_type': 'customer',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('AuthService: Profil client créé dans la table users.');
      } else {
        print('AuthService: response.user est null après signUp (client).');
      }
      return response;
    } catch (e) {
      print('AuthService: Erreur dans signUpCustomer: $e');
      rethrow; // Propage l'erreur pour qu'elle soit gérée par la page d'inscription
    }
  }

  // Inscription d'un e-commerçant
  Future<AuthResponse> signUpMerchant({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String businessName,
    required String businessDescription,
    required String businessAddress,
    required String businessPhone,
    String? phoneNumber,
  }) async {
    print('AuthService: Tentative d\'inscription e-commerçant avec email: $email');
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'user_type': 'merchant',
          'business_name': businessName,
        },
      );
      print('AuthService: Réponse Supabase Auth (e-commerçant): $response');

      if (response.user != null) {
        print('AuthService: Utilisateur authentifié, création du profil e-commerçant dans la table users...');
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone_number': phoneNumber,
          'user_type': 'merchant',
          'business_name': businessName,
          'business_description': businessDescription,
          'business_address': businessAddress,
          'business_phone': businessPhone,
          'business_email': email,
          'is_verified': false,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('AuthService: Profil e-commerçant créé dans la table users.');
      } else {
        print('AuthService: response.user est null après signUp (e-commerçant).');
      }
      return response;
    } catch (e) {
      print('AuthService: Erreur dans signUpMerchant: $e');
      rethrow;
    }
  }

  // Connexion
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('AuthService: Tentative de connexion avec email: $email');
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('AuthService: Réponse Supabase Auth (signIn): $response');

      if (response.user == null) {
        print('AuthService: response.user est null après signIn.');
      }
      return response;
    } catch (e) {
      print('AuthService: Erreur dans signIn: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _supabase.auth.signOut();
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
      print('Erreur lors de la récupération du profil: $e');
    }
    return null;
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _supabase
        .from('users')
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Obtenir le type d'utilisateur
  String? get userType {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return user.userMetadata?['user_type'] as String?;
  }

  // Vérifier si l'utilisateur courant est administrateur
  Future<bool> isCurrentUserAdmin() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase
          .from('users')
          .select('is_admin, user_type')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Fallback metadata si profil users absent temporairement
        return (user.userMetadata?['user_type'] as String?) == 'admin';
      }

      final isAdminFlag = response['is_admin'] == true;
      final isAdminType = (response['user_type']?.toString().toLowerCase() == 'admin');
      return isAdminFlag || isAdminType;
    } catch (e) {
      print('AuthService: Erreur vérification admin: $e');
      return false;
    }
  }
} 
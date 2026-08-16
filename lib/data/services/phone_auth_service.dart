import 'package:supabase_flutter/supabase_flutter.dart';

class PhoneAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Exposer le client Supabase pour les requêtes personnalisées
  SupabaseClient get supabase => _supabase;

  // Envoyer un code OTP par SMS
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
  }) async {
    try {
      // Pour la démo, on simule l'envoi d'OTP
      // En production, vous devrez intégrer un service SMS comme Twilio, AWS SNS, etc.
      
      print('Envoi d\'OTP vers: $phoneNumber');
      
      // Simulation d'un délai d'envoi
      await Future.delayed(const Duration(seconds: 2));
      
      // Pour la démo, on génère un code fixe
      // En production, générez un code aléatoire et stockez-le temporairement
      const demoOTP = '123456';
      
      return {
        'success': true,
        'message': 'Code OTP envoyé avec succès',
        'otp': demoOTP, // En production, ne pas retourner l'OTP
        'expires_in': 300, // 5 minutes
      };
    } catch (e) {
      print('Erreur lors de l\'envoi d\'OTP: $e');
      return {
        'success': false,
        'error': 'Erreur lors de l\'envoi du code OTP: $e',
      };
    }
  }

  // Vérifier le code OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      // Pour la démo, on accepte le code 123456
      // En production, vérifiez le code contre celui stocké
      
      if (otp == '123456') {
        // Rechercher l'utilisateur par numéro de téléphone
        final userResponse = await _supabase
            .from('merchants')
            .select('*')
            .eq('phone_number', phoneNumber)
            .single();
        
        if (userResponse.isNotEmpty) {
          return {
            'success': true,
            'message': 'Code OTP vérifié avec succès',
            'user': userResponse,
            'user_type': 'merchant',
          };
        }
        
        // Si pas trouvé dans merchants, chercher dans customers
        final customerResponse = await _supabase
            .from('customers')
            .select('*')
            .eq('phone_number', phoneNumber)
            .single();
        
        if (customerResponse.isNotEmpty) {
          return {
            'success': true,
            'message': 'Code OTP vérifié avec succès',
            'user': customerResponse,
            'user_type': 'customer',
          };
        }
        
        return {
          'success': false,
          'error': 'Aucun compte trouvé avec ce numéro de téléphone',
        };
      } else {
        return {
          'success': false,
          'error': 'Code OTP incorrect',
        };
      }
    } catch (e) {
      print('Erreur lors de la vérification d\'OTP: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la vérification du code OTP: $e',
      };
    }
  }

  // Connexion par numéro de téléphone
  Future<Map<String, dynamic>> signInWithPhone({
    required String phoneNumber,
  }) async {
    try {
      // D'abord, envoyer l'OTP
      final otpResponse = await sendOTP(phoneNumber: phoneNumber);
      
      if (otpResponse['success'] == true) {
        return {
          'success': true,
          'message': 'Code OTP envoyé. Veuillez le saisir pour vous connecter.',
          'phone_number': phoneNumber,
          'otp_sent': true,
        };
      } else {
        return otpResponse;
      }
    } catch (e) {
      print('Erreur lors de la connexion par téléphone: $e');
      return {
        'success': false,
        'error': 'Erreur lors de la connexion par téléphone: $e',
      };
    }
  }

  // Formater le numéro de téléphone
  String formatPhoneNumber(String phoneNumber) {
    // Supprimer tous les caractères non numériques
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si le numéro commence par 226, le garder
    if (cleaned.startsWith('226')) {
      return '+$cleaned';
    }
    
    // Si le numéro commence par 0, remplacer par +226
    if (cleaned.startsWith('0')) {
      return '+226${cleaned.substring(1)}';
    }
    
    // Si le numéro ne commence pas par 226, l'ajouter
    if (!cleaned.startsWith('226')) {
      return '+226$cleaned';
    }
    
    return '+$cleaned';
  }

  // Valider le format du numéro de téléphone
  bool isValidPhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Numéro burkinabé: 226 + 8 chiffres
    if (cleaned.startsWith('226') && cleaned.length == 11) {
      return true;
    }
    
    // Numéro commençant par 0 + 8 chiffres
    if (cleaned.startsWith('0') && cleaned.length == 9) {
      return true;
    }
    
    // Numéro de 8 chiffres
    if (cleaned.length == 8) {
      return true;
    }
    
    return false;
  }
}

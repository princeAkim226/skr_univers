import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/subscription_plans.dart';
import 'messaging_service.dart';

class SubscriptionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final MessagingService _messagingService = MessagingService();

  // S'abonner à un e-commerçant (gratuit pour le client)
  Future<bool> subscribeToMerchant({
    required String customerId,
    required String merchantId,
  }) async {
    try {
      // Créer l'abonnement
      await _supabase
          .from('customer_subscriptions')
          .insert({
            'customer_id': customerId,
            'merchant_id': merchantId,
          });

      // Créer automatiquement une conversation pour permettre la messagerie
      try {
        await _messagingService.getOrCreateConversation(
          customerId: customerId,
          merchantId: merchantId,
        );
        print('Conversation créée automatiquement');
      } catch (e) {
        print('Erreur lors de la création de la conversation: $e');
        // Ne pas faire échouer l'abonnement si la conversation ne peut pas être créée
      }

      print('Abonnement réussi');
      return true;
    } catch (e) {
      print('Erreur lors de l\'abonnement: $e');
      return false;
    }
  }

  // Se désabonner d'un e-commerçant
  Future<bool> unsubscribeFromMerchant({
    required String customerId,
    required String merchantId,
  }) async {
    try {
      await _supabase
          .from('customer_subscriptions')
          .delete()
          .eq('customer_id', customerId)
          .eq('merchant_id', merchantId);

      print('Désabonnement réussi');
      return true;
    } catch (e) {
      print('Erreur lors du désabonnement: $e');
      return false;
    }
  }

  // Vérifier si un client est abonné à un e-commerçant
  Future<bool> isSubscribed({
    required String customerId,
    required String merchantId,
  }) async {
    try {
      final response = await _supabase
          .from('customer_subscriptions')
          .select('id')
          .eq('customer_id', customerId)
          .eq('merchant_id', merchantId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Erreur lors de la vérification de l\'abonnement: $e');
      return false;
    }
  }

  // Obtenir les e-commerçants auxquels un client est abonné
  Future<List<Map<String, dynamic>>> getSubscribedMerchants(String customerId) async {
    try {
      final response = await _supabase
          .from('customer_subscriptions')
          .select('''
            merchant_id,
            created_at,
            merchant:users!customer_subscriptions_merchant_id_fkey(
              id,
              first_name,
              last_name,
              business_name,
              business_description,
              profile_image,
              phone_number
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des abonnements: $e');
      return [];
    }
  }

  // Obtenir les clients abonnés à un e-commerçant
  Future<List<Map<String, dynamic>>> getSubscribers(String merchantId) async {
    try {
      final response = await _supabase
          .from('customer_subscriptions')
          .select('''
            customer_id,
            created_at,
            customer:users!customer_subscriptions_customer_id_fkey(
              id,
              first_name,
              last_name,
              phone_number,
              profile_image
            )
          ''')
          .eq('merchant_id', merchantId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des abonnés: $e');
      return [];
    }
  }

  // Obtenir tous les e-commerçants disponibles pour l'abonnement (pour la messagerie, tous les marchands sont disponibles)
  Future<List<Map<String, dynamic>>> getAvailableMerchants() async {
    try {
      print('🔍 Recherche des e-commerçants disponibles...');
      
      // Essayer d'abord avec la table users
      try {
        // Récupérer tous les marchands (sans filtre is_active pour la messagerie)
        final merchants = await _supabase
            .from('users')
            .select('''
              id,
              first_name,
              last_name,
              business_name,
              business_description,
              profile_image,
              phone_number,
              created_at
            ''')
            .eq('user_type', 'merchant')
            .order('created_at', ascending: false);

        print('✅ ${merchants.length} e-commerçants trouvés dans users');
        final merchantsList = List<Map<String, dynamic>>.from(merchants);
        
        if (merchantsList.isEmpty) {
          // Si aucun dans users, essayer de récupérer depuis merchants
          print('⚠️ Aucun marchand dans users, recherche dans merchants...');
          try {
            final merchantsFromTable = await _supabase
                .from('merchants')
                .select('''
                  user_id,
                  business_name,
                  business_description,
                  business_image,
                  created_at
                ''')
                .order('created_at', ascending: false);
            
            print('✅ ${merchantsFromTable.length} e-commerçants trouvés dans merchants');
            
            final convertedMerchants = <Map<String, dynamic>>[];
            for (final merchant in merchantsFromTable) {
              final userId = merchant['user_id'] as String?;
              if (userId != null) {
                // Essayer de récupérer les infos utilisateur
                try {
                  final userInfo = await _supabase
                      .from('users')
                      .select('first_name, last_name, phone_number, profile_image')
                      .eq('id', userId)
                      .maybeSingle();
                  
                  convertedMerchants.add({
                    'id': userId,
                    'first_name': userInfo?['first_name'] ?? '',
                    'last_name': userInfo?['last_name'] ?? '',
                    'business_name': merchant['business_name'] ?? 'E-commerçant',
                    'business_description': merchant['business_description'],
                    'profile_image': merchant['business_image'] ?? userInfo?['profile_image'],
                    'phone_number': userInfo?['phone_number'] ?? '',
                    'created_at': merchant['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                  });
                } catch (e) {
                  // Si on ne peut pas récupérer les infos user, utiliser juste les données merchant
                  convertedMerchants.add({
                    'id': userId,
                    'first_name': '',
                    'last_name': '',
                    'business_name': merchant['business_name'] ?? 'E-commerçant',
                    'business_description': merchant['business_description'],
                    'profile_image': merchant['business_image'],
                    'phone_number': '',
                    'created_at': merchant['created_at']?.toString() ?? DateTime.now().toIso8601String(),
                  });
                }
              }
            }
            
            if (convertedMerchants.isNotEmpty) {
              merchantsList.addAll(convertedMerchants);
              print('✅ ${convertedMerchants.length} e-commerçants convertis depuis merchants');
            }
          } catch (e) {
            print('❌ Erreur lors de la récupération depuis merchants: $e');
          }
        }
        
        // Pour la messagerie, on inclut TOUS les marchands (même ceux avec le plan Simple)
        // Récupérer tous les plans en une seule requête pour optimiser
        final merchantsWithPlan = <Map<String, dynamic>>[];
        
        if (merchantsList.isNotEmpty) {
          try {
            // Récupérer tous les plans actifs en une seule requête (sans filtre pour optimiser)
            final merchantIds = merchantsList.map((m) => m['id'] as String).toSet().toList();
            final allActivePlans = await _supabase
                .from('merchant_plans')
                .select('merchant_id, plan_type, end_date, is_active')
                .eq('is_active', true);
            
            // Créer un map pour accès rapide (filtrer côté client)
            final planMap = <String, String>{};
            final now = DateTime.now();
            
            for (final plan in allActivePlans) {
              final merchantId = plan['merchant_id'] as String;
              // Ne traiter que les marchands de notre liste
              if (!merchantIds.contains(merchantId)) continue;
              
              final endDate = plan['end_date'] != null 
                  ? DateTime.parse(plan['end_date']) 
                  : null;
              
              // Vérifier si le plan n'a pas expiré
              if (endDate == null || now.isBefore(endDate)) {
                planMap[merchantId] = plan['plan_type'] as String? ?? SubscriptionPlans.simple;
              }
            }
            
            // Assigner les plans aux marchands
            for (final merchant in merchantsList) {
              final merchantId = merchant['id'] as String;
              merchant['subscription_plan'] = planMap[merchantId] ?? SubscriptionPlans.simple;
              merchantsWithPlan.add(merchant);
            }
          } catch (e) {
            print('⚠️ Erreur lors de la récupération des plans: $e');
            // En cas d'erreur, assigner le plan simple par défaut à tous
            for (final merchant in merchantsList) {
              merchant['subscription_plan'] = SubscriptionPlans.simple;
              merchantsWithPlan.add(merchant);
            }
          }
        }

        // Trier par plan (Premium en premier, puis Pro, puis Simple)
        merchantsWithPlan.sort((a, b) {
          final planA = a['subscription_plan'] as String? ?? SubscriptionPlans.simple;
          final planB = b['subscription_plan'] as String? ?? SubscriptionPlans.simple;
          
          if (planA == SubscriptionPlans.premium && planB != SubscriptionPlans.premium) return -1;
          if (planA != SubscriptionPlans.premium && planB == SubscriptionPlans.premium) return 1;
          if (planA == SubscriptionPlans.pro && planB == SubscriptionPlans.simple) return -1;
          if (planA == SubscriptionPlans.simple && planB == SubscriptionPlans.pro) return 1;
          return 0;
        });

        print('✅ ${merchantsWithPlan.length} e-commerçants disponibles retournés');
        return merchantsWithPlan;
      } catch (usersError) {
        print('❌ Erreur avec la table users: $usersError');
        // Essayer avec la table merchants directement
        try {
          final merchants = await _supabase
              .from('merchants')
              .select('''
                user_id,
                business_name,
                business_description,
                business_image
              ''')
              .order('created_at', ascending: false);
          
          final convertedMerchants = <Map<String, dynamic>>[];
          for (final merchant in merchants) {
            convertedMerchants.add({
              'id': merchant['user_id'],
              'first_name': '',
              'last_name': '',
              'business_name': merchant['business_name'] ?? '',
              'business_description': merchant['business_description'],
              'profile_image': merchant['business_image'],
              'phone_number': '',
              'created_at': DateTime.now().toIso8601String(),
              'subscription_plan': SubscriptionPlans.simple,
            });
          }
          
          print('✅ ${convertedMerchants.length} e-commerçants récupérés depuis merchants');
          return convertedMerchants;
        } catch (merchantsError) {
          print('❌ Erreur avec la table merchants: $merchantsError');
          return [];
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des e-commerçants: $e');
      return [];
    }
  }

  // Activer ou mettre à jour un plan d'abonnement pour un e-commerçant
  Future<bool> activatePlan({
    required String merchantId,
    required String planType, // 'simple', 'pro', ou 'premium'
    required double price,
    String? currency, // 'FCFA' ou 'USD'
  }) async {
    try {
      // Utiliser la durée définie dans les constantes
      final durationInDays = SubscriptionPlans.getDurationInDays(planType);
      final endDate = DateTime.now().add(Duration(days: durationInDays));
      
      // Mettre à jour la table merchant_plans
      await _supabase
          .from('merchant_plans')
          .upsert({
            'merchant_id': merchantId,
            'plan_type': planType,
            'is_plus': planType != SubscriptionPlans.simple, // Pro et Premium sont considérés comme "plus"
            'price': price,
            'currency': currency ?? SubscriptionPlans.getCurrency(planType),
            'end_date': endDate.toIso8601String(),
            'is_active': true,
          });

      // Mettre à jour la table merchants si nécessaire
      if (planType != SubscriptionPlans.simple) {
        await _supabase
            .from('merchants')
            .update({
              'has_plus_subscription': true,
              'plus_subscription_expires_at': endDate.toIso8601String(),
            })
            .eq('user_id', merchantId);
      }

      print('Plan $planType activé avec succès');
      return true;
    } catch (e) {
      print('Erreur lors de l\'activation du plan: $e');
      return false;
    }
  }

  // Activer l'abonnement plus pour un e-commerçant (méthode de compatibilité)
  Future<bool> activatePlusSubscription({
    required String merchantId,
    required double price,
    required int durationInDays,
  }) async {
    // Par défaut, activer le plan Pro
    return activatePlan(
      merchantId: merchantId,
      planType: SubscriptionPlans.pro,
      price: price,
      currency: 'FCFA',
    );
  }

  // Obtenir le plan actif d'un e-commerçant
  Future<String?> getActivePlan(String merchantId) async {
    try {
      final response = await _supabase
          .from('merchant_plans')
          .select('plan_type, end_date, is_active')
          .eq('merchant_id', merchantId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return SubscriptionPlans.simple; // Plan par défaut

      // Vérifier si l'abonnement n'a pas expiré
      if (response['end_date'] != null) {
        final endDate = DateTime.parse(response['end_date']);
        if (DateTime.now().isAfter(endDate)) {
          return SubscriptionPlans.simple; // Plan expiré, retour au simple
        }
      }

      return response['plan_type'] as String? ?? SubscriptionPlans.simple;
    } catch (e) {
      print('Erreur lors de la récupération du plan: $e');
      return SubscriptionPlans.simple;
    }
  }

  // Vérifier si un e-commerçant a un abonnement plus actif (méthode de compatibilité)
  Future<bool> hasActivePlusSubscription(String merchantId) async {
    final plan = await getActivePlan(merchantId);
    return plan == SubscriptionPlans.pro || plan == SubscriptionPlans.premium;
  }

  // Vérifier si un e-commerçant peut apparaître dans la liste
  Future<bool> canAppearInMerchantList(String merchantId) async {
    final plan = await getActivePlan(merchantId);
    return SubscriptionPlans.canAppearInMerchantList(plan ?? SubscriptionPlans.simple);
  }

  // Obtenir les e-commerçants avec abonnement plus (pour les stories)
  Future<List<Map<String, dynamic>>> getMerchantsWithPlusSubscription() async {
    try {
      final response = await _supabase
          .from('merchant_plans')
          .select('''
            merchant_id,
            plan_type,
            price,
            end_date,
            merchant:users!merchant_plans_merchant_id_fkey(
              id,
              first_name,
              last_name,
              business_name,
              business_description,
              profile_image,
              phone_number
            )
          ''')
          .eq('is_plus', true)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur lors de la récupération des e-commerçants avec abonnement plus: $e');
      return [];
    }
  }

  // Obtenir les statistiques d'abonnement pour un e-commerçant
  Future<Map<String, dynamic>> getSubscriptionStats(String merchantId) async {
    try {
      // Nombre d'abonnés
      final subscribersList = await _supabase
          .from('customer_subscriptions')
          .select('id')
          .eq('merchant_id', merchantId);

      // Obtenir le plan actif
      final plan = await getActivePlan(merchantId);
      final hasPlus = await hasActivePlusSubscription(merchantId);

      return {
        'subscribers_count': subscribersList.length,
        'has_plus_subscription': hasPlus,
        'current_plan': plan ?? SubscriptionPlans.simple,
        'can_appear_in_list': await canAppearInMerchantList(merchantId),
      };
    } catch (e) {
      print('Erreur lors de la récupération des statistiques: $e');
      return {
        'subscribers_count': 0,
        'has_plus_subscription': false,
        'current_plan': SubscriptionPlans.simple,
        'can_appear_in_list': false,
      };
    }
  }
}

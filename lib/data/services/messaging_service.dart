import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationCreateResult {
  final String? conversationId;
  final bool isNewConversation;

  const ConversationCreateResult({
    required this.conversationId,
    required this.isNewConversation,
  });
}

class MessagingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // `products.merchant_id` correspond généralement à l'ID du profil dans `merchants`,
  // alors que `conversations.merchant_id` et `messages.receiver_id` réfèrent à `users(id)`.
  // Cette méthode normalise donc `merchantId` -> `merchants.user_id` si besoin.
  Future<String> _resolveMerchantUserId(String merchantId) async {
    try {
      final resp = await _supabase
          .from('merchants')
          .select('user_id')
          .eq('id', merchantId)
          .maybeSingle();

      final userId = resp?['user_id'];
      if (userId != null) return userId.toString();
    } catch (_) {
      // Si ça ne matche pas `merchants.id`, on garde l'ID original.
    }
    return merchantId;
  }

  // Obtenir les conversations d'un utilisateur
  Future<List<Map<String, dynamic>>> getConversations(String userId, String userType) async {
    try {
      // Essayer d'abord avec les vues, sinon utiliser des requêtes directes
      try {
        String tableName;
        if (userType == 'customer') {
          tableName = 'customer_conversations';
        } else {
          tableName = 'merchant_conversations';
        }

        final response = await _supabase
            .from(tableName)
            .select('*')
            .eq(userType == 'customer' ? 'customer_id' : 'merchant_id', userId)
            .order('last_message_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (viewError) {
        print('Vues non disponibles, utilisation de requêtes directes: $viewError');
        
        // Requête directe pour les clients
        if (userType == 'customer') {
          final response = await _supabase
              .from('conversations')
              .select('''
                id,
                customer_id,
                merchant_id,
                last_message_at,
                last_message_content,
                customer_unread_count,
                merchant_unread_count,
                created_at,
                updated_at,
                merchant:users!conversations_merchant_id_fkey(
                  id,
                  first_name,
                  last_name,
                  business_name,
                  business_description,
                  profile_image,
                  phone_number
                )
              ''')
              .eq('customer_id', userId)
              .order('last_message_at', ascending: false);

          return List<Map<String, dynamic>>.from(response);
        } else {
          // Requête directe pour les e-commerçants
          final response = await _supabase
              .from('conversations')
              .select('''
                id,
                customer_id,
                merchant_id,
                last_message_at,
                last_message_content,
                customer_unread_count,
                merchant_unread_count,
                created_at,
                updated_at,
                customer:users!conversations_customer_id_fkey(
                  id,
                  first_name,
                  last_name,
                  profile_image,
                  phone_number
                )
              ''')
              .eq('merchant_id', userId)
              .order('last_message_at', ascending: false);

          return List<Map<String, dynamic>>.from(response);
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des conversations: $e');
      return [];
    }
  }

  // Obtenir les messages d'une conversation
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      // Essayer d'abord avec la vue, sinon utiliser une requête directe
      try {
        final response = await _supabase
            .from('messages_with_sender')
            .select('*')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);

        return List<Map<String, dynamic>>.from(response);
      } catch (viewError) {
        print('Vue messages_with_sender non disponible, utilisation de requête directe: $viewError');
        
        // Requête directe
        final response = await _supabase
            .from('messages')
            .select('''
              id,
              conversation_id,
              sender_id,
              receiver_id,
              content,
              message_type,
              is_read,
              read_at,
              created_at,
              updated_at,
              sender:users!messages_sender_id_fkey(
                id,
                first_name,
                last_name,
                business_name,
                user_type,
                profile_image
              )
            ''')
            .eq('conversation_id', conversationId)
            .order('created_at', ascending: true);

        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Erreur lors de la récupération des messages: $e');
      return [];
    }
  }

  // Envoyer un message
  Future<Map<String, dynamic>?> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final resolvedReceiverUserId = await _resolveMerchantUserId(receiverId);

      // Vérifier que la conversation existe et récupérer les IDs
      final conversationCheck = await _supabase
          .from('conversations')
          .select('id, merchant_id, customer_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (conversationCheck == null) {
        throw Exception('Conversation introuvable');
      }

      final conversationMerchantId = conversationCheck['merchant_id'] as String?;
      final conversationCustomerId = conversationCheck['customer_id'] as String?;

      // Vérifier que l'expéditeur fait partie de la conversation
      if (senderId != conversationMerchantId && senderId != conversationCustomerId) {
        throw Exception('Vous n\'êtes pas autorisé à envoyer un message dans cette conversation');
      }

      // Insérer le message
      final response = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'receiver_id': resolvedReceiverUserId,
            'content': content,
            'message_type': messageType,
          })
          .select('''
            id,
            conversation_id,
            sender_id,
            receiver_id,
            content,
            message_type,
            is_read,
            created_at,
            updated_at,
            sender:users!messages_sender_id_fkey(
              id,
              first_name,
              last_name,
              business_name,
              user_type,
              profile_image
            )
          ''')
          .single();

      // Mettre à jour la conversation avec le dernier message
      try {
        final updateData = <String, dynamic>{
          'last_message_at': DateTime.now().toIso8601String(),
          'last_message_content': content,
        };

        // IMPORTANT:
        // Certaines versions du schéma n'ont pas les colonnes
        // `merchant_unread_count` / `customer_unread_count`.
        // Pour éviter un aller-retour réseau qui échoue et ralentit l'UI,
        // on ne les met plus à jour ici.

        await _supabase
            .from('conversations')
            .update(updateData)
            .eq('id', conversationId);
      } catch (updateError) {
        print('Erreur lors de la mise à jour de la conversation: $updateError');
        // Ne pas bloquer si la mise à jour échoue, le message est déjà envoyé
      }

      return response;
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      // Relancer l'exception pour que l'appelant puisse la gérer
      rethrow;
    }
  }

  // Créer ou obtenir une conversation + indiquer si elle vient d'être créée
  Future<ConversationCreateResult> getOrCreateConversationWithStatus({
    required String customerId,
    required String merchantId,
  }) async {
    try {
      final resolvedMerchantUserId = await _resolveMerchantUserId(merchantId);

      final existingConversation = await _supabase
          .from('conversations')
          .select('id')
          .eq('customer_id', customerId)
          .eq('merchant_id', resolvedMerchantUserId)
          .maybeSingle();

      if (existingConversation != null) {
        return ConversationCreateResult(
          conversationId: existingConversation['id']?.toString(),
          isNewConversation: false,
        );
      }

      try {
        final response = await _supabase
            .from('conversations')
            .insert({
              'customer_id': customerId,
              'merchant_id': resolvedMerchantUserId,
            })
            .select('id')
            .single();

        return ConversationCreateResult(
          conversationId: response['id']?.toString(),
          isNewConversation: true,
        );
      } catch (e) {
        // En cas de concurrence : la conversation a peut-être été créée juste après notre check.
        final retryConversation = await _supabase
            .from('conversations')
            .select('id')
            .eq('customer_id', customerId)
            .eq('merchant_id', resolvedMerchantUserId)
            .maybeSingle();

        return ConversationCreateResult(
          conversationId: retryConversation?['id']?.toString(),
          isNewConversation: false,
        );
      }
    } catch (e) {
      print('Erreur lors de la création de la conversation: $e');
      return const ConversationCreateResult(
        conversationId: null,
        isNewConversation: false,
      );
    }
  }

  // Créer ou obtenir une conversation
  Future<String?> getOrCreateConversation({
    required String customerId,
    required String merchantId,
  }) async {
    final res = await getOrCreateConversationWithStatus(
      customerId: customerId,
      merchantId: merchantId,
    );
    return res.conversationId;
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', conversationId)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      // IMPORTANT:
      // Le schéma peut ne pas contenir `customer_unread_count` / `merchant_unread_count`.
      // On évite donc l'update sur `conversations` (ça casse et ralentit).
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  // (optionnel) Des méthodes dédiées existent parfois pour éviter des doublons,
  // mais pour l'instant on ne fait pas d'envoi auto afin que le clic "Contacter"
  // soit instantané et sans spam.

  // Note: on ne récupère plus le `user_type` pour la messagerie tant que
  // les colonnes de compteur unread ne sont pas garanties dans le schéma.

  // Écouter les nouveaux messages en temps réel
  RealtimeChannel subscribeToMessages(String conversationId, Function(Map<String, dynamic>) onMessage) {
    return _supabase
        .channel('messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Écouter les nouvelles conversations et les mises à jour (dernier message)
  RealtimeChannel subscribeToConversations(String userId, String userType, Function(Map<String, dynamic>) onConversation) {
    String filterColumn = userType == 'customer' ? 'customer_id' : 'merchant_id';
    
    return _supabase
        .channel('conversations_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filterColumn,
            value: userId,
          ),
          callback: (payload) {
            onConversation(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Se désabonner des canaux temps réel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/messaging_service.dart';
import '../../../../data/services/image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantChatPage extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversation;

  const MerchantChatPage({
    super.key,
    required this.conversationId,
    required this.conversation,
  });

  @override
  State<MerchantChatPage> createState() => _MerchantChatPageState();
}

class _MerchantChatPageState extends State<MerchantChatPage> {
  final MessagingService _messagingService = MessagingService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _messagesChannel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markMessagesAsRead();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshMessagesQuietly();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _refreshMessagesQuietly() async {
    try {
      final messages = await _messagingService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() => _messages = messages);
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final messages = await _messagingService.getMessages(widget.conversationId);
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Erreur lors du chargement des messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Impossible de charger les messages. Réessayez.');
      }
    }
  }

  void _subscribeToMessages() {
    try {
      _messagesChannel = _messagingService.subscribeToMessages(
        widget.conversationId,
        (message) {
          if (mounted) {
            final msgId = message['id']?.toString();
            setState(() {
              final exists = _messages.any((m) => m['id']?.toString() == msgId);
              if (!exists) {
                _messages.add(message);
              }
            });
            _scrollToBottom();
            _markMessagesAsRead();
          }
        },
      );
      print('✅ Abonnement aux messages activé');
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement aux messages: $e');
      _showError('Erreur de connexion temps réel');
    }
  }

  Future<void> _markMessagesAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    try {
      await _messagingService.markMessagesAsRead(widget.conversationId, user.id);
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour envoyer un message'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Récupérer customer_id depuis la conversation ou depuis l'objet customer
    String? customerId = widget.conversation['customer_id'];
    if (customerId == null) {
      final customer = widget.conversation['customer'];
      if (customer != null && customer is Map<String, dynamic>) {
        customerId = customer['id'];
      }
    }

    if (customerId == null) {
      print('Erreur: customer_id introuvable dans la conversation');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Impossible d\'identifier le client'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Sauvegarder le contenu avant de vider le champ
    final messageContent = content;
    _messageController.clear();

    try {
      final result = await _messagingService.sendMessage(
        conversationId: widget.conversationId,
        senderId: user.id,
        receiverId: customerId,
        content: messageContent,
      );

      if (result == null) {
        throw Exception('Le message n\'a pas pu être envoyé (réponse nulle)');
      }

      // Ajouter le message à la liste localement pour un feedback immédiat
      if (mounted) {
        setState(() {
          _messages.add(result);
        });
        _scrollToBottom();
        _markMessagesAsRead();
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      // Remettre le contenu dans le champ si l'envoi échoue
      _messageController.text = messageContent;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.conversation['customer'] ?? {};
    final customerName = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Safe avatar to avoid throwing on image load failures
            ImageService.buildCircularImage(
              imageUrl: customer['profile_image'] ?? '',
              radius: 18,
              placeholder: Container(
                width: 36,
                height: 36,
                color: Colors.grey[400],
                child: Center(
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              errorWidget: Container(
                width: 36,
                height: 36,
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName.isNotEmpty ? customerName : 'Client',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer['phone_number'] != null)
                    Text(
                      customer['phone_number'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index]);
                        },
                      ),
          ),
          
          // Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final customer = widget.conversation['customer'] ?? {};
    final customerName = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez la conversation avec ${customerName.isNotEmpty ? customerName : 'ce client'}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final user = _supabase.auth.currentUser;
    final isMe = message['sender_id'] == user?.id;
    final sender = message['sender'] ?? {};
    final senderName = sender['business_name'] ?? 
                       '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim() ?? 
                       'Moi';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['created_at']),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}min';
      } else {
        return 'Maintenant';
      }
    } catch (e) {
      return '';
    }
  }

  void _showError(String message) {
    if (mounted) {
      ErrorHandler.showError(context, message, customMessage: message);
    }
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/image_service.dart';
import '../../../../data/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversation;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final MessagingService _messagingService = MessagingService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  RealtimeChannel? _messagesChannel;
  String? _resolvedReceiverId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markMessagesAsRead();
    _resolveReceiverId();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _refreshMessagesQuietly();
    });
  }

  Future<void> _resolveReceiverId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final merchantIdFromExtra = widget.conversation['merchant_id']?.toString();
      if (merchantIdFromExtra != null && merchantIdFromExtra.isNotEmpty) {
        // Le routeur a bien fourni l'info, on peut l'utiliser.
        _resolvedReceiverId = merchantIdFromExtra;
        return;
      }

      // Fallback robuste: on récupère merchant_id / customer_id depuis DB
      final conv = await _supabase
          .from('conversations')
          .select('merchant_id, customer_id')
          .eq('id', widget.conversationId)
          .maybeSingle();

      final merchantId = conv?['merchant_id']?.toString();
      final customerId = conv?['customer_id']?.toString();

      if (merchantId == null || customerId == null) return;

      // Chat côté customer: si l'utilisateur connecté est le customer => receiver = merchant
      // Sinon => receiver = customer
      if (user.id == customerId) {
        _resolvedReceiverId = merchantId;
      } else {
        _resolvedReceiverId = customerId;
      }
    } catch (_) {
      // On ignore: l'envoi tentera un resolve au besoin.
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
            print('📨 Nouveau message reçu en temps réel');
            setState(() {
              // Dédupliquer : le chargement initial + realtime peuvent provoquer des doublons.
              final msgId = message['id']?.toString();
              final key = msgId ??
                  '${message['sender_id']}-${message['created_at']}-${message['content']}';

              final exists = _messages.any((m) {
                final mId = m['id']?.toString();
                if (mId != null) {
                  return mId == msgId;
                }
                final mKey = '${m['sender_id']}-${m['created_at']}-${m['content']}';
                return mKey == key;
              });

              if (exists) return;
              _messages.add(message);
            });
            _scrollToBottom();
          }
        },
      );
      print('✅ Abonnement aux messages activé');
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement aux messages: $e');
      _showError('Erreur de connexion temps réel');
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

    final receiverId = _resolvedReceiverId ?? widget.conversation['merchant_id']?.toString();
    if (receiverId == null || receiverId.trim().isEmpty) {
      // Tente une résolution tardive si l'extra n'était pas complet.
      await _resolveReceiverId();
    }

    final finalReceiverId = _resolvedReceiverId ?? widget.conversation['merchant_id']?.toString();
    if (finalReceiverId == null || finalReceiverId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Impossible d\'identifier le destinataire'),
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
        receiverId: finalReceiverId,
        content: messageContent,
      );

      // Ajouter le message à la liste localement pour un feedback immédiat
      if (result != null && mounted) {
        setState(() {
          _messages.add(result);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi du message: $e');
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
    final merchant = widget.conversation['merchant'];
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryLightColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                // Use safe circular image loader to avoid throwing on 404s
                ImageService.buildCircularImage(
                  imageUrl: merchant['business_image'] ?? '',
                  radius: 18,
                  placeholder: Container(
                    width: 36,
                    height: 36,
                    color: Colors.white.withOpacity(0.2),
                    child: Center(
                      child: Text(
                        merchant['business_name']?.toString().substring(0, 1).toUpperCase() ?? 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: Container(
                    width: 36,
                    height: 36,
                    color: Colors.white.withOpacity(0.2),
                    child: Center(
                      child: Text(
                        merchant['business_name']?.toString().substring(0, 1).toUpperCase() ?? 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        merchant['business_name'] ?? 'E-commerçant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _messagesChannel != null ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _messagesChannel != null ? 'En ligne' : 'Hors ligne',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  // TODO: Menu options
                },
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLightColor,
                  ],
                ),
              ),
            ),
          ),
        ),
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
            'Commencez la conversation avec ${widget.conversation['merchant']['business_name']}',
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
    final sender = message['sender'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundImage: sender['profile_image'] != null
                  ? NetworkImage(sender['profile_image'])
                  : null,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: sender['profile_image'] == null
                  ? Text(
                      sender['first_name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : Colors.grey[100],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(6),
                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'],
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message['created_at']),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['is_read'] == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message['is_read'] == true ? Colors.blue[300] : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Tapez votre message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16),
                    onSubmitted: (_) => _sendMessage(), // Permet d'envoyer avec la touche Entrée
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton d'envoi amélioré et plus visible
              Material(
                color: AppTheme.primaryColor,
                shape: const CircleBorder(),
                elevation: 4,
                child: InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryLightColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        return '${difference.inDays}j';
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

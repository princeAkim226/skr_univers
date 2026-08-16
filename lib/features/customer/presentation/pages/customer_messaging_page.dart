import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../data/services/image_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/messaging_service.dart';
import '../../../../data/services/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerMessagingPage extends StatefulWidget {
  const CustomerMessagingPage({super.key});

  @override
  State<CustomerMessagingPage> createState() => _CustomerMessagingPageState();
}

class _CustomerMessagingPageState extends State<CustomerMessagingPage> {
  final MessagingService _messagingService = MessagingService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _availableMerchants = [];
  bool _isLoading = true;
  RealtimeChannel? _conversationsChannel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadDataQuietly();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _conversationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadDataQuietly() async {
    final user = _supabase.auth.currentUser;
    if (user == null || !mounted) return;
    try {
      final conversations = await _messagingService.getConversations(user.id, 'customer');
      if (!mounted) return;
      setState(() => _conversations = conversations);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError('Vous devez être connecté pour accéder à la messagerie');
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Charger les conversations et les marchands en parallèle avec timeout
      final results = await Future.wait([
        _messagingService.getConversations(user.id, 'customer').timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('⏱️ Timeout lors du chargement des conversations');
            return <Map<String, dynamic>>[];
          },
        ),
        _subscriptionService.getAvailableMerchants().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('⏱️ Timeout lors du chargement des marchands');
            return <Map<String, dynamic>>[];
          },
        ),
      ]);

      final conversations = results[0];
      final merchants = results[1];
      
      print('📨 ${conversations.length} conversations chargées');
      print('🏪 ${merchants.length} e-commerçants disponibles chargés');
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _availableMerchants = merchants;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des données: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('Erreur lors du chargement: ${e.toString()}');
      }
    }
  }

  void _subscribeToConversations() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showError('Utilisateur non connecté');
      return;
    }

    try {
      _conversationsChannel = _messagingService.subscribeToConversations(
        user.id,
        'customer',
        (conversation) {
          if (mounted) {
            print('🔄 Nouvelle conversation reçue en temps réel');
            _loadDataQuietly();
          }
        },
      );
      print('✅ Abonnement aux conversations activé');
    } catch (e) {
      print('❌ Erreur lors de l\'abonnement aux conversations: $e');
      _showError('Erreur de connexion temps réel');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StyledAppBar(
        title: 'Messagerie',
        actions: [
          // Indicateur de statut de connexion
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _conversationsChannel != null ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people_rounded),
            onPressed: _showMerchantsList,
            tooltip: 'Voir les e-commerçants',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : _buildConversationsList(),
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
            'Aucune conversation',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Abonnez-vous à des e-commerçants pour commencer à discuter',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showMerchantsList,
            icon: const Icon(Icons.people),
            label: const Text('Voir les e-commerçants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final merchant = conversation['merchant'] ?? {};
        final unreadCount = conversation['customer_unread_count'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.push('/customer/chat/${conversation['id']}', extra: conversation);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar avec indicateur de statut
                    Stack(
                      children: [
                        ImageService.buildCircularImage(
                          imageUrl: (merchant['business_image'] ?? merchant['profile_image']) ?? '',
                          radius: 28,
                          placeholder: Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                (merchant['business_name']?.toString() ?? 'M').substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: Container(
                            width: 56,
                            height: 56,
                            color: AppTheme.primaryColor.withOpacity(0.06),
                            child: Center(
                              child: Text(
                                (merchant['business_name']?.toString() ?? 'M').substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Contenu de la conversation
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  merchant['business_name'] ?? 'E-commerçant',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTime(conversation['last_message_at']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conversation['last_message_content'] ?? 'Aucun message',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: unreadCount > 0 ? AppTheme.textPrimaryColor : Colors.grey[600],
                              fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Indicateur de statut
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  void _showMerchantsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // AppBar personnalisé avec bouton de retour
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryLightColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Retour',
                    ),
                    Expanded(
                      child: Text(
                        'E-commerçants disponibles',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        await _loadData();
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      tooltip: 'Actualiser',
                    ),
                  ],
                ),
              ),
              // Contenu
              Expanded(
                child: _availableMerchants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucun e-commerçant disponible',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Les e-commerçants apparaîtront ici une fois qu\'ils auront créé leur compte',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableMerchants.length,
                        itemBuilder: (context, index) {
                          final merchant = _availableMerchants[index];
                          return _buildMerchantCard(merchant);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant) {
    final businessName = merchant['business_name']?.toString() ?? 'E-commerçant';
    final businessDescription = merchant['business_description']?.toString() ?? 'Aucune description';
    final profileImage = merchant['profile_image']?.toString();
    final businessImage = merchant['business_image']?.toString();
    final imageUrl = businessImage ?? profileImage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryLightColor,
                  ],
                ),
              ),
              child: imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              businessName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Text(
                        businessName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Boutons d'action
            FutureBuilder<bool>(
              future: _subscriptionService.isSubscribed(
                customerId: _supabase.auth.currentUser?.id ?? '',
                merchantId: merchant['id'],
              ),
              builder: (context, snapshot) {
                final isSubscribed = snapshot.data ?? false;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton Message - Plus visible
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openChatWithMerchant(merchant),
                        borderRadius: BorderRadius.circular(25),
                        child: Container(
                          width: 48,
                          height: 48,
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
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chat_bubble_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton d'abonnement
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () {
                          if (isSubscribed) {
                            _unsubscribeFromMerchant(merchant);
                          } else {
                            _subscribeToMerchant(merchant);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSubscribed 
                              ? Colors.red.shade400 
                              : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isSubscribed ? 'Se désabonner' : 'S\'abonner',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithMerchant(Map<String, dynamic> merchant) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showError('Vous devez être connecté pour envoyer un message');
      return;
    }

    try {
      // Créer ou récupérer la conversation
      final conversationId = await _messagingService.getOrCreateConversation(
        customerId: user.id,
        merchantId: merchant['id'],
      );

      if (conversationId == null) {
        if (mounted) {
          _showError('Impossible de créer ou récupérer la conversation');
        }
        return;
      }

      if (mounted) {
        // Fermer la modale des marchands
        Navigator.of(context).pop();
        
        // Préparer les données de conversation
        final conversationData = <String, dynamic>{
          'id': conversationId,
          'customer_id': user.id,
          'merchant_id': merchant['id'],
          'merchant': merchant,
        };
        
        // Ouvrir la page de chat
        context.push('/customer/chat/$conversationId', extra: conversationData);
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du chat: $e');
      if (mounted) {
        _showError('Erreur lors de l\'ouverture du chat: ${e.toString()}');
      }
    }
  }

  void _subscribeToMerchant(Map<String, dynamic> merchant) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final success = await _subscriptionService.subscribeToMerchant(
      customerId: user.id,
      merchantId: merchant['id'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Abonnement réussi à ${merchant['business_name']}'
                : 'Erreur lors de l\'abonnement',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      
      if (success) {
        _loadData(); // Recharger les données
      }
    }
  }

  void _unsubscribeFromMerchant(Map<String, dynamic> merchant) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final success = await _subscriptionService.unsubscribeFromMerchant(
      customerId: user.id,
      merchantId: merchant['id'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Désabonnement réussi de ${merchant['business_name']}'
                : 'Erreur lors du désabonnement',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      
      if (success) {
        _loadData(); // Recharger les données
      }
    }
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

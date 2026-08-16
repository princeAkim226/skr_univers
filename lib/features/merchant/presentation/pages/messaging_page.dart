import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/messaging_service.dart';
import '../../../../data/services/subscription_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantMessagingPage extends StatefulWidget {
  const MerchantMessagingPage({super.key});

  @override
  State<MerchantMessagingPage> createState() => _MerchantMessagingPageState();
}

class _MerchantMessagingPageState extends State<MerchantMessagingPage> {
  final MessagingService _messagingService = MessagingService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _conversationsChannel;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToConversations();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      _loadConversationsQuietly();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _conversationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversationsQuietly() async {
    final user = _supabase.auth.currentUser;
    if (user == null || !mounted) return;
    try {
      final conversations = await _messagingService.getConversations(user.id, 'merchant');
      if (!mounted) return;
      setState(() => _conversations = conversations);
    } catch (_) {}
  }

  Future<void> _loadConversations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous devez être connecté pour voir vos conversations'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final conversations = await _messagingService.getConversations(user.id, 'merchant');
      
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ErrorHandler.showError(context, e);
      }
    }
  }

  void _subscribeToConversations() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      _conversationsChannel = _messagingService.subscribeToConversations(
        user.id,
        'merchant',
        (conversation) {
          if (mounted) {
            _loadConversationsQuietly();
          }
        },
      );
    } catch (e) {
      print('Erreur lors de l\'abonnement aux conversations: $e');
      // Ne pas bloquer l'interface si l'abonnement échoue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StyledAppBar(
        title: 'Messagerie',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
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
            'Les clients abonnés à votre compte pourront vous envoyer des messages',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Afficher les statistiques d'abonnement
              _showSubscriptionStats();
            },
            icon: const Icon(Icons.people),
            label: const Text('Voir mes abonnés'),
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
        final customer = conversation['customer'] as Map<String, dynamic>?;
        final unreadCount = conversation['merchant_unread_count'] ?? 0;
        
        // Gérer le cas où customer est null ou vide
        final customerName = customer != null
            ? '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim()
            : 'Client';
        final customerInitial = customer != null && customer['first_name'] != null
            ? customer['first_name'].toString().substring(0, 1).toUpperCase()
            : 'C';
        final profileImage = customer?['profile_image'];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: profileImage != null && profileImage.toString().isNotEmpty
                  ? NetworkImage(profileImage.toString())
                  : null,
              child: profileImage == null || profileImage.toString().isEmpty
                  ? Text(
                      customerInitial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              customerName.isEmpty ? 'Client' : customerName,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              conversation['last_message_content'] ?? 'Aucun message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(conversation['last_message_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap: () {
              _openChat(conversation);
            },
          ),
        );
      },
    );
  }

  void _openChat(Map<String, dynamic> conversation) {
    // Naviguer vers la page de chat
    context.push('/merchant/chat/${conversation['id']}', extra: {
      'conversation': conversation,
    });
  }

  void _showSubscriptionStats() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final stats = await _subscriptionService.getSubscriptionStats(user.id);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Statistiques d\'abonnement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: AppTheme.primaryColor),
                title: const Text('Abonnés'),
                trailing: Text(
                  '${stats['subscribers_count']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  stats['has_plus_subscription'] ? Icons.star : Icons.star_border,
                  color: stats['has_plus_subscription'] ? Colors.amber : Colors.grey,
                ),
                title: const Text('Abonnement Plus'),
                trailing: Text(
                  stats['has_plus_subscription'] ? 'Actif' : 'Inactif',
                  style: TextStyle(
                    color: stats['has_plus_subscription'] ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            if (!stats['has_plus_subscription'])
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showUpgradeDialog();
                },
                child: const Text('Upgrader'),
              ),
          ],
        ),
      );
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrader vers Plus'),
        content: const Text(
          'L\'abonnement Plus vous permet d\'apparaître dans les stories des clients et d\'avoir plus de visibilité.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici vous pouvez intégrer un système de paiement
              _activatePlusSubscription();
            },
            child: const Text('Activer Plus'),
          ),
        ],
      ),
    );
  }

  void _activatePlusSubscription() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Pour l'instant, on active gratuitement pour les tests
    final success = await _subscriptionService.activatePlusSubscription(
      merchantId: user.id,
      price: 29.99,
      durationInDays: 30,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Abonnement Plus activé avec succès !'
                : 'Erreur lors de l\'activation de l\'abonnement Plus',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
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
}

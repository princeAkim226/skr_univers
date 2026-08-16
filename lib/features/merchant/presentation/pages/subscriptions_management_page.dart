import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../core/constants/subscription_plans.dart';
import '../../../../data/services/subscription_service.dart';
import '../../../../data/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionsManagementPage extends StatefulWidget {
  const SubscriptionsManagementPage({super.key});

  @override
  State<SubscriptionsManagementPage> createState() => _SubscriptionsManagementPageState();
}

class _SubscriptionsManagementPageState extends State<SubscriptionsManagementPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final MessagingService _messagingService = MessagingService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _subscribers = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      setState(() {
        _isLoading = true;
      });

      // Note: customer_subscriptions.merchant_id référence users(id), pas merchants(id)
      // Donc on utilise user.id directement
      final subscribers = await _subscriptionService.getSubscribers(user.id);

      // Charger les statistiques (utilise l'ID utilisateur)
      final stats = await _subscriptionService.getSubscriptionStats(user.id);

      if (mounted) {
        setState(() {
          _subscribers = subscribers;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StyledAppBar(
        title: 'Plans & abonnements',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(VintageIcons.merchantAction('plans')),
            tooltip: 'Changer de plan',
            onPressed: () {
              context.push('/merchant/plans').then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
                    _buildStatsCard(),
                    const SizedBox(height: 24),
                    
                    // Liste des abonnés
                    const Text(
                      'Mes Abonnés',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_subscribers.isEmpty)
                      _buildEmptyState()
                    else
                      ..._subscribers.map((subscriber) => _buildSubscriberCard(subscriber)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    final subscribersCount = _stats['subscribers_count'] ?? 0;
    final currentPlan = _stats['current_plan'] as String? ?? SubscriptionPlans.simple;
    final canAppearInList = _stats['can_appear_in_list'] ?? false;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    context.push('/merchant/plans').then((_) => _loadData());
                  },
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: const Text('Changer de plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Abonnés',
                    value: subscribersCount.toString(),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: currentPlan == SubscriptionPlans.premium
                        ? Icons.star
                        : currentPlan == SubscriptionPlans.pro
                            ? Icons.business
                            : Icons.person_outline,
                    label: 'Plan actuel',
                    value: SubscriptionPlans.getDisplayName(currentPlan),
                    color: currentPlan == SubscriptionPlans.premium
                        ? Colors.amber
                        : currentPlan == SubscriptionPlans.pro
                            ? Colors.blue
                            : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Avantages de votre plan:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              'Apparaître dans la liste',
              canAppearInList,
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Les publicités nécessitent un abonnement publicitaire séparé (25 000 FCFA/mois)',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: enabled ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriberCard(Map<String, dynamic> subscriber) {
    final customer = subscriber['customer'] ?? {};
    final firstName = customer['first_name'] ?? '';
    final lastName = customer['last_name'] ?? '';
    final customerName = '$firstName $lastName'.trim();
    final phoneNumber = customer['phone_number'] ?? '';
    final profileImage = customer['profile_image'];
    final subscribedAt = subscriber['created_at'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profileImage != null ? NetworkImage(profileImage) : null,
          child: profileImage == null
              ? Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          customerName.isNotEmpty ? customerName : 'Client',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phoneNumber.isNotEmpty)
              Text(phoneNumber),
            if (subscribedAt != null)
              Text(
                'Abonné depuis ${_formatDate(subscribedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => _openChatWithCustomer(subscriber),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun abonné',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les clients peuvent s\'abonner à votre compte pour recevoir vos actualités',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _openChatWithCustomer(Map<String, dynamic> subscriber) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final customerId = subscriber['customer_id'];
      if (customerId == null) return;

      // Dans conversations, merchant_id référence users(id), donc on utilise user.id
      // Créer ou obtenir la conversation
      final conversationId = await _messagingService.getOrCreateConversation(
        customerId: customerId,
        merchantId: user.id,
      );

      if (conversationId != null && mounted) {
        // Récupérer les détails de la conversation
        final conversations = await _messagingService.getConversations(user.id, 'merchant');
        final conversation = conversations.firstWhere(
          (c) => c['id'] == conversationId,
          orElse: () => {
            'id': conversationId,
            'customer_id': customerId,
            'merchant_id': user.id,
            'customer': subscriber['customer'],
          },
        );

        context.push('/merchant/chat/$conversationId', extra: {
          'conversation': conversation,
        });
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
      } else {
        return 'quelques minutes';
      }
    } catch (e) {
      return '';
    }
  }
}


import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final notifications = await NotificationService.getPendingNotifications();
      setState(() {
        _pendingNotifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Toutes les notifications ont été supprimées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.showNotification(
        id: 999,
        title: 'Test de notification',
        body: 'Ceci est une notification de test',
        payload: 'test',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification de test envoyée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_pendingNotifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Supprimer toutes les notifications',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingNotifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _testNotification,
        child: const Icon(Icons.notifications_active),
        tooltip: 'Tester les notifications',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous recevrez des notifications ici',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _testNotification,
            icon: const Icon(Icons.notifications_active),
            label: const Text('Tester les notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingNotifications.length,
      itemBuilder: (context, index) {
        final notification = _pendingNotifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(PendingNotificationRequest notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getNotificationIcon(notification.payload),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          notification.title ?? 'Notification',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          notification.body ?? 'Aucun contenu',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () async {
            await NotificationService.cancelNotification(notification.id);
            await _loadNotifications();
          },
        ),
        onTap: () {
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? payload) {
    if (payload == null) return Icons.notifications;
    
    if (payload.startsWith('order:')) return Icons.shopping_bag;
    if (payload == 'cart') return Icons.shopping_cart;
    if (payload == 'promotion') return Icons.local_offer;
    if (payload == 'product') return Icons.inventory;
    if (payload == 'test') return Icons.bug_report;
    
    return Icons.notifications;
  }

  void _handleNotificationTap(PendingNotificationRequest notification) {
    final payload = notification.payload;
    if (payload == null) return;

    if (payload.startsWith('order:')) {
      context.push('/customer/orders');
    } else if (payload == 'cart') {
      context.push('/customer/cart');
    } else if (payload == 'product') {
      context.push('/customer/products');
    }
  }
}

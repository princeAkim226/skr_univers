import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactSellerWidget extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final Map<String, dynamic> product;

  const ContactSellerWidget({
    super.key,
    required this.merchant,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Icon(
                Icons.store,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Contacter le vendeur',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations du vendeur
          _buildSellerInfo(),
          
          const SizedBox(height: 16),
          
          // Informations du produit
          _buildProductInfo(),
          
          const SizedBox(height: 20),
          
          // Boutons d'action
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du vendeur',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          if (merchant['business_name'] != null)
            _buildInfoRow(
              Icons.business,
              'Commerce',
              merchant['business_name'],
            ),
          
          if (merchant['business_phone'] != null)
            _buildInfoRow(
              Icons.phone,
              'Téléphone',
              merchant['business_phone'],
            ),
          
          if (merchant['business_address'] != null)
            _buildInfoRow(
              Icons.location_on,
              'Adresse',
              merchant['business_address'],
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produit d\'intérêt',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.successColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildInfoRow(
            Icons.shopping_bag,
            'Produit',
            product['title'] ?? 'Non spécifié',
          ),
          
          _buildInfoRow(
            Icons.attach_money,
            'Prix',
            '${NumberUtils.toDouble(product['price']).toStringAsFixed(0)} FCFA',
          ),
          
          if (product['category'] != null)
            _buildInfoRow(
              Icons.category,
              'Catégorie',
              product['category'],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Bouton Messagerie interne
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _startConversation(context),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Messagerie'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Bouton Appeler (optionnel)
        if (merchant['business_phone'] != null)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _makePhoneCall(merchant['business_phone']),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _startConversation(BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showError(context, 'Vous devez être connecté pour envoyer un message');
        return;
      }

      final messagingService = MessagingService();
      
      // IMPORTANT:
      // Dans la plupart des requêtes, `merchant` contient seulement business_name/image.
      // Le champ `id` peut donc être null.
      // Pour créer une conversation, on a besoin de l'ID du profil marchand => `products.merchant_id`.
      final String? receiverMerchantId = (product['merchant_id'] ?? merchant['id'])?.toString();
      if (receiverMerchantId == null || receiverMerchantId.trim().isEmpty) {
        _showError(context, 'Impossible de trouver l\'identifiant du vendeur (merchant_id).');
        return;
      }

      // Créer ou obtenir la conversation (et savoir si elle est nouvelle)
      final convoResult = await messagingService.getOrCreateConversationWithStatus(
        customerId: user.id,
        merchantId: receiverMerchantId,
      );

      final conversationId = convoResult.conversationId;

      if (conversationId != null) {
        // Naviguer vers la page de chat
        if (context.mounted) {
          context.push('/customer/chat/$conversationId', extra: {
            'merchant_id': receiverMerchantId,
            'merchant': merchant,
          });
        }
      } else {
        _showError(context, 'Impossible de créer la conversation');
      }
    } catch (e) {
      ErrorHandler.showError(context, e);
    }
  }

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return;
    }
    
    try {
      // Note: url_launcher est nécessaire pour les appels téléphoniques
      // await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
      print('Appel vers: $phoneNumber');
    } catch (e) {
      print('Erreur lors de l\'appel: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

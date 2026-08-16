import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/error_handling/error_boundary.dart';
import '../../../../data/services/payment_service.dart';
import '../../../../data/services/order_service.dart';
import '../../../../data/services/cart_service.dart';

class PaymentPage extends StatefulWidget {
  final String orderId;

  const PaymentPage({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> with ErrorHandlingMixin {
  final PaymentService _paymentService = PaymentService();
  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();
  
  String _selectedPaymentMethod = 'mobile_money';
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    await executeWithErrorHandling(
      () async {
        final order = await _orderService.getOrderById(widget.orderId);
        setState(() {
          _order = order;
        });
      },
    );
  }

  Future<void> _processPayment() async {
    if (isLoading) return;

    await executeWithErrorHandling(
      () async {
        Map<String, dynamic> result;

        if (_selectedPaymentMethod == 'mobile_money') {
          if (_phoneController.text.trim().isEmpty) {
            throw Exception('Veuillez entrer votre numéro de téléphone');
          }
          
          result = await _paymentService.processMobileMoneyPayment(
            phoneNumber: _phoneController.text.trim(),
            amount: _order!['total_amount'].toDouble(),
            orderId: widget.orderId,
          );
        } else {
          if (_cardNumberController.text.trim().isEmpty ||
              _expiryController.text.trim().isEmpty ||
              _cvvController.text.trim().isEmpty ||
              _cardHolderController.text.trim().isEmpty) {
            throw Exception('Veuillez remplir tous les champs de la carte');
          }
          
          result = await _paymentService.processCardPayment(
            cardNumber: _cardNumberController.text.trim(),
            expiryDate: _expiryController.text.trim(),
            cvv: _cvvController.text.trim(),
            cardHolderName: _cardHolderController.text.trim(),
            amount: _order!['total_amount'].toDouble(),
            orderId: widget.orderId,
          );
        }

        if (result['success'] == true) {
          // Mettre à jour le statut de la commande
          await _orderService.updateOrderStatus(widget.orderId, 'paid');
          
          // Vider le panier
          await _cartService.clearCart();
          
          if (mounted) {
            showSuccess('Paiement effectué avec succès !');
            // Rediriger vers la page de confirmation
            context.go('/customer/orders');
          }
        } else {
          throw Exception(result['error'] ?? 'Erreur lors du paiement');
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: buildLoadingWidget(message: 'Chargement de la commande...'),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: Center(
          child: buildErrorWidget(
            title: 'Commande non trouvée',
            message: 'Impossible de charger les détails de la commande.',
            onRetry: _loadOrder,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la commande
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.lightShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Résumé de la commande',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sous-total'),
                      Text('${_order!['total_amount'].toStringAsFixed(0)} FCFA'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Livraison'),
                      const Text('Gratuite'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_order!['total_amount'].toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Méthodes de paiement
            const Text(
              'Méthode de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Mobile Money
            _buildPaymentMethodCard(
              'mobile_money',
              'Mobile Money',
              'Orange Money, Moov Money, MTN Mobile Money',
              Icons.phone_android,
            ),
            
            const SizedBox(height: 12),
            
            // Carte bancaire
            _buildPaymentMethodCard(
              'card',
              'Carte bancaire',
              'Visa, Mastercard, American Express',
              Icons.credit_card,
            ),
            
            const SizedBox(height: 24),
            
            // Formulaire de paiement
            if (_selectedPaymentMethod == 'mobile_money') ...[
              _buildMobileMoneyForm(),
            ] else ...[
              _buildCardForm(),
            ],
            
            const SizedBox(height: 32),
            
            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Traitement en cours...'),
                        ],
                      )
                    : Text(
                        'Payer ${_order!['total_amount'].toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String value, String title, String subtitle, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMoneyForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations Mobile Money',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: '+226 XX XX XX XX',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations de la carte',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Numéro de carte',
              hintText: '1234 5678 9012 3456',
              prefixIcon: Icon(Icons.credit_card),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'MM/AA',
                    hintText: '12/25',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cardHolderController,
            decoration: const InputDecoration(
              labelText: 'Nom du titulaire',
              hintText: 'Jean Dupont',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/number_utils.dart';
import '../../../../data/services/cart_service.dart';
import '../../../../data/services/order_service.dart';
import '../../../../data/services/promo_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();
  final PromoService _promoService = PromoService();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _promoCodeController = TextEditingController();
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isApplyingPromo = false;
  double _total = 0;
  double _discountAmount = 0;
  String? _appliedPromoCodeId;
  String? _promoMessage;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCartItems() async {
    try {
      setState(() => _isLoading = true);
      final items = await _cartService.getCartItems();
      setState(() {
        _cartItems = items;
        _total = _cartService.calculateTotal(items);
        _discountAmount = 0;
        _appliedPromoCodeId = null;
        _promoMessage = null;
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

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cartItems.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final order = await _orderService.createOrder(
        cartItems: _cartItems,
        shippingAddress: _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        promoCodeId: _appliedPromoCodeId,
        discountAmount: _discountAmount,
        subtotalAmount: _total,
        finalAmount: _finalTotal,
      );

      if (_appliedPromoCodeId != null && _discountAmount > 0) {
        await _promoService.redeemPromoCode(
          promoCodeId: _appliedPromoCodeId!,
          orderId: order['id'].toString(),
          discountAmount: _discountAmount,
        );
      }

      if (mounted) {
        // Naviguer vers la page de paiement
        context.push('/customer/payment/${order['id']}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? _buildEmptyCart()
              : _buildCheckoutForm(),
    );
  }

  double get _finalTotal {
    final value = _total - _discountAmount;
    return value < 0 ? 0 : value;
  }

  String? _resolveMerchantId() {
    if (_cartItems.isEmpty) return null;
    final product = _cartItems.first['product'];
    if (product is! Map) return null;
    final merchantId = product['merchant_id']?.toString();
    if (merchantId != null && merchantId.isNotEmpty) return merchantId;
    if (product['merchant'] is Map) {
      return (product['merchant'] as Map)['id']?.toString();
    }
    return null;
  }

  Future<void> _applyPromoCode() async {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;
    final merchantId = _resolveMerchantId();
    if (merchantId == null || merchantId.isEmpty) {
      setState(() {
        _promoMessage = 'Impossible d\'identifier le marchand pour ce panier';
        _appliedPromoCodeId = null;
        _discountAmount = 0;
      });
      return;
    }

    setState(() => _isApplyingPromo = true);
    final result = await _promoService.validatePromoCode(
      code: code,
      merchantId: merchantId,
      orderAmount: _total,
    );

    if (!mounted) return;
    setState(() {
      _isApplyingPromo = false;
      _promoMessage = result.message;
      if (result.valid) {
        _appliedPromoCodeId = result.promoCodeId;
        _discountAmount = result.discountAmount;
      } else {
        _appliedPromoCodeId = null;
        _discountAmount = 0;
      }
    });
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Votre panier est vide',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/customer/products'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Voir les produits'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la commande
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé de la commande',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._cartItems.map((item) => _buildOrderItem(item)),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_total.toStringAsFixed(0)} FCFA',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.priceColor,
                          ),
                        ),
                      ],
                    ),
                    if (_discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Réduction promo:',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '-${_discountAmount.toStringAsFixed(0)} FCFA',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total final:',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${_finalTotal.toStringAsFixed(0)} FCFA',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.priceColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informations de livraison
            Text(
              'Informations de livraison',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse de livraison *',
                hintText: 'Entrez votre adresse complète',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'L\'adresse de livraison est requise';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),

            // Code promo
            Text(
              'Code promo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _promoCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Entrez votre code',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isApplyingPromo ? null : _applyPromoCode,
                  child: _isApplyingPromo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Appliquer'),
                ),
              ],
            ),
            if (_promoMessage != null && _promoMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _promoMessage!,
                style: TextStyle(
                  color: _appliedPromoCodeId != null ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Instructions spéciales pour la livraison',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            // Méthode de paiement
            Text(
              'Méthode de paiement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_android, color: AppTheme.primaryColor),
                title: const Text('Mobile Money'),
                subtitle: const Text('Orange Money, MTN Money, Moov Money'),
                trailing: Radio<String>(
                  value: 'mobile_money',
                  groupValue: 'mobile_money',
                  onChanged: (value) {},
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de commande
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                icon: _isSubmitting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.shopping_bag),
                label: Text(_isSubmitting ? 'Traitement...' : 'Confirmer la commande'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final product = item['product'];
    if (product == null) return const SizedBox.shrink();

    final String title = product['title'] ?? 'Produit';
    final double price = NumberUtils.toDouble(product['price']);
    final int quantity = (item['quantity'] ?? 0).toInt();
    final String imageUrl = (product['images'] is List && (product['images'] as List).isNotEmpty)
        ? (product['images'] as List).first.toString()
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          color: Colors.grey.shade400,
                          size: 20,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.shopping_bag,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          
          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantité: $quantity',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Prix
          Text(
            '${(price * quantity).toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.priceColor,
            ),
          ),
        ],
      ),
    );
  }
}

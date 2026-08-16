import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../data/services/subscription_service.dart';
import '../../../../data/services/category_service.dart';
import '../../../../data/services/messaging_service.dart';
import '../../../../data/services/image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/merchant_card.dart';
import '../widgets/category_selector.dart';
import '../../../../core/error_handling/error_handler.dart';

class MerchantsDiscoveryPage extends StatefulWidget {
  const MerchantsDiscoveryPage({super.key});

  @override
  State<MerchantsDiscoveryPage> createState() => _MerchantsDiscoveryPageState();
}

class _MerchantsDiscoveryPageState extends State<MerchantsDiscoveryPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CategoryService _categoryService = CategoryService();
  final MessagingService _messagingService = MessagingService();

  List<Map<String, dynamic>> _merchants = [];
  List<String> _categories = [];
  Map<String, int> _categoryStats = {};
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _categoryService.getAllCategories();
      final categoryStats = await _categoryService.getCategoryStats();
      final merchants = await _subscriptionService.getAvailableMerchants();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryStats = categoryStats;
        _merchants = merchants;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _filterByCategory(String? category) async {
    if (category == null) {
      final merchants = await _subscriptionService.getAvailableMerchants();
      setState(() {
        _merchants = merchants;
        _selectedCategory = null;
      });
    } else {
      final merchants = await _categoryService.getMerchantsByCategory(category);
      setState(() {
        _merchants = merchants;
        _selectedCategory = category;
      });
    }
  }

  Future<void> _openProducts(Map<String, dynamic> merchant) async {
    final id = merchant['id']?.toString();
    if (id == null || id.isEmpty) return;
    if (mounted) context.push('/customer/merchant/$id');
  }

  Future<void> _contactMerchant(Map<String, dynamic> merchant) async {
    final user = Supabase.instance.client.auth.currentUser;
    final merchantId = merchant['id']?.toString();
    if (user == null || merchantId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour contacter la boutique')),
      );
      return;
    }

    try {
      await _subscriptionService.subscribeToMerchant(
        customerId: user.id,
        merchantId: merchantId,
      );
      final conversationId = await _messagingService.getOrCreateConversation(
        customerId: user.id,
        merchantId: merchantId,
      );
      if (!mounted) return;
      if (conversationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir la conversation')),
        );
        return;
      }
      context.push(
        '/customer/chat/$conversationId',
        extra: {
          'id': conversationId,
          'merchant_id': merchantId,
          'customer_id': user.id,
          'merchant': merchant,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: StyledAppBar(
        title: 'Boutiques',
        subtitle: 'Découvrir les e-commerçants',
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  CategorySelector(
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _filterByCategory,
                    categoryStats: _categoryStats,
                  ),
                  const SizedBox(height: 8),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    '${_merchants.length} boutique${_merchants.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: _merchants.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppTheme.primaryColor,
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _merchants.length,
                            itemBuilder: (context, index) {
                              final merchant = _merchants[index];
                              return MerchantCard(
                                merchant: merchant,
                                onTap: () => _showMerchantDetails(merchant),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VintageIconBadge(
              icon: Icons.store,
              size: 36,
            ),
            const SizedBox(height: 18),
            Text(
              _selectedCategory == null
                  ? 'Aucune boutique pour l’instant'
                  : 'Aucune boutique dans « $_selectedCategory »',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Revenez plus tard pour découvrir de nouveaux e-commerçants.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  void _showMerchantDetails(Map<String, dynamic> merchant) {
    final name = merchant['business_name']?.toString() ?? 'Boutique';
    final description = merchant['business_description']?.toString() ?? '';
    final phone = merchant['phone_number']?.toString() ??
        merchant['business_phone']?.toString() ??
        '';
    final image = merchant['profile_image']?.toString() ??
        merchant['business_image']?.toString() ??
        '';
    final initial =
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F7F4),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Poignée
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // Hero boutique
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1B5E20),
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: image.isNotEmpty
                              ? ImageService.buildCircularImage(
                                  imageUrl: image,
                                  radius: 34,
                                  placeholder: _InitialAvatar(initial: initial),
                                  errorWidget: _InitialAvatar(initial: initial),
                                )
                              : _InitialAvatar(initial: initial, radius: 34),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (phone.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk,
                                      size: 15,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        phone,
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE6EEE6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'À propos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _openProducts(merchant);
                            },
                            icon: Icon(
                              VintageIcons.merchantAction('Mes produits'),
                              size: 18,
                            ),
                            label: const Text('Voir les produits'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _contactMerchant(merchant);
                            },
                            icon: Icon(
                              VintageIcons.merchantAction('Conversations'),
                              size: 18,
                            ),
                            label: const Text('Contacter'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.45),
                              ),
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String initial;
  final double radius;

  const _InitialAvatar({required this.initial, this.radius = 30});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8F2E8),
      child: Text(
        initial,
        style: TextStyle(
          color: AppTheme.primaryDarkColor,
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../core/widgets/raaga_bottom_nav.dart';
import '../../../../core/widgets/app_nav_shell.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/order_service.dart';
import '../../../../data/services/product_service.dart';
import '../../../../data/services/profile_service.dart';
import '../../../../data/services/story_service.dart';
import '../../../../data/services/subscription_service.dart';
import 'products_page.dart';
import 'stories_page.dart';
import 'profile_page.dart';
import 'messaging_page.dart';
import 'ads_management_page.dart';
import 'subscriptions_management_page.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = const [
      _ProductsTab(),
      _StoriesTab(),
      _MessagingTab(),
      _OrdersTab(),
      _AdsManagementTab(),
      _SubscriptionsManagementTab(),
      _ProfileTab(),
    ];
  }

  /// Pages: [Dashboard, Products, Stories, Messaging, Orders, Ads, Subs, Profile]
  /// Nav: [Accueil, Produits, Chat, Pubs, Plans, Profil]
  int _navSelectedIndexFromPage(int pageIndex) {
    const map = [0, 1, 3, 5, 6, 7];
    final idx = map.indexOf(pageIndex);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    // Pas d'AppBar au niveau shell : chaque onglet gère la sienne
    // (évite le double bandeau "Espace e-commerçant" + "Mes produits").
    return AppNavShell(
      backgroundColor: const Color(0xFFF4F7F4),
      currentIndex: _navSelectedIndexFromPage(_currentIndex),
      onTap: (visibleIndex) {
        const map = [0, 1, 3, 5, 6, 7];
        final pageIndex = (visibleIndex >= 0 && visibleIndex < map.length)
            ? map[visibleIndex]
            : 0;
        setState(() => _currentIndex = pageIndex);
      },
      items: RaagaBottomNav.merchantItems,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DashboardTab(
            onTabChange: (index) => setState(() => _currentIndex = index),
          ),
          ..._tabs,
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final ValueChanged<int> onTabChange;

  const _DashboardTab({
    required this.onTabChange,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab>
    with SingleTickerProviderStateMixin {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final ProductService _productService = ProductService();
  final StoryService _storyService = StoryService();
  final OrderService _orderService = OrderService();
  final ProfileService _profileService = ProfileService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _isLoading = true;
  String _businessName = 'Ma boutique';
  String? _businessImage;
  int _productCount = 0;
  int _storyCount = 0;
  int _pendingOrders = 0;
  int _subscribers = 0;
  bool _hasPlus = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _loadDashboard();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _profileService.getMerchantProfile(),
        _productService.getMyProducts(),
        _storyService.getMyStories(),
        _subscriptionService.getSubscriptionStats(user.id),
        _safeOrderStats(),
      ]);

      if (!mounted) return;

      final profile = results[0] as Map<String, dynamic>?;
      final products = results[1] as List;
      final stories = results[2] as List;
      final subStats = results[3] as Map<String, dynamic>;
      final orderStats = results[4] as Map<String, dynamic>;

      final name = profile?['business_name']?.toString().trim() ?? '';
      setState(() {
        _businessName = name.isNotEmpty ? name : 'Ma boutique';
        _businessImage = profile?['business_image']?.toString();
        _productCount = products.length;
        _storyCount = stories.length;
        _pendingOrders = (orderStats['pending'] as int?) ?? 0;
        _subscribers = (subStats['subscribers_count'] as int?) ?? 0;
        _hasPlus = subStats['has_plus_subscription'] == true;
        _isLoading = false;
      });
      _anim.forward();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _anim.forward();
    }
  }

  Future<Map<String, dynamic>> _safeOrderStats() async {
    try {
      final stats = await _orderService.getOrderStats();
      return {'pending': (stats['pending'] as int?) ?? 0};
    } catch (_) {
      return {'pending': 0};
    }
  }

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    context.go('/user-type-selection');
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    if (_isLoading) {
      return const ColoredBox(
        color: Color(0xFFF4F7F4),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ColoredBox(
      color: const Color(0xFFF4F7F4),
      child: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: () async {
          _anim.reset();
          setState(() => _isLoading = true);
          await _loadDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(top),
              Transform.translate(
                offset: const Offset(0, -28),
                child: FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 18),
                          _buildPrimaryCta(),
                          const SizedBox(height: 22),
                          const Text(
                            'Actions rapides',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionsGrid(),
                          const SizedBox(height: 22),
                          const Text(
                            'Développer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildGrowCards(),
                        ],
                      ),
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

  Widget _buildHero(double top) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 8, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
            Color(0xFF43A047),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'B-Place',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3.2,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Déconnexion',
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _greeting,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (_businessImage != null && _businessImage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipOval(
                    child: Image.network(
                      _businessImage!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: Colors.white24,
                        child: const Icon(Icons.store, color: Colors.white70, size: 22),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _businessName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _hasPlus ? 'Plan Plus actif' : 'Espace e-commerçant',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'Produits',
            value: '$_productCount',
            icon: VintageIcons.merchantStat('produits'),
            delay: 0,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            label: 'Stories',
            value: '$_storyCount',
            icon: VintageIcons.merchantStat('stories'),
            delay: 60,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            label: 'En attente',
            value: '$_pendingOrders',
            icon: VintageIcons.merchantStat('attente'),
            delay: 120,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatPill(
            label: 'Abonnés',
            value: '$_subscribers',
            icon: VintageIcons.merchantStat('abonnés'),
            delay: 180,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCta() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/merchant/add-product'),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              SizedBox(width: 20),
              Icon(Icons.add_business, color: Colors.white, size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ajouter un produit',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Publie une nouvelle annonce',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
              SizedBox(width: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionsGrid() {
    final actions = <_ActionItem>[
      _ActionItem(
        title: 'Créer une story',
        subtitle: 'Capte l’attention',
        icon: VintageIcons.merchantAction('Créer une story'),
        onTap: () => context.push('/merchant/add-story'),
      ),
      _ActionItem(
        title: 'Mes produits',
        subtitle: 'Gérer le stock',
        icon: VintageIcons.merchantAction('Mes produits'),
        onTap: () => widget.onTabChange(1),
      ),
      _ActionItem(
        title: 'Mes stories',
        subtitle: 'Voir & suivre',
        icon: VintageIcons.merchantAction('Mes Stories'),
        onTap: () => widget.onTabChange(2),
      ),
      _ActionItem(
        title: 'Conversations',
        subtitle: 'Répondre vite',
        icon: VintageIcons.merchantAction('Conversations'),
        onTap: () => widget.onTabChange(3),
      ),
      _ActionItem(
        title: 'Stats stories',
        subtitle: 'Vues & impact',
        icon: VintageIcons.merchantAction('Stats Stories'),
        onTap: () => context.push('/merchant/story-stats'),
      ),
      _ActionItem(
        title: 'Mon profil',
        subtitle: 'Boutique',
        icon: VintageIcons.merchantAction('profil'),
        onTap: () => widget.onTabChange(7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 700 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cols == 3 ? 1.35 : 1.28,
          ),
          itemBuilder: (context, i) {
            final a = actions[i];
            return _ActionCard(
              title: a.title,
              subtitle: a.subtitle,
              icon: a.icon,
              onTap: a.onTap,
            );
          },
        );
      },
    );
  }

  Widget _buildGrowCards() {
    return Column(
      children: [
        _GrowTile(
          icon: VintageIcons.merchantAction('pubs'),
          title: 'Publicités',
          subtitle: 'Boostez la visibilité de votre boutique',
          onTap: () => widget.onTabChange(5),
        ),
        const SizedBox(height: 10),
        _GrowTile(
          icon: VintageIcons.merchantAction('plans'),
          title: 'Plans & abonnements',
          subtitle: _hasPlus
              ? '$_subscribers abonné(s) · Plan Plus actif'
              : '$_subscribers abonné(s) · Découvrir Plus',
          accent: _hasPlus ? const Color(0xFFC9A227) : AppTheme.primaryColor,
          onTap: () => widget.onTabChange(6),
        ),
      ],
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final int delay;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(
          scale: 0.92 + (0.08 * t),
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EEE6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryDarkColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EEE6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VintageIconBadge(icon: icon, size: 22),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  const _GrowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE6EEE6)),
          ),
          child: Row(
            children: [
              VintageIconBadge(
                icon: icon,
                size: 24,
                color: accent == AppTheme.primaryColor
                    ? AppTheme.primaryDarkColor
                    : accent,
                backgroundColor: accent.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) => const MerchantProductsPage();
}

class _StoriesTab extends StatelessWidget {
  const _StoriesTab();

  @override
  Widget build(BuildContext context) => const MerchantStoriesPage();
}

class _MessagingTab extends StatelessWidget {
  const _MessagingTab();

  @override
  Widget build(BuildContext context) => const MerchantMessagingPage();
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Commandes - À implémenter')),
    );
  }
}

class _AdsManagementTab extends StatelessWidget {
  const _AdsManagementTab();

  @override
  Widget build(BuildContext context) => const AdsManagementPage();
}

class _SubscriptionsManagementTab extends StatelessWidget {
  const _SubscriptionsManagementTab();

  @override
  Widget build(BuildContext context) => const SubscriptionsManagementPage();
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => const MerchantProfilePage();
}

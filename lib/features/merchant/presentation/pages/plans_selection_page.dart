import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/styled_app_bar.dart';
import '../../../../core/constants/subscription_plans.dart';
import '../../../../data/services/subscription_service.dart';
import '../../../../core/error_handling/error_handler.dart';

class PlansSelectionPage extends StatefulWidget {
  const PlansSelectionPage({super.key});

  @override
  State<PlansSelectionPage> createState() => _PlansSelectionPageState();
}

class _PlansSelectionPageState extends State<PlansSelectionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  String? _currentPlan;
  bool _isLoading = true;
  bool _isActivating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final plan = await _subscriptionService.getActivePlan(user.id);
      if (mounted) {
        setState(() {
          _currentPlan = plan;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement du plan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _activatePlan(String planType) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _isActivating = true;
    });

    try {
      // Tous les prix sont maintenant en FCFA
      final price = SubscriptionPlans.getPriceInFCFA(planType);
      const currency = 'FCFA';

      final success = await _subscriptionService.activatePlan(
        merchantId: user.id,
        planType: planType,
        price: price,
        currency: currency,
      );

      if (mounted) {
        setState(() {
          _isActivating = false;
        });

        if (success) {
          await _loadCurrentPlan();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plan ${SubscriptionPlans.getDisplayName(planType)} activé avec succès !',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'activation du plan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de l\'activation: $e');
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
        ErrorHandler.showError(context, e);
      }
    }
  }

  String _getPriceDisplay(String planType) {
    // Tous les prix sont maintenant en FCFA
    return '${SubscriptionPlans.getPriceInFCFA(planType).toStringAsFixed(0)} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StyledAppBar(
        title: 'Plans d\'abonnement',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentPlan != null)
                    Card(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Plan actuel: ${SubscriptionPlans.getDisplayName(_currentPlan!)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  
                  // Plan Simple
                  _buildPlanCard(
                    planType: SubscriptionPlans.simple,
                    color: Colors.grey,
                    icon: Icons.person_outline,
                    isCurrent: _currentPlan == SubscriptionPlans.simple,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Plan Pro
                  _buildPlanCard(
                    planType: SubscriptionPlans.pro,
                    color: Colors.blue,
                    icon: Icons.business,
                    isCurrent: _currentPlan == SubscriptionPlans.pro,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Plan Premium
                  _buildPlanCard(
                    planType: SubscriptionPlans.premium,
                    color: Colors.amber,
                    icon: Icons.star,
                    isCurrent: _currentPlan == SubscriptionPlans.premium,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String planType,
    required Color color,
    required IconData icon,
    required bool isCurrent,
  }) {
    final benefits = SubscriptionPlans.planBenefits[planType] ?? [];
    final displayName = SubscriptionPlans.getDisplayName(planType);
    final description = SubscriptionPlans.getDescription(planType);

    return Card(
      elevation: isCurrent ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isCurrent
            ? BorderSide(color: color, width: 3)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Actuel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getPriceDisplay(planType),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Durée: ${SubscriptionPlans.getDurationDisplay(planType)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Avantages:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          benefit,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isActivating || isCurrent
                    ? null
                    : () => _activatePlan(planType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isActivating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isCurrent ? 'Plan actuel' : 'Activer ce plan',
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
}


import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/vintage_icons.dart';
import '../../../../data/services/subscription_service.dart';
import '../../../../data/services/image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantCard extends StatefulWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback? onTap;
  final bool showSubscribeButton;

  const MerchantCard({
    super.key,
    required this.merchant,
    this.onTap,
    this.showSubscribeButton = true,
  });

  @override
  State<MerchantCard> createState() => _MerchantCardState();
}

class _MerchantCardState extends State<MerchantCard> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSubscribeButton) {
      _checkSubscriptionStatus();
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final isSubscribed = await _subscriptionService.isSubscribed(
      customerId: user.id,
      merchantId: widget.merchant['id'],
    );

    if (mounted) {
      setState(() => _isSubscribed = isSubscribed);
    }
  }

  Future<void> _toggleSubscription() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isSubscribed) {
      success = await _subscriptionService.unsubscribeFromMerchant(
        customerId: user.id,
        merchantId: widget.merchant['id'],
      );
    } else {
      success = await _subscriptionService.subscribeToMerchant(
        customerId: user.id,
        merchantId: widget.merchant['id'],
      );
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (success) _isSubscribed = !_isSubscribed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isSubscribed
                  ? 'Abonné à ${widget.merchant['business_name']}'
                  : 'Désabonné de ${widget.merchant['business_name']}')
              : 'Erreur lors de l\'opération',
        ),
        backgroundColor: !success
            ? Colors.red
            : (_isSubscribed ? Colors.green : Colors.orange),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName =
        widget.merchant['business_name']?.toString() ?? 'E-commerçant';
    final businessDescription =
        widget.merchant['business_description']?.toString() ?? '';
    final profileImage = widget.merchant['profile_image']?.toString() ??
        widget.merchant['business_image']?.toString() ??
        '';
    final phoneNumber = widget.merchant['phone_number']?.toString() ??
        widget.merchant['business_phone']?.toString() ??
        '';
    final initial = businessName.isNotEmpty
        ? businessName.substring(0, 1).toUpperCase()
        : 'B';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EEE6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: ImageService.buildCircularImage(
                    imageUrl: profileImage,
                    radius: 30,
                    placeholder: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE8F2E8),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.primaryDarkColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    errorWidget: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFE8F2E8),
                      child: Icon(
                        Icons.store,
                        color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (businessDescription.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          businessDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (phoneNumber.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_in_talk,
                              size: 14,
                              color: AppTheme.primaryColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                phoneNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.showSubscribeButton) ...[
                  const SizedBox(width: 6),
                  _isLoading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          onPressed: _toggleSubscription,
                          tooltip:
                              _isSubscribed ? 'Se désabonner' : 'S\'abonner',
                          icon: VintageIconBadge(
                            icon: _isSubscribed
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: _isSubscribed
                                ? Colors.redAccent
                                : AppTheme.primaryDarkColor,
                            backgroundColor: _isSubscribed
                                ? Colors.redAccent.withValues(alpha: 0.1)
                                : const Color(0xFFEAF3EA),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

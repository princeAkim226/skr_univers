import 'package:supabase_flutter/supabase_flutter.dart';

class PromoValidationResult {
  final bool valid;
  final String message;
  final String? promoCodeId;
  final String? code;
  final double discountAmount;
  final double finalTotal;

  const PromoValidationResult({
    required this.valid,
    required this.message,
    this.promoCodeId,
    this.code,
    required this.discountAmount,
    required this.finalTotal,
  });
}

class PromoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMerchantsForAdmin() async {
    final response = await _supabase
        .from('merchants')
        .select('id, business_name, user_id')
        .order('business_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getPromoCodesForAdmin() async {
    final response = await _supabase
        .from('promo_codes')
        .select('''
          id,
          code,
          merchant_id,
          discount_type,
          discount_value,
          min_order_amount,
          max_discount_amount,
          starts_at,
          ends_at,
          usage_limit_total,
          usage_limit_per_customer,
          used_count,
          is_active,
          created_at,
          merchant:merchant_id(business_name)
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createPromoCode({
    required String code,
    required String merchantId,
    required String discountType,
    required double discountValue,
    double minOrderAmount = 0,
    double? maxDiscountAmount,
    int? usageLimitTotal,
    int? usageLimitPerCustomer,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    final cleanedCode = code.trim().toUpperCase();

    if (cleanedCode.isEmpty) {
      throw Exception('Le code promo est requis');
    }

    await _supabase.from('promo_codes').insert({
      'code': cleanedCode,
      'merchant_id': merchantId,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      if (maxDiscountAmount != null) 'max_discount_amount': maxDiscountAmount,
      if (usageLimitTotal != null) 'usage_limit_total': usageLimitTotal,
      if (usageLimitPerCustomer != null) 'usage_limit_per_customer': usageLimitPerCustomer,
      if (startsAt != null) 'starts_at': startsAt.toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toIso8601String(),
      'is_active': true,
      if (userId != null) 'created_by_admin_id': userId,
    });
  }

  Future<void> togglePromoCodeActive({
    required String promoCodeId,
    required bool isActive,
  }) async {
    await _supabase
        .from('promo_codes')
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', promoCodeId);
  }

  Future<PromoValidationResult> validatePromoCode({
    required String code,
    required String merchantId,
    required double orderAmount,
  }) async {
    final cleanedCode = code.trim();
    if (cleanedCode.isEmpty) {
      return PromoValidationResult(
        valid: false,
        message: 'Veuillez saisir un code promo',
        discountAmount: 0,
        finalTotal: orderAmount,
      );
    }

    try {
      final response = await _supabase.rpc(
        'validate_promo_code',
        params: {
          'p_code': cleanedCode,
          'p_merchant_id': merchantId,
          'p_order_amount': orderAmount,
        },
      );

      final data = response as Map<String, dynamic>? ?? <String, dynamic>{};
      final isValid = data['is_valid'] == true;

      return PromoValidationResult(
        valid: isValid,
        message: (data['message'] ?? (isValid ? 'Code promo appliqué' : 'Code invalide')).toString(),
        promoCodeId: data['promo_code_id']?.toString(),
        code: data['code']?.toString(),
        discountAmount: (data['discount_amount'] as num?)?.toDouble() ?? 0,
        finalTotal: (data['final_total'] as num?)?.toDouble() ?? orderAmount,
      );
    } catch (e) {
      return PromoValidationResult(
        valid: false,
        message: 'Erreur validation code promo: $e',
        discountAmount: 0,
        finalTotal: orderAmount,
      );
    }
  }

  Future<Map<String, dynamic>> redeemPromoCode({
    required String promoCodeId,
    required String orderId,
    required double discountAmount,
  }) async {
    try {
      final result = await _supabase.rpc(
        'redeem_promo_code',
        params: {
          'p_promo_code_id': promoCodeId,
          'p_order_id': orderId,
          'p_discount_amount': discountAmount,
        },
      );

      if (result is Map<String, dynamic>) {
        return result;
      }

      return {
        'success': false,
        'message': 'Réponse invalide du serveur promo',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur consommation code promo: $e',
      };
    }
  }
}


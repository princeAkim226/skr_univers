import 'package:flutter/material.dart';
import '../../../../core/error_handling/error_handler.dart';
import '../../../../data/services/promo_service.dart';

class AdminPromoCodesPage extends StatefulWidget {
  const AdminPromoCodesPage({super.key});

  @override
  State<AdminPromoCodesPage> createState() => _AdminPromoCodesPageState();
}

class _AdminPromoCodesPageState extends State<AdminPromoCodesPage> {
  final PromoService _promoService = PromoService();
  final _formKey = GlobalKey<FormState>();

  final _codeCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController(text: '0');
  final _maxDiscountCtrl = TextEditingController();
  final _usageTotalCtrl = TextEditingController();
  final _usagePerCustomerCtrl = TextEditingController();

  bool _loading = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _merchants = [];
  List<Map<String, dynamic>> _promoCodes = [];

  String? _selectedMerchantId;
  String _discountType = 'percent';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountValueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageTotalCtrl.dispose();
    _usagePerCustomerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final merchants = await _promoService.getMerchantsForAdmin();
      final codes = await _promoService.getPromoCodesForAdmin();
      setState(() {
        _merchants = merchants;
        _promoCodes = codes;
        _selectedMerchantId ??= merchants.isNotEmpty ? merchants.first['id']?.toString() : null;
      });
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPromoCode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMerchantId == null || _selectedMerchantId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un e-commerçant')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _promoService.createPromoCode(
        code: _codeCtrl.text.trim(),
        merchantId: _selectedMerchantId!,
        discountType: _discountType,
        discountValue: double.parse(_discountValueCtrl.text.trim()),
        minOrderAmount: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        maxDiscountAmount: _maxDiscountCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_maxDiscountCtrl.text.trim()),
        usageLimitTotal: _usageTotalCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_usageTotalCtrl.text.trim()),
        usageLimitPerCustomer: _usagePerCustomerCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_usagePerCustomerCtrl.text.trim()),
      );

      _codeCtrl.clear();
      _discountValueCtrl.clear();
      _minOrderCtrl.text = '0';
      _maxDiscountCtrl.clear();
      _usageTotalCtrl.clear();
      _usagePerCustomerCtrl.clear();

      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code promo créé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _toggleCode(Map<String, dynamic> code) async {
    final id = code['id']?.toString();
    if (id == null || id.isEmpty) return;
    final current = code['is_active'] == true;

    try {
      await _promoService.togglePromoCodeActive(
        promoCodeId: id,
        isActive: !current,
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCreateCard(),
          const SizedBox(height: 16),
          const Text(
            'Codes existants',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_promoCodes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucun code promo pour le moment'),
              ),
            )
          else
            ..._promoCodes.map(_buildCodeTile),
        ],
      ),
    );
  }

  Widget _buildCreateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Créer un code promo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedMerchantId,
                items: _merchants
                    .map(
                      (m) => DropdownMenuItem<String>(
                        value: m['id']?.toString(),
                        child: Text((m['business_name'] ?? 'Marchand').toString()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedMerchantId = v),
                decoration: const InputDecoration(
                  labelText: 'E-commerçant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code promo (ex: BPLACE10)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Code requis' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _discountType,
                      items: const [
                        DropdownMenuItem(value: 'percent', child: Text('Pourcentage (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('Montant fixe (FCFA)')),
                      ],
                      onChanged: (v) => setState(() => _discountType = v ?? 'percent'),
                      decoration: const InputDecoration(
                        labelText: 'Type réduction',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _discountValueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valeur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || double.tryParse(v) == null)
                          ? 'Valeur invalide'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Panier minimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _maxDiscountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Réduction max (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _usageTotalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limite totale (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _usagePerCustomerCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limite/client (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _createPromoCode,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(_submitting ? 'Création...' : 'Créer le code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeTile(Map<String, dynamic> code) {
    final promoCode = (code['code'] ?? '').toString();
    final discountType = (code['discount_type'] ?? '').toString();
    final discountValue = code['discount_value']?.toString() ?? '0';
    final usedCount = code['used_count']?.toString() ?? '0';
    final merchantName = (code['merchant'] is Map)
        ? ((code['merchant'] as Map)['business_name'] ?? 'Marchand')
        : 'Marchand';
    final isActive = code['is_active'] == true;

    final discountLabel = discountType == 'percent'
        ? '$discountValue%'
        : '${double.tryParse(discountValue)?.toStringAsFixed(0) ?? discountValue} FCFA';

    return Card(
      child: ListTile(
        title: Text(
          promoCode,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$merchantName • Réduction: $discountLabel • Utilisé: $usedCount'),
        trailing: Switch(
          value: isActive,
          onChanged: (_) => _toggleCode(code),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/core/providers.dart';
import 'package:dukaapp/core/network/api_exception.dart';

class ShopDetailsPage extends ConsumerStatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  ConsumerState<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends ConsumerState<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController     = TextEditingController();
  final _tradingNameController  = TextEditingController();
  final _emailController        = TextEditingController();
  final _phoneController        = TextEditingController();
  final _addressController      = TextEditingController();
  final _stateCityController    = TextEditingController();
  final _tinController          = TextEditingController();
  final _vrnController          = TextEditingController();

  String _shopType     = 'All';
  String _shopCategory = 'Default';
  String _currency     = 'TZS';

  bool _isLoading = true;
  bool _isSaving  = false;

  static const List<String> _shopTypes = [
    'All','Product & Services','Manufacturing','Microfinance','Online Shop',
  ];
  static const List<String> _shopCategories = [
    'Default','Fashion','Electronics','Food','Health','Retail','Wholesale',
  ];
  static const List<String> _currencies = [
    'TZS','USD','KES','UGX','ZAR','GBP','EUR','CAD','AUD','INR',
    'CNY','JPY','CHF','NGN','ETB','RWF','BWP',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShop());
  }

  Future<void> _loadShop() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getSessionShop();
      final raw = res.data;
      Map<String, dynamic>? shop;
      if (raw is Map<String, dynamic>) {
        shop = raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw;
      } else if (raw is List && raw.isNotEmpty) {
        shop = raw.first as Map<String, dynamic>;
      }
      if (!mounted) return;
      if (shop != null) {
        _shopNameController.text    = shop['shop_name']?.toString()    ?? '';
        _tradingNameController.text = shop['trading_name']?.toString() ?? '';
        _emailController.text       = shop['shop_email']?.toString()   ?? '';
        _phoneController.text       = shop['phone']?.toString()        ?? '';
        _addressController.text     = shop['address']?.toString()      ?? '';
        _stateCityController.text   = shop['location']?.toString()     ?? '';
        _tinController.text         = shop['tin']?.toString()          ?? '';
        _vrnController.text         = shop['vrn']?.toString()          ?? '';
        final type = shop['shop_type']?.toString() ?? 'All';
        _shopType = _shopTypes.contains(type) ? type : 'All';
        final cat = shop['shop_category']?.toString() ?? 'Default';
        _shopCategory = _shopCategories.contains(cat) ? cat : 'Default';
        final cur = shop['currency']?.toString() ?? 'TZS';
        _currency = _currencies.contains(cur) ? cur : 'TZS';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.postSettingsShopSettingsSave({
        'shop_name':    _shopNameController.text.trim(),
        'trading_name': _tradingNameController.text.trim(),
        'shop_email':   _emailController.text.trim(),
        'phone':        _phoneController.text.trim(),
        'address':      _addressController.text.trim(),
        'location':     _stateCityController.text.trim(),
        'currency':     _currency,
        'tin':          _tinController.text.trim(),
        'vrn':          _vrnController.text.trim(),
        'shop_type':    _shopType,
        'shop_category':_shopCategory,
      });
      if (!mounted) return;
      final status = res['status']?.toString() ?? '';
      if (status == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Shop details saved successfully'),
          backgroundColor: AppColors.success,
        ));
        context.go('/shop-settings');
      } else {
        _snack(res['message']?.toString() ?? 'Save failed', AppColors.danger);
      }
    } catch (e) {
      if (mounted) _snack(e is ApiException ? e.friendlyMessage : e.toString(), AppColors.danger);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  void dispose() {
    _shopNameController.dispose();
    _tradingNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _stateCityController.dispose();
    _tinController.dispose();
    _vrnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.card, elevation: 0,
        leading: Padding(padding: const EdgeInsets.all(8.0), child: Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 1.5), borderRadius: BorderRadius.circular(AppConstants.radiusSM)),
          child: IconButton(onPressed: () => context.go('/shop-settings'), icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20)),
        )),
        leadingWidth: 56,
        title: Text('Shop Details', style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.divider)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _lbl('Shop Name'), const SizedBox(height: 8),
                _field(_shopNameController, 'Shop name', validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter shop name' : null),
                const SizedBox(height: 20),
                _lbl('Trading Name'), const SizedBox(height: 8),
                _field(_tradingNameController, 'Trading name (optional)'),
                const SizedBox(height: 20),
                _lbl('Shop Type'), const SizedBox(height: 8),
                _drop<String>(value: _shopType, items: _shopTypes, onChanged: (v) => setState(() => _shopType = v!)),
                const SizedBox(height: 20),
                _lbl('Shop Category'), const SizedBox(height: 8),
                _drop<String>(value: _shopCategory, items: _shopCategories, onChanged: (v) => setState(() => _shopCategory = v!)),
                const SizedBox(height: 20),
                _lbl('Business Email'), const SizedBox(height: 8),
                _field(_emailController, 'Business email', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 20),
                _lbl('Phone Number'), const SizedBox(height: 8),
                _field(_phoneController, 'Phone number', keyboardType: TextInputType.phone),
                const SizedBox(height: 20),
                _lbl('Address'), const SizedBox(height: 8),
                _field(_addressController, 'Shop address'),
                const SizedBox(height: 20),
                _lbl('City / Location'), const SizedBox(height: 8),
                _field(_stateCityController, 'City or location'),
                const SizedBox(height: 20),
                _lbl('Currency'), const SizedBox(height: 8),
                _drop<String>(value: _currency, items: _currencies, onChanged: (v) => setState(() => _currency = v!)),
                const SizedBox(height: 20),
                _lbl('TIN Number'), const SizedBox(height: 8),
                _field(_tinController, 'Taxpayer number', keyboardType: TextInputType.number),
                const SizedBox(height: 20),
                _lbl('VRN Number'), const SizedBox(height: 8),
                _field(_vrnController, 'VRN number'),
                const SizedBox(height: 32),
                Row(children: [
                  Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.go('/shop-settings'),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
                    child: Text('Cancel', style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ))),
                  const SizedBox(width: 16),
                  Expanded(child: SizedBox(height: AppConstants.buttonHeight, child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM))),
                    child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes', style: AppTypography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  ))),
                ]),
                SizedBox(height: 24 + bottomPadding),
              ]),
            ),
          ),
    );
  }

  Widget _lbl(String t) => Text(t, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c, keyboardType: keyboardType, validator: validator,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint, hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: BorderSide(color: AppColors.textHint.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppConstants.radiusSM), borderSide: const BorderSide(color: AppColors.danger)),
      ),
    );
  }

  Widget _drop<T>({required T value, required List<T> items, required void Function(T?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppConstants.radiusSM), border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3))),
      child: DropdownButton<T>(
        value: value, isExpanded: true, underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
        items: items.map((i) => DropdownMenuItem<T>(value: i, child: Text(i.toString(), style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

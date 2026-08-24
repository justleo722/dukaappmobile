import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dukaapp/app/colors.dart';
import 'package:dukaapp/app/typography.dart';
import 'package:dukaapp/app/constants.dart';
import 'package:dukaapp/shared/textfields/app_text_field.dart';
import 'package:dukaapp/features/online_shop/presentation/widgets/order_confirmation_dialog.dart';

class OnlineShopCheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const OnlineShopCheckoutPage({super.key, required this.cartItems});

  @override
  State<OnlineShopCheckoutPage> createState() => _OnlineShopCheckoutPageState();
}

class _OnlineShopCheckoutPageState extends State<OnlineShopCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();

  String? _selectedRegion;
  int _selectedDeliveryIndex = 0;
  int _selectedPaymentIndex = 0;
  String? _appliedCouponCode;
  String? _couponError;

  final List<String> _regions = const [
    'Dar es Salaam',
    'Arusha',
    'Mwanza',
    'Dodoma',
    'Zanzibar',
    'Tanga',
    'Mbeya',
    'Morogoro',
    'Kilimanjaro',
    'Iringa',
  ];

  final List<Map<String, dynamic>> _deliveryMethods = const [
    {
      'name': 'City Delivery',
      'fee': 5000,
      'estimatedDelivery': '~20 minutes',
      'icon': Icons.delivery_dining_rounded,
    },
    {
      'name': 'Pickup in Office',
      'fee': 0,
      'estimatedDelivery': 'Ready for pickup',
      'icon': Icons.store_rounded,
    },
    {
      'name': 'Fast Delivery',
      'fee': 10000,
      'estimatedDelivery': '3–5 hours',
      'icon': Icons.flash_on_rounded,
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = const [
    {'name': 'Cash on Delivery', 'icon': Icons.money_rounded},
    {'name': 'MPESA', 'icon': Icons.phone_android_rounded},
    {'name': 'YAS (Mobile Payment)', 'icon': Icons.credit_card_rounded},
  ];

  static const Map<String, double> _validCoupons = {
    'SAVE10': 10,
    'WELCOME20': 20,
    'FLAT5000': 0,
  };

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  int _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  String _formatPrice(int amount) {
    final str = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return 'TZS $buf';
  }

  int get _subtotal => widget.cartItems.fold(0, (sum, item) {
    final price = _parsePrice((item['price'] as String?) ?? '0');
    final qty = (item['qty'] as int?) ?? 1;
    return sum + (price * qty);
  });

  int get _deliveryFee => _deliveryMethods[_selectedDeliveryIndex]['fee'] as int;

  double get _discountAmount {
    if (_appliedCouponCode == null) return 0;
    if (_appliedCouponCode == 'FLAT5000') return 5000;
    final pct = _validCoupons[_appliedCouponCode] ?? 0;
    return _subtotal * (pct / 100);
  }

  int get _total => _subtotal + _deliveryFee - _discountAmount.round();

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'Please enter a coupon code';
        _appliedCouponCode = null;
      });
      return;
    }
    if (_validCoupons.containsKey(code)) {
      setState(() {
        _appliedCouponCode = code;
        _couponError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coupon "$code" applied!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      setState(() {
        _couponError = 'Invalid coupon code';
        _appliedCouponCode = null;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  String _generateOrderId() {
    final now = DateTime.now();
    final datePart = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';
    final seqPart = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    return 'OS-$datePart-$seqPart';
  }

  void _placeOrder() {
    if (!_formKey.currentState!.validate()) return;

    final orderId = _generateOrderId();

    OrderConfirmationDialog.show(
      context: context,
      orderId: orderId,
      customerName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      deliveryMethod: _deliveryMethods[_selectedDeliveryIndex]['name'] as String,
      deliveryFee: _deliveryFee,
      paymentMethod: _paymentMethods[_selectedPaymentIndex]['name'] as String,
      items: widget.cartItems,
      subtotal: _subtotal,
      total: _total,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
        ),
        leadingWidth: 56,
        title: Text(
          'Checkout',
          style: AppTypography.h6.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Customer Information', AppColors.primary),
                    const SizedBox(height: 12),
                    _buildCustomerInfoSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Delivery Method', const Color(0xFF14B8A6)),
                    const SizedBox(height: 12),
                    _buildDeliveryMethodSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Payment Method', AppColors.secondary),
                    const SizedBox(height: 12),
                    _buildPaymentMethodSection(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Order Summary', const Color(0xFF9333EA)),
                    const SizedBox(height: 12),
                    _buildOrderSummarySection(),
                    const SizedBox(height: 24),
                    _buildCouponSection(),
                    SizedBox(height: bottomPadding + 100),
                  ],
                ),
              ),
            ),
            _buildPlaceOrderBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.h6.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          AppTextField(
            label: 'Full Name',
            hintText: 'Enter your full name',
            controller: _fullNameController,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Phone Number',
            hintText: 'e.g. 0755 644 282',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email Address',
            hintText: 'e.g. you@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _buildRegionDropdown(),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Delivery Address',
            hintText: 'Street, building, floor, etc.',
            controller: _addressController,
            textInputAction: TextInputAction.done,
            maxLines: 2,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Region',
          style: AppTypography.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedRegion,
          hint: Text(
            'Select your region',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
            ),
          ),
          items: _regions.map((r) => DropdownMenuItem(
            value: r,
            child: Text(r, style: AppTypography.bodyMedium),
          )).toList(),
          onChanged: (v) => setState(() => _selectedRegion = v),
          validator: (v) => v == null ? 'Please select a region' : null,
        ),
      ],
    );
  }

  Widget _buildDeliveryMethodSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(_deliveryMethods.length, (i) {
          final method = _deliveryMethods[i];
          final isSelected = _selectedDeliveryIndex == i;
          final fee = method['fee'] as int;
          return GestureDetector(
            onTap: () => setState(() => _selectedDeliveryIndex = i),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: i == _deliveryMethods.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(AppConstants.radiusMD))
                    : null,
                border: i < _deliveryMethods.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _selectedDeliveryIndex,
                    onChanged: (v) => setState(() => _selectedDeliveryIndex = v!),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['name'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method['estimatedDelivery'] as String,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    fee == 0 ? 'Free' : _formatPrice(fee),
                    style: AppTypography.bodyMedium.copyWith(
                      color: fee == 0 ? AppColors.success : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(_paymentMethods.length, (i) {
          final method = _paymentMethods[i];
          final isSelected = _selectedPaymentIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentIndex = i),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                borderRadius: i == _paymentMethods.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(AppConstants.radiusMD))
                    : null,
                border: i < _paymentMethods.length - 1
                    ? const Border(bottom: BorderSide(color: AppColors.border))
                    : null,
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: _selectedPaymentIndex,
                    onChanged: (v) => setState(() => _selectedPaymentIndex = v!),
                    activeColor: AppColors.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      size: 20,
                      color: isSelected ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      method['name'] as String,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.cartItems.map((item) {
            final qty = (item['qty'] as int?) ?? 1;
            final price = _parsePrice((item['price'] as String?) ?? '0');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                    ),
                    child: item['icon'] != null
                        ? Icon(item['icon'] as IconData, size: 20, color: AppColors.primary)
                        : const Center(child: Text('📦', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['name'] as String?) ?? 'Product',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (item['seller'] as String?) ?? 'Seller',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$qty × ${_formatPrice(price)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', _formatPrice(_subtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Delivery (${_deliveryMethods[_selectedDeliveryIndex]['name']})',
            _deliveryFee == 0 ? 'Free' : _formatPrice(_deliveryFee),
          ),
          if (_appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Coupon ($_appliedCouponCode)',
              '-${_formatPrice(_discountAmount.round())}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatPrice(_total),
                style: AppTypography.h6.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCouponSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coupon Code',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Have a discount code? Enter it below.',
            style: AppTypography.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'e.g. SAVE10',
                    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
                    errorText: _couponError,
                    errorStyle: AppTypography.caption.copyWith(color: AppColors.danger),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      borderSide: const BorderSide(color: AppColors.inputFocusBorder, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      borderSide: const BorderSide(color: AppColors.inputErrorBorder),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      borderSide: const BorderSide(color: AppColors.inputErrorBorder, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_appliedCouponCode != null)
                GestureDetector(
                  onTap: _removeCoupon,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: const Icon(Icons.close_rounded, color: AppColors.danger, size: 20),
                  ),
                )
              else
                GestureDetector(
                  onTap: _applyCoupon,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      'Apply',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_appliedCouponCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Coupon "$_appliedCouponCode" applied!',
                    style: AppTypography.captionBold.copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: AppConstants.buttonHeight,
          child: ElevatedButton(
            onPressed: _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.textWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Place Order — ${_formatPrice(_total)}',
                  style: AppTypography.buttonLarge.copyWith(color: AppColors.textWhite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
